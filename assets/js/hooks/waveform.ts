// THE SHAPE OF A LEFT PRESENCE.
//
// Every peak here is decoded from the actual audio file. Nothing is generated to
// look plausible, and that matters more than it sounds: a fabricated waveform is
// a picture of nothing, identical for every clip once you have seen two of them.
// A real one means two presences of the same length look different because they
// ARE different, which is the only reason to draw one at all.
const BARS = 72;

// One decode per URL, not per row. The fixtures deliberately repeat clips across
// users, and Wikimedia rate-limits anyone who asks for the same file repeatedly.
const peaksFor = new Map<string, Promise<number[]>>();

const decode = (url: string): Promise<number[]> => {
  const hit = peaksFor.get(url);
  if (hit) return hit;

  const job = (async () => {
    const Ctx = window.AudioContext || (window as any).webkitAudioContext;
    const res = await fetch(url);
    if (!res.ok) throw new Error(String(res.status));
    const buf = await new Ctx().decodeAudioData(await res.arrayBuffer());

    // Peak, not average. Averaging a waveform flattens it towards silence and
    // every clip ends up the same gentle hill; the peak is what you actually
    // hear as loud.
    const data = buf.getChannelData(0);
    const per = Math.floor(data.length / BARS) || 1;
    const raw: number[] = [];
    for (let i = 0; i < BARS; i++) {
      let max = 0;
      for (let j = i * per; j < (i + 1) * per && j < data.length; j++) {
        const v = Math.abs(data[j]);
        if (v > max) max = v;
      }
      raw.push(max);
    }

    // Normalised against the clip's OWN loudest moment, so a quietly recorded
    // voice still fills its row. The floor keeps silence visible as a line
    // rather than as a gap, which is what makes a pause read as a pause.
    const loudest = Math.max(...raw, 0.0001);
    return raw.map((v) => Math.max(0.06, v / loudest));
  })();

  peaksFor.set(url, job);
  return job;
};

export const Waveform = {
  mounted(this: { el: HTMLElement }) {
    // The hook sits on the presence BOX itself, not on an inner shape holder:
    // the box is the press target, so it is also the thing that knows how to
    // play. There is no separate control to wire up.
    const el = this.el;
    const url = el.dataset.media;
    const base = el.querySelector<HTMLElement>(".wave-base");
    const lit = el.querySelector<HTMLElement>(".wave-lit");
    if (!url || !base || !lit) return;

    // TWO LAYERS, one clipped. The alternative — recolouring bars one by one as
    // the playhead passes — repaints seventy-two elements every frame and still
    // steps a bar at a time. Clipping the lit layer moves continuously and costs
    // one style write.
    const draw = (peaks: number[]) => {
      const html = peaks.map((p) => `<span style="height:${(p * 100).toFixed(1)}%"></span>`).join("");
      base.innerHTML = html;
      lit.innerHTML = html;
      el.classList.add("is-drawn");
    };

    decode(url)
      .then(draw)
      // A flat line is an honest failure: it says "there is a clip here and we
      // could not read its shape", where an invented waveform would lie about
      // having read it.
      .catch(() => {
        draw(new Array(BARS).fill(0.06));
        el.classList.add("is-shapeless");
      });

    // Playback belongs to the row, so a presence is self-contained and can be
    // dropped into a chat column without anything above it coordinating.
    const audio = new Audio();
    audio.preload = "none";

    const setPlayed = (ratio: number) =>
      el.style.setProperty("--played", `${Math.min(1, Math.max(0, ratio)) * 100}%`);

    let raf = 0;
    const follow = () => {
      if (audio.duration) setPlayed(audio.currentTime / audio.duration);
      raf = requestAnimationFrame(follow);
    };

    const play = () => {
      if (!audio.src) audio.src = url;
      audio.play().catch(() => {});
      el.classList.add("is-playing");
      // Heard is not a thing you undo. Once played, the row stops asking.
      el.classList.remove("is-unheard");
      raf = requestAnimationFrame(follow);
    };
    const pause = () => {
      audio.pause();
      el.classList.remove("is-playing");
      cancelAnimationFrame(raf);
    };

    this.toggle = () => (audio.paused ? play() : pause());

    // Pressing the box plays from where you pressed, because a shape you can see
    // the end of invites aiming at the middle of it. Pause is Space rather than
    // a second click: on a nine-second clip the dominant act is "play it", and
    // making a second click mean "stop" would cost the ability to re-aim.
    el.addEventListener("click", (e) => {
      const r = el.getBoundingClientRect();
      const ratio = (e.clientX - r.left) / r.width;
      if (!audio.src) audio.src = url;

      const applySeek = () => {
        if (!isFinite(audio.duration)) return;
        audio.currentTime = ratio * audio.duration;
        setPlayed(ratio);
      };

      if (audio.readyState >= 1) {
        applySeek();
        if (audio.paused) play();
      } else {
        // preload="none" means assigning src does NOT start a metadata fetch —
        // nothing loads until something asks to play. Waiting on loadedmetadata
        // before calling play() therefore waited forever, and the first press
        // of any presence did nothing at all. Ask first, seek when it arrives.
        audio.addEventListener("loadedmetadata", applySeek, { once: true });
        play();
      }
    });

    // Space and Enter, because role="button" earns a keyboard and a box you can
    // press with a mouse but not with a key is a button in costume only.
    el.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        this.toggle();
      }
    });

    audio.addEventListener("ended", () => {
      pause();
      setPlayed(0);
    });

    this.cleanup = () => {
      cancelAnimationFrame(raf);
      audio.pause();
      audio.removeAttribute("src");
    };
  },

  destroyed(this: { cleanup?: () => void }) {
    this.cleanup?.();
  },
};

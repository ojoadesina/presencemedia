// A LEFT PRESENCE, playing.
//
// The hook sits on the presence BOX itself rather than on a control inside it:
// the box is the press target, so the box is what knows how to play. There is no
// separate button to wire up, and nothing above it has to coordinate — a
// presence is self-contained and can be dropped straight into a chat column.
//
// It drives one thing, `--played`, which is the width of the inner rectangle's
// fill. What you look at and what tells you where you are in it are the same
// object, so there is only ever one number to keep true.
export const Waveform = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const url = el.dataset.media;
    if (!url) return;

    const audio = new Audio();
    audio.preload = "none";

    const setPlayed = (ratio: number) =>
      el.style.setProperty("--played", `${Math.min(1, Math.max(0, ratio)) * 100}%`);

    // requestAnimationFrame rather than timeupdate: the browser fires that event
    // roughly four times a second, which on a nine-second clip is a fill that
    // visibly jumps rather than moves.
    let raf = 0;
    const follow = () => {
      if (audio.duration) setPlayed(audio.currentTime / audio.duration);
      raf = requestAnimationFrame(follow);
    };

    const play = () => {
      if (!audio.src) audio.src = url;
      audio.play().catch(() => {});
      el.classList.add("is-playing");
      // Heard is not a thing you undo. Once played, it stops asking.
      el.classList.remove("is-unheard");
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(follow);
    };

    const pause = () => {
      audio.pause();
      el.classList.remove("is-playing");
      cancelAnimationFrame(raf);
    };

    this.toggle = () => (audio.paused ? play() : pause());

    // Pressing plays from where you pressed. A rectangle you can see the end of
    // invites aiming at the middle of it, and the fill makes that legible.
    // Pause is Space rather than a second press: on a short clip the dominant
    // act is "play it", and making a second press mean "stop" would cost the
    // ability to re-aim.
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
        // before calling play() therefore waits forever, and the first press of
        // any presence does nothing at all. Ask first, seek when it arrives.
        audio.addEventListener("loadedmetadata", applySeek, { once: true });
        play();
      }
    });

    // role="button" earns a keyboard, and a box you can press with a mouse but
    // not with a key is a button in costume only.
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

// THE PRESENCE PANEL. The relationship list's own mechanism, one level in: a
// band a third of the way down, presences scrolling THROUGH it, and whichever
// settles there is chosen. What is different is what "chosen" does. There is no
// frame off to the side — the chosen box IS the player. A voice breathes its
// background, a face fills it, and it plays the moment it lands. The work the
// frame used to do is delegated to the selection itself.
//
// This is deliberately a sibling of the relationship list's hook rather than a
// shared abstraction: the two choose different things (a person, a moment) and
// one does its playing in a frame while this one does it in the box. When they
// have both stopped moving, factor them; not before.
type HookCtx = { el: HTMLElement };

export const PresencePanel = {
  mounted(this: HookCtx) {
    const scroll = this.el;
    const items = Array.from(scroll.querySelectorAll<HTMLElement>(".presence-item"));
    const stage = scroll.parentElement?.querySelector<HTMLElement>(".stage") ?? null;
    const video = stage?.querySelector<HTMLVideoElement>(".stage-video") ?? null;
    const audio = stage?.querySelector<HTMLAudioElement>(".stage-audio") ?? null;
    if (!items.length || !stage) return;

    // The stage's state is CLASSES, not data attributes — it is
    // phx-update="ignore" so a patch never rewrites it, and classes survive a
    // re-render where a client-set src would not. `mode` is a plain variable
    // because reading it back out of the class list would be guessing at what we
    // ourselves wrote.
    let mode = "empty"; // empty | voice | face
    let src = "";

    const setStage = (next: string) => {
      stage.classList.remove("is-voice", "is-face", "is-playing");
      if (next !== "empty") stage.classList.add(`is-${next}`, "is-playing");
      mode = next;
    };
    const media = (): HTMLMediaElement | null =>
      mode === "face" ? video : mode === "voice" ? audio : null;

    // Pausing alone freezes the last frame and leaves the file downloading.
    // Dropping the src and calling load() is what actually stops the transfer
    // and blanks the box for the next presence.
    const stopMedia = () => {
      for (const m of [video, audio]) {
        if (!m) continue;
        m.pause();
        if (m.getAttribute("src")) {
          m.removeAttribute("src");
          m.load();
        }
      }
    };

    const play = (el: HTMLElement) => {
      const nextMode = el.dataset.kind || "empty";
      const nextSrc = el.dataset.media || "";
      // Re-landing on the presence already playing must not restart it.
      if (mode === nextMode && src === nextSrc) return;

      stopMedia();
      setStage(nextMode);
      src = nextSrc;

      const m = media();
      if (!m || !nextSrc) return;
      m.src = nextSrc;
      // A scroll is not a user activation, so the first autoplay of a session
      // can be refused — the browser's policy, not a fault, and it must not
      // throw. Any click on a row (which is how most selections happen) grants
      // it from then on.
      m.play().catch(() => {});
    };

    const silence = () => {
      stopMedia();
      setStage("empty");
      src = "";
    };

    let settleTimer: number | undefined;
    // A snap scrolls, which settles, which may snap again. Bounded, so a snap
    // the scroller cannot perform (already at an end) gives up rather than loop.
    let snaps = 0;

    const rowHeight = () => items[0].getBoundingClientRect().height;
    const bandCentre = () => {
      const r = scroll.getBoundingClientRect();
      return r.top + r.height * 0.34;
    };

    // Lead and trail are MEASURED, not written in the markup: the band sits at
    // 34% of the scroller's HEIGHT and a percentage padding resolves against
    // WIDTH, so a hard-coded figure is right at one viewport and wrong at every
    // other. The lead rests the first row one row BELOW the band, so the list
    // opens unselected and silent — nothing plays until a presence is scrolled
    // in, which is the whole of "auto play on selected".
    const pad = () => {
      const ul = scroll.querySelector<HTMLElement>("ul");
      if (!ul) return;
      const h = scroll.clientHeight;
      const rh = rowHeight();
      // A FULL row deeper than the band, not half — so the first row rests a
      // row and a half below it and the band is genuinely out of reach at rest.
      // At exactly one row the settle's `> rowHeight()` test lets it land, and
      // the list opens with its first presence already playing instead of quiet.
      ul.style.paddingTop = `${Math.max(0, h * 0.34 + rh)}px`;
      ul.style.paddingBottom = `${Math.max(0, h * 0.66 - rh / 2)}px`;
    };

    const nearest = (): { el: HTMLElement; delta: number } | null => {
      const centre = bandCentre();
      let best: { el: HTMLElement; delta: number } | null = null;
      for (const el of items) {
        const r = el.getBoundingClientRect();
        const delta = r.top + r.height / 2 - centre;
        if (!best || Math.abs(delta) < Math.abs(best.delta)) best = { el, delta };
      }
      return best;
    };

    const clear = () => items.forEach((i) => i.classList.remove("is-focused"));

    const settle = () => {
      pad();
      scroll.classList.remove("is-scrolling");
      stage.classList.remove("is-scrolling");
      clear();
      const near = nearest();

      // Out of reach — the band is genuinely empty and stays silent.
      if (!near || Math.abs(near.delta) > rowHeight()) {
        scroll.classList.remove("has-selection");
        silence();
        snaps = 0;
        return;
      }

      // In reach but off-centre — draw it in, and settle again when it lands.
      // No media yet: the row is still travelling and a clip started here would
      // be cut off by the next settle. Guard the scroll that never happens (a
      // scroller already at its end fires no event) by taking the row anyway.
      if (Math.abs(near.delta) > 1 && snaps < 3) {
        const before = scroll.scrollTop;
        snaps++;
        scroll.scrollBy({ top: near.delta, behavior: "smooth" });
        window.setTimeout(() => {
          if (scroll.scrollTop === before) {
            snaps = 0;
            take(near.el);
          }
        }, 200);
        return;
      }

      snaps = 0;
      take(near.el);
    };

    const take = (el: HTMLElement) => {
      clear();
      el.classList.add("is-focused");
      scroll.classList.add("has-selection");
      play(el);
    };

    scroll.addEventListener(
      "scroll",
      () => {
        // Moving: no selection and no sound, and the placeholder gone too — a
        // row is passing through the band and they would collide. A voice
        // carrying on over a moving list would be a voice with nobody attached.
        scroll.classList.add("is-scrolling");
        stage.classList.add("is-scrolling");
        scroll.classList.remove("has-selection");
        clear();
        silence();
        window.clearTimeout(settleTimer);
        settleTimer = window.setTimeout(settle, 140);
      },
      { passive: true },
    );

    // Tapping a row is the same act as scrolling it in — it travels to the band
    // and the band decides, rather than being chosen behind the band's back.
    // The click also grants the activation autoplay needs.
    items.forEach((el) =>
      el.addEventListener("click", () => {
        const r = el.getBoundingClientRect();
        scroll.scrollBy({ top: r.top + r.height / 2 - bandCentre(), behavior: "smooth" });
      }),
    );

    window.addEventListener("resize", settle);

    // After layout: the rows must have a height to measure before the padding
    // and the first settle can be right.
    requestAnimationFrame(() =>
      requestAnimationFrame(() => {
        pad();
        settle();
      }),
    );
  },
};

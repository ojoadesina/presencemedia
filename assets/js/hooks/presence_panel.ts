// THE PRESENCE PANEL. The relationship list's own mechanism, one level in: a
// band a third of the way down, presences scrolling THROUGH it, and whichever
// settles there is chosen. What is different is what "chosen" does. There is no
// frame off to the side — the chosen box IS the player.
//
// Two stages, so scrolling the list is never a wall of noise:
//
//   PREVIEW — a presence that lands in the band plays MUTED. A voice breathes
//   the box (the pulse is the play effect); a face shows silently at rest size.
//   Nothing is audible, so you can scroll through a whole conversation in peace.
//
//   COMMIT — clicking the chosen presence is what turns the sound on. A face
//   also grows to full height to be looked at properly; a voice just becomes
//   audible. There is no play/pause control anywhere — the row is the control.
//
// It reverts itself. When the media finishes, or the list moves under it, the
// box shrinks back and mutes again. Nothing keeps playing over a moving list,
// and nothing stays enlarged once it is done.
type HookCtx = { el: HTMLElement };

export const PresencePanel = {
  mounted(this: HookCtx) {
    const scroll = this.el;
    const items = Array.from(scroll.querySelectorAll<HTMLElement>(".presence-item"));
    const stage = scroll.parentElement?.querySelector<HTMLElement>(".stage") ?? null;
    const video = stage?.querySelector<HTMLVideoElement>(".stage-video") ?? null;
    const audio = stage?.querySelector<HTMLAudioElement>(".stage-audio") ?? null;
    if (!items.length || !stage) return;

    // The box's state is CLASSES, not data attributes: it is phx-update="ignore"
    // so a patch never rewrites it, and classes survive a re-render where a
    // client-set src would not. `mode` is a plain variable because reading it
    // back out of the class list would be guessing at what we ourselves wrote.
    //
    //   is-voice / is-face — a presence of that kind is loaded (preview or on).
    //   is-playing         — the media is actually playing; drives the pulse.
    //   is-live            — sound is on and a face is enlarged; the commit.
    let mode = "empty";
    let src = "";

    const setKind = (next: string) => {
      stage.classList.remove("is-voice", "is-face");
      if (next !== "empty") stage.classList.add(`is-${next}`);
      mode = next;
    };
    const media = (): HTMLMediaElement | null =>
      mode === "face" ? video : mode === "voice" ? audio : null;

    // Pausing alone freezes the last frame and leaves the file downloading.
    // Dropping the src and calling load() is what stops the transfer and blanks
    // the box for the next presence.
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

    // PREVIEW: a presence lands, and it plays muted. No commit yet — a new
    // presence always arrives silent and at rest size.
    const preview = (el: HTMLElement) => {
      const nextMode = el.dataset.kind || "empty";
      const nextSrc = el.dataset.media || "";
      if (mode === nextMode && src === nextSrc) return;

      stopMedia();
      stage.classList.remove("is-live");
      setKind(nextMode);
      src = nextSrc;

      const m = media();
      if (!m || !nextSrc) return;
      m.src = nextSrc;
      m.muted = true;
      // A scroll is not a user activation; a muted clip may still be refused,
      // which is policy and must not throw. The pulse runs regardless once the
      // 'play' event lands.
      m.play().catch(() => {});
    };

    // COMMIT: the click on the already-chosen presence turns the sound on, and
    // grows a face to full height. Reaching a click is the activation the audio
    // needs. A clip that had already run out restarts from the top.
    const commit = () => {
      const m = media();
      if (!m || !src) return;
      m.muted = false;
      if (m.ended || m.paused) {
        m.currentTime = 0;
        m.play().catch(() => {});
      }
      if (mode === "face") stage.classList.add("is-live");
    };

    const silence = () => {
      stopMedia();
      stage.classList.remove("is-live");
      setKind("empty");
      src = "";
    };

    // THE PLAY EFFECT AND THE REVERT both follow the media's OWN state rather
    // than our intentions, so a clip that ends or is paused by the browser tells
    // the truth. is-playing is what the pulse rides; ending drops the commit so
    // the box shrinks and mutes itself with nothing else asked of it.
    for (const m of [video, audio]) {
      m?.addEventListener("play", () => stage.classList.add("is-playing"));
      m?.addEventListener("pause", () => stage.classList.remove("is-playing"));
      m?.addEventListener("ended", () => {
        stage.classList.remove("is-playing", "is-live");
        m.muted = true;
      });
    }

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
    // WIDTH. A full row deeper than the band, so the first row rests a row and a
    // half below it and the list opens unselected and silent.
    const pad = () => {
      const ul = scroll.querySelector<HTMLElement>("ul");
      if (!ul) return;
      const h = scroll.clientHeight;
      const rh = rowHeight();
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

      if (!near || Math.abs(near.delta) > rowHeight()) {
        scroll.classList.remove("has-selection");
        silence();
        snaps = 0;
        return;
      }

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
      preview(el);
    };

    scroll.addEventListener(
      "scroll",
      () => {
        // Moving: no selection, no sound, no placeholder — a row is passing
        // through the band and they would collide. The box reverts with it.
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

    // Clicking a row that is NOT yet chosen scrolls it into the band — the same
    // act as scrolling it there by hand, and the gesture the audio will need.
    // Clicking the one already chosen is the commit: sound on, face enlarged.
    items.forEach((el) =>
      el.addEventListener("click", () => {
        if (el.classList.contains("is-focused")) {
          commit();
          return;
        }
        const r = el.getBoundingClientRect();
        scroll.scrollBy({ top: r.top + r.height / 2 - bandCentre(), behavior: "smooth" });
      }),
    );

    window.addEventListener("resize", settle);

    requestAnimationFrame(() =>
      requestAnimationFrame(() => {
        pad();
        settle();
      }),
    );
  },
};

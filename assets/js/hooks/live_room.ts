// THE LIVE ROOM. A grid of the people whose line is open right now, and one
// set of brackets — the RETICLE — that glides between them, resting on whoever
// is speaking. That single moving frame is the whole idea: attention in a real
// room is one thing that moves, not every face outlined at once. Every call app
// boxes all of them; this one looks at whoever is talking.
//
// Here there is no microphone to listen to, so the speaker is chosen for the
// demo — a random one of the people who CAN speak (a voice or a face, never an
// open-but-silent line), held for a beat, then the reticle moves on. When the
// real signal exists, this is the one place that changes: pick by loudness
// instead of by dice, and the brackets already know how to fly.
type HookCtx = { el: HTMLElement; cleanup?: () => void };

export const LiveRoom = {
  mounted(this: HookCtx) {
    const root = this.el;
    const reticle = root.querySelector<HTMLElement>(".live-reticle");
    const stage = reticle?.parentElement ?? null; // the positioned grid
    const speakers = Array.from(root.querySelectorAll<HTMLElement>(".live-cell")).filter(
      (c) => c.dataset.speaks === "true",
    );
    if (!reticle || !stage || !speakers.length) return;

    let idx = 0;
    let timer: number | undefined;

    // Lay the reticle over a cell's FRAME (not the whole cell, which carries the
    // name below it), measured against the grid it lives in. Every frame is the
    // same size, so only the transform actually changes between speakers — which
    // is exactly what the CSS transition rides.
    const place = (cell: HTMLElement, animate: boolean) => {
      const frame = cell.querySelector<HTMLElement>(".live-frame");
      if (!frame) return;
      const fr = frame.getBoundingClientRect();
      const gr = stage.getBoundingClientRect();
      if (!animate) reticle.style.transition = "none";
      reticle.style.width = `${fr.width}px`;
      reticle.style.height = `${fr.height}px`;
      reticle.style.transform = `translate(${Math.round(fr.left - gr.left)}px, ${Math.round(fr.top - gr.top)}px)`;
      if (!animate) {
        void reticle.offsetHeight; // commit the jump before the transition returns
        reticle.style.transition = "";
      }
    };

    // Move to a DIFFERENT speaker each time, so the reticle never appears to
    // stall on the person it is already watching.
    const step = () => {
      let next = idx;
      if (speakers.length > 1) {
        while (next === idx) next = Math.floor(Math.random() * speakers.length);
      }
      idx = next;
      place(speakers[idx], true);
      timer = window.setTimeout(step, 1300 + Math.random() * 1300);
    };

    // First placement is a jump, not a glide — there is nowhere for it to fly
    // FROM. Wait a frame so the grid has laid out and the frames have real
    // rects to measure.
    requestAnimationFrame(() => {
      place(speakers[0], false);
      timer = window.setTimeout(step, 1000);
    });

    const onResize = () => place(speakers[idx], false);
    window.addEventListener("resize", onResize);

    this.cleanup = () => {
      window.clearTimeout(timer);
      window.removeEventListener("resize", onResize);
    };
  },

  destroyed(this: HookCtx) {
    this.cleanup?.();
  },
};

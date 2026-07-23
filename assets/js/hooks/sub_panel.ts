// THE SUBPANEL. On a phone the panel's two halves cannot stand side by side, so
// they become layers: the live room and the box underneath, the record stream
// riding over them. This drags that top layer.
//
// It opens BY DEFAULT, because the record stream is what you came for — the
// live room is context you glance at, not the reason you opened a person. So
// the gesture is a dismissal, not a summons: drag down to reveal what is behind,
// and it springs back if you do not mean it.
//
// TWO RESTING PLACES, never a free position. A sheet that stops wherever the
// finger left it looks broken half the time, and it makes the view behind it
// half-visible, which is worse than either state. Release nearer the top, or
// flick upward, and it closes; otherwise it goes down to a peek.
//
// Desktop never runs any of this: there the two views are columns, the panel is
// not fixed, and the handle is not rendered.
type HookCtx = { el: HTMLElement; cleanup?: () => void };

const PHONE = "(max-width: 40rem)";

export const SubPanel = {
  mounted(this: HookCtx) {
    const el = this.el;
    const handle = el.querySelector<HTMLElement>(".sub-handle");
    if (!handle) return;

    const phone = window.matchMedia(PHONE);

    // How far down "peeked" is: everything but the handle and the heading it
    // sits above, so what remains still reads as the record stream waiting
    // rather than as a stray bar. Measured, so it follows the panel's real
    // height on any screen rather than assuming one.
    const peek = () => Math.max(0, el.getBoundingClientRect().height - 88);

    let y = 0;
    const set = (next: number) => {
      y = next;
      el.style.setProperty("--sub-y", `${next}px`);
    };

    let startY = 0;
    let startAt = 0;
    let startTime = 0;
    let dragging = false;

    const down = (e: PointerEvent) => {
      if (!phone.matches) return;
      dragging = true;
      startY = e.clientY;
      startAt = y;
      startTime = e.timeStamp;
      el.classList.add("is-dragging");
      handle.setPointerCapture(e.pointerId);
    };

    const move = (e: PointerEvent) => {
      if (!dragging) return;
      // Clamped at both ends. Past the top it would cover the header, which is
      // the one thing the panel must never do — it is what the panel belongs to.
      const next = Math.min(peek(), Math.max(0, startAt + (e.clientY - startY)));
      set(next);
    };

    const up = (e: PointerEvent) => {
      if (!dragging) return;
      dragging = false;
      el.classList.remove("is-dragging");

      const dt = Math.max(1, e.timeStamp - startTime);

      // A TAP IS A TOGGLE. The handle looks pressable and people press it, so
      // treating every pointerdown as a drag left a tap doing nothing at all —
      // the panel sprang straight back and read as broken. Barely-moved and
      // quick is a press; anything else is a drag and falls through below.
      if (Math.abs(y - startAt) < 6 && dt < 500) {
        set(y > 0 ? 0 : peek());
        return;
      }

      // A FLICK BEATS THE POSITION. Someone who throws it downward means it even
      // if they let go early, and someone who throws it up means to close it
      // even from near the bottom — going on distance alone ignores intent.
      const velocity = (y - startAt) / dt; // px per ms, positive = downward
      if (Math.abs(velocity) > 0.4) set(velocity > 0 ? peek() : 0);
      else set(y > peek() / 2 ? peek() : 0);
    };

    handle.addEventListener("pointerdown", down);
    handle.addEventListener("pointermove", move);
    handle.addEventListener("pointerup", up);
    handle.addEventListener("pointercancel", up);

    // Rotating the phone changes the peek distance, so a panel resting down
    // would otherwise sit at yesterday's offset.
    const onResize = () => {
      if (!phone.matches) set(0);
      else if (y > 0) set(peek());
    };
    window.addEventListener("resize", onResize);

    this.cleanup = () => window.removeEventListener("resize", onResize);
  },

  destroyed(this: HookCtx) {
    this.cleanup?.();
  },
};

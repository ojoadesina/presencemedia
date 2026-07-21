// THE PRESENCE STREAM. The same mechanism as the relationship list, one level
// down: a fixed box a third of the way in, and presences that scroll THROUGH it
// rather than being clicked. Whichever settles there is captured, and the box
// shows everything the row was holding back.
//
// This is deliberately a copy of `regions.ts` rather than a shared abstraction.
// The two lists sit at different levels of the same app and will drift — one
// chooses a person, the other chooses a moment — and a base class that has to
// serve both would end up parameterised into something neither of them reads
// like. When they have stopped moving, factor them; not before.
//
// Selection resolves on SETTLE, not continuously: a card rebuilding itself for
// every row that flies past during a flick reads as noise, not as choosing.
type HookCtx = { el: HTMLElement; pushEvent: (event: string, payload: object) => void };

export const Stream = {
  mounted(this: HookCtx) {
    const scroll = this.el;
    const push = this.pushEvent.bind(this);
    const items = Array.from(scroll.querySelectorAll<HTMLElement>(".stream-item"));
    if (!items.length) return;

    let settleTimer: number | undefined;
    // A snap scrolls, which settles, which may snap again. Bounded, so a snap
    // the scroller cannot actually perform — already at either end — gives up
    // instead of retrying forever.
    let snaps = 0;

    const rowHeight = () => items[0].getBoundingClientRect().height;
    const bandCentre = () => {
      const r = scroll.getBoundingClientRect();
      // The box sits at 34% of the list, not its middle — the same third the
      // relationship list uses, so the two screens rhyme.
      return r.top + r.height * 0.34;
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

    const clear = () => items.forEach((i) => i.classList.remove("is-captured"));

    // Reported only on change: a settle that lands on the presence already
    // captured is not news, and re-sending it would rebuild the card and
    // restart whatever was playing in it.
    let reported: number | null = null;
    const report = (index: number | null) => {
      if (index === reported) return;
      reported = index;
      if (index === null) push("release_presence", {});
      else push("capture_presence", { index });
    };

    const settle = () => {
      scroll.classList.remove("is-scrolling");
      clear();
      const near = nearest();

      // Out of reach — the box is genuinely empty and says so.
      if (!near || Math.abs(near.delta) > rowHeight()) {
        scroll.classList.remove("has-capture");
        report(null);
        snaps = 0;
        return;
      }

      // In reach but off-centre — draw it in, and settle again when it lands.
      if (Math.abs(near.delta) > 1 && snaps < 3) {
        snaps++;
        scroll.scrollBy({ top: near.delta, behavior: "smooth" });
        return;
      }

      snaps = 0;
      near.el.classList.add("is-captured");
      scroll.classList.add("has-capture");
      report(items.indexOf(near.el));
    };

    scroll.addEventListener(
      "scroll",
      () => {
        scroll.classList.add("is-scrolling");
        scroll.classList.remove("has-capture");
        clear();
        window.clearTimeout(settleTimer);
        settleTimer = window.setTimeout(settle, 140);
      },
      { passive: true },
    );

    // Tapping a row is the same act as scrolling it in — it travels to the box
    // and the box decides, rather than being selected behind the box's back.
    items.forEach((el) =>
      el.addEventListener("click", () => {
        const r = el.getBoundingClientRect();
        scroll.scrollBy({ top: r.top + r.height / 2 - bandCentre(), behavior: "smooth" });
      }),
    );

    window.addEventListener("resize", settle);
    settle();
  },
};

// THE PRESENCE STREAM. The same mechanism as the relationship list, one level
// down: a fixed box a third of the way in, and presences that scroll THROUGH it
// rather than being clicked. Whichever settles there is captured, and the box
// shows everything the row was holding back.
//
// WHERE THE BOX SITS IS THE LIST'S BUSINESS, not the mechanism's, so it comes
// in as `data-anchor`. On /presence it is "top": a presence is chosen in order
// to be watched, and what is watched belongs directly under the screen showing
// it, so the chosen row rises to first position and the rest queue below. The
// panel inside a relationship keeps the default third — there the stream is one
// element among several and a box pinned to its top edge would read as a
// heading rather than as a sight.
//
// This is deliberately a copy of `scopes.ts` rather than a shared abstraction.
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

    // A third of the way down unless the list asks for its own top edge.
    const at = scroll.dataset.anchor === "top" ? 0 : 0.34;

    const rowHeight = () => items[0].getBoundingClientRect().height;

    // THE LEAD AND TRAIL ARE MEASURED, not written in the markup, because they
    // cannot be written there: the box sits at a fraction of the scroller's
    // HEIGHT, and a percentage padding resolves against WIDTH. Any figure
    // hard-coded in the template is therefore right at exactly one viewport size
    // and wrong everywhere else — which is why the first row once sat 31px above
    // the band and the snap then tried to scroll up from zero to fix it.
    //
    // Computed here, the first row lands ON the band at rest and the last one
    // can still reach it. Anchored at the top the lead falls out to nothing: the
    // list starts already aimed, with nothing above it to scroll past.
    const lead = () => {
      const list = scroll.querySelector<HTMLElement>("ul");
      if (!list) return;
      const h = scroll.clientHeight;
      const half = rowHeight() / 2;
      list.style.paddingTop = `${Math.max(0, h * at - half)}px`;
      list.style.paddingBottom = `${Math.max(0, h * (1 - at) - half)}px`;
    };
    const bandCentre = () => {
      const r = scroll.getBoundingClientRect();
      return r.top + Math.max(r.height * at, rowHeight() / 2);
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
    // Starts UNDEFINED rather than null, and that distinction is load-bearing.
    // With null as the initial value, the first `report(null)` — which is what a
    // settle sends when nothing is in reach — matched and returned early, so the
    // server was never told and kept the default capture it had been given at
    // mount. A box holding a presence the hook had already released.
    let reported: number | null | undefined = undefined;
    const report = (index: number | null) => {
      if (index === reported) return;
      reported = index;
      if (index === null) push("release_presence", {});
      else push("capture_presence", { index });
    };

    const settle = () => {
      lead();
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
      //
      // A SCROLLER AT ITS END CANNOT MOVE, and then no scroll event arrives to
      // settle again with — so the retry loop, which is driven entirely by that
      // event, simply stops and nothing is ever captured. That is exactly what
      // happened at the top of this list: the first row sits 31px above the
      // band, the snap asks to scroll up from zero, nothing moves, and the box
      // stayed empty forever. Watch for the scroll that did not happen and take
      // the row anyway.
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
      el.classList.add("is-captured");
      scroll.classList.add("has-capture");
      report(items.indexOf(el));
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

    // WHICH SENTENCES ACTUALLY OVERFLOW. The two-line fade splits at 50% of the
    // box, so on a one-line row it would cut that single line in half — there
    // is nothing below it to fade into. Only the rows that really run past two
    // lines get masked.
    const clamp = () =>
      scroll.querySelectorAll<HTMLElement>(".stream-line").forEach((line) =>
        line.classList.toggle("is-clamped", line.scrollHeight > line.clientHeight + 1),
      );
    clamp();
    window.addEventListener("resize", clamp);

    window.addEventListener("resize", settle);

    // THE SCROLLER'S OWN HEIGHT CHANGES WITHOUT THE WINDOW'S. It takes what the
    // screen above it leaves, so capturing a face shortens it by a screen's
    // worth — and the trail padding, which is measured from that height, would
    // go on describing the list it used to be. Then the last presence cannot
    // reach the box. No resize event fires for this; only the element knows.
    new ResizeObserver(() => lead()).observe(scroll);

    // AFTER LAYOUT, not during mount. Every row now holds a card, and a card has
    // an icon in it — so at mount time the rows can still measure zero, which
    // makes rowHeight() zero, which makes every row further than one row away,
    // which releases the capture and then never runs again because nothing
    // scrolls. Two frames is enough for the rows to have a size to compare.
    requestAnimationFrame(() => requestAnimationFrame(settle));
  },
};

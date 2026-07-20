// THE REGION LIST. A fixed band a third of the way down the list is the
// selection: rows scroll THROUGH it, and whichever lands there is chosen.
//
// Selection resolves on SETTLE, not continuously — a highlight strobing past
// every row during a flick reads as noise, not as choosing. That single choice
// is what gives the line its rule too: the line and the marker ARE the settled
// choice made visible, so they leave the moment the list moves and return only
// once it has come to rest on a row.
//
// On settling, the nearest row PULLS ITSELF to the band's centre rather than
// sitting wherever the scroll happened to stop. A row only does that from
// within one row's reach; beyond that the band stands genuinely empty, which is
// what lets the list rest unselected at the top instead of magnetising the
// first row in.
export const Regions = {
  mounted(this: { el: HTMLElement }) {
    const scroll = this.el;
    const items = Array.from(scroll.querySelectorAll<HTMLElement>(".regions-item"));
    const root = document.getElementById("regions");
    if (!root || !items.length) return;

    let settleTimer: number | undefined;
    // A snap scrolls, which settles, which may snap again. Bounded, so a snap
    // the scroller cannot actually perform (already at either end) gives up
    // instead of retrying forever.
    let snaps = 0;

    const rowHeight = () => items[0].getBoundingClientRect().height;
    const bandCentre = () => {
      const r = scroll.getBoundingClientRect();
      // The band sits at 34% of the list, not its middle.
      return r.top + r.height * 0.34;
    };

    // The nearest row and how far it is from the band, signed: positive means
    // the row sits below the band, so scrolling down by that much lifts it in.
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
      root.classList.remove("is-scrolling");
      clear();
      const near = nearest();

      // Out of reach — the band is genuinely empty and says so.
      if (!near || Math.abs(near.delta) > rowHeight()) {
        root.classList.remove("has-selection");
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
      near.el.classList.add("is-focused");
      root.classList.add("has-selection");
    };

    scroll.addEventListener(
      "scroll",
      () => {
        // Moving: no selection, no line, and no placeholder either — a row is
        // passing through the band and they would collide.
        root.classList.add("is-scrolling");
        root.classList.remove("has-selection");
        clear();
        window.clearTimeout(settleTimer);
        settleTimer = window.setTimeout(settle, 140);
      },
      { passive: true },
    );

    // Tapping a row is the same act as scrolling it in — it travels to the band
    // and the band decides, rather than being selected behind the band's back.
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

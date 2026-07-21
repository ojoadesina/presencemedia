// THE PICK. The band and the frame are already one element — the bar — so
// picking an item up is not a matter of assembling anything, only of moving
// what is there. It travels by TRANSFORM and nothing else, which is not a
// performance choice: the frame inside it may be mid-sentence, and moving a
// <video> in the DOM pauses it. Nothing here touches the tree.
//
// The server owns WHETHER it is picked (the `is-picked` class arrives with a
// patch); this hook owns HOW FAR, because that is a question about the viewport
// that only the client can answer.
const HEADER_TOP = 32; // 2rem of air above the header, per the design

export const Bar = {
  mounted(this: { el: HTMLElement }) {
    // ONLY THE DELTA GOES HERE, never the bar's own -50% centring shift.
    // Tailwind v4 writes `-translate-y-1/2` to the `translate` PROPERTY, not to
    // `transform`, and the two compose — `translate` is applied first, then
    // `transform` on top. Repeating the -50% here therefore doubled it and sat
    // the band half its own height above the row it was supposed to be framing.
    // The centring belongs to the class; the travel belongs to this.
    let shift = 0;

    const apply = (px: number) => {
      shift = px;
      this.el.style.transform = px === 0 ? "" : `translateY(${px}px)`;
    };

    // Measured from where it IS, not from where it started, so a resize or a
    // second pick corrects rather than compounds.
    const fly = () => {
      const top = this.el.getBoundingClientRect().top;
      apply(shift + (HEADER_TOP - top));
    };

    const land = () => apply(0);

    this.sync = () => (this.el.classList.contains("is-picked") ? fly() : land());
    this.sync();

    // A resize moves the band, and with it the distance left to travel.
    this.onResize = () => this.sync();
    window.addEventListener("resize", this.onResize);
  },

  // The class flips on the server, so the move has to be re-derived after every
  // patch. Cheap: one measurement and one style write.
  updated(this: { sync: () => void }) {
    this.sync();
  },

  destroyed(this: { onResize: () => void }) {
    window.removeEventListener("resize", this.onResize);
  },
};

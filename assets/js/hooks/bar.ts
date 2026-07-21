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
    // The bar sits at top-[34%] with a -50% shift of its own. Every transform
    // written here has to carry that shift along, or the bar jumps half its
    // height the instant we touch it.
    let shift = 0;

    const apply = (px: number) => {
      shift = px;
      this.el.style.transform = `translateY(calc(-50% + ${px}px))`;
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

// THE SCREEN under the band. It plays whatever the captured presence carries,
// the moment it arrives — the box exists to show more than the row could, so
// asking for a gesture first would be the box failing at its one job.
//
// Its id carries the captured index, so scrolling to another presence replaces
// the element outright and this hook is destroyed with it. That is what stops
// one clip playing on underneath the next.
export const Screen = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const url = el.dataset.media;
    const kind = el.dataset.kind;
    if (!url) return;

    const video = el.querySelector<HTMLVideoElement>(".screen-video");
    const fill = el.querySelector<HTMLElement>(".screen-fill");

    // A face plays in the screen itself. A voice has nothing to look at, so it
    // plays through an Audio element and the strip is all there is to see.
    const media: HTMLMediaElement = kind === "face" && video ? video : new Audio();
    if (media !== video) media.preload = "none";
    media.setAttribute("src", url);

    // Only the strip needs a position: a face shows where it is by what is on
    // it. requestAnimationFrame rather than timeupdate, which fires about four
    // times a second and would make a 10-second clip visibly step.
    let raf = 0;
    const follow = () => {
      if (fill && media.duration) {
        el.style.setProperty("--played", `${(media.currentTime / media.duration) * 100}%`);
      }
      raf = requestAnimationFrame(follow);
    };

    // Autoplay with sound needs a user activation. Reaching this takes clicks,
    // so there always is one — but a refusal is policy rather than a fault and
    // must not throw.
    media.play().catch(() => {});
    if (fill) raf = requestAnimationFrame(follow);

    media.addEventListener("ended", () => {
      cancelAnimationFrame(raf);
      el.style.setProperty("--played", "0%");
    });

    this.cleanup = () => {
      cancelAnimationFrame(raf);
      media.pause();
      media.removeAttribute("src");
    };
  },

  destroyed(this: { cleanup?: () => void }) {
    this.cleanup?.();
  },
};

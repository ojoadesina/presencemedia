// A CAPTURED PRESENCE.
//
// It plays the moment it arrives. Asking for a swipe first was friction dressed
// as an interaction: the box exists to show more than the row could, so making
// you work for it is the box failing at its one job — and it hid the media
// twice over, once in the list and again behind a card, when scrolling
// something into the box is already the act of saying you want it.
//
// The swipe is still there, but it now leads to an empty layer held for later.
// Playback does not depend on it and does not stop for it.
export const Presence = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const url = el.dataset.media;
    const kind = el.dataset.kind || "voice";

    const status = el.querySelector<HTMLElement>(".presence-status");
    const elapsed = el.querySelector<HTMLElement>(".presence-elapsed");
    const video = el.querySelector<HTMLVideoElement>(".presence-video");

    // A text presence has nothing to play and says so by carrying no media.
    if (!url) {
      if (status) status.textContent = "";
      return;
    }

    // Voice plays through an Audio element and leaves the screen dark, because
    // there is nothing to look at; a face plays in the screen itself.
    const media: HTMLMediaElement = kind === "face" && video ? video : new Audio();
    if (media !== video) media.preload = "none";

    const clock = (s: number) =>
      `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;

    let raf = 0;
    const tick = () => {
      if (elapsed) elapsed.textContent = clock(media.currentTime);
      raf = requestAnimationFrame(tick);
    };

    media.setAttribute("src", url);
    if (video && kind === "face") video.classList.remove("hidden");
    if (status) status.textContent = kind === "face" ? "playing face" : "playing voice";

    // Autoplay with sound needs a user activation. Reaching a captured presence
    // takes several clicks, so by here there always is one — but a refusal is
    // the browser's policy rather than a fault, and must not throw.
    media
      .play()
      .then(() => {
        el.classList.add("is-playing");
        // Heard is not a thing you undo. Once played, it stops asking.
        el.classList.remove("is-unheard");
      })
      .catch(() => {
        if (status) status.textContent = "";
      });

    raf = requestAnimationFrame(tick);

    media.addEventListener("ended", () => {
      el.classList.remove("is-playing");
      if (status) status.textContent = "";
      if (elapsed) elapsed.textContent = clock(0);
      if (video) video.classList.add("hidden");
      cancelAnimationFrame(raf);
    });

    this.cleanup = () => {
      cancelAnimationFrame(raf);
      media.pause();
      media.removeAttribute("src");
    };
  },

  // The captured card's id carries the captured index, so scrolling to another
  // presence destroys this one outright. Tearing the media down here is what
  // stops a clip playing on under whatever replaced it.
  destroyed(this: { cleanup?: () => void }) {
    this.cleanup?.();
  },
};

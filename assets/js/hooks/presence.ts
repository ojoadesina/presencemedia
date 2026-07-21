// A LEFT PRESENCE.
//
// The recorder's transport, run backwards. There, sliding a layer aside ARMED a
// stream; here it UNCOVERS one — the gesture that reveals the media is the
// gesture that starts it. Same invention, read in reverse.
//
// scrollend rather than scroll, and a threshold rather than a position, both
// taken from the original: a swipe is judged once it has SETTLED, so a finger
// dragged halfway and released does not start anything.
const THRESHOLD = 0.95 * 0.8;

export const Presence = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const url = el.dataset.media;
    const kind = el.dataset.kind || "voice";

    const layer = el.querySelector<HTMLElement>(".presence-layer");
    const inner = el.querySelector<HTMLElement>(".presence-inner");
    const status = el.querySelector<HTMLElement>(".presence-status");
    const elapsed = el.querySelector<HTMLElement>(".presence-elapsed");
    const video = el.querySelector<HTMLVideoElement>(".presence-video");
    if (!url || !layer) return;

    // Voice plays through an Audio element and leaves the screen dark, because
    // there is nothing to look at; face plays in the screen itself.
    const media: HTMLMediaElement = kind === "face" && video ? video : new Audio();
    if (media !== video) media.preload = "none";

    const clock = (s: number) =>
      `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;

    let raf = 0;
    const tick = () => {
      if (elapsed) elapsed.textContent = clock(media.currentTime);
      raf = requestAnimationFrame(tick);
    };

    // The original held a flag for 500ms while it moved a layer itself, so its
    // own scroll would not be read back as the user's. Same problem here, same
    // answer: carrying you to the video layer must not look like you asked.
    let selfScrolling = false;

    const play = () => {
      if (!media.getAttribute("src")) media.setAttribute("src", url);
      media.play().catch(() => {});
      el.classList.add("is-playing");
      // Heard is not a thing you undo. Once played, it stops asking.
      el.classList.remove("is-unheard");
      if (status) status.textContent = kind === "face" ? "playing face" : "playing voice";
      if (video && kind === "face") video.classList.remove("hidden");

      // A face has something to look at, so it is carried one layer further and
      // the pane slides off the picture. A voice stays on the tinted pane,
      // which is the whole reason that layer exists.
      if (kind === "face" && inner) {
        selfScrolling = true;
        inner.scrollTo({ left: inner.scrollWidth, behavior: "smooth" });
        setTimeout(() => (selfScrolling = false), 500);
      }

      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(tick);
    };

    const pause = () => {
      media.pause();
      el.classList.remove("is-playing");
      if (status) status.textContent = "";
      cancelAnimationFrame(raf);
    };

    layer.addEventListener("scrollend", () => {
      const open = layer.scrollLeft > layer.clientWidth * THRESHOLD;
      if (open && media.paused) play();
      else if (!open && !media.paused) pause();
    });

    // Sliding the inner layer back by hand takes the picture away without
    // stopping the sound — the same clip, heard rather than watched.
    inner?.addEventListener("scrollend", () => {
      if (selfScrolling || kind !== "face" || !video) return;
      const onVideo = inner.scrollLeft > inner.clientWidth * THRESHOLD;
      video.classList.toggle("hidden", !onVideo);
      if (status) status.textContent = onVideo ? "playing face" : "playing voice";
    });

    media.addEventListener("ended", () => {
      pause();
      if (elapsed) elapsed.textContent = clock(0);
      if (video) video.classList.add("hidden");
      // A finished presence goes back to being a card rather than sitting open
      // on a screen with nothing on it.
      selfScrolling = true;
      inner?.scrollTo({ left: 0, behavior: "smooth" });
      layer.scrollTo({ left: 0, behavior: "smooth" });
      setTimeout(() => (selfScrolling = false), 500);
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

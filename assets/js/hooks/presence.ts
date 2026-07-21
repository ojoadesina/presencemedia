// A LEFT PRESENCE.
//
// The recorder's idea, run backwards. There, sliding the card aside ARMED the
// stream; here it REVEALS the playback — the gesture that uncovers the media is
// the gesture that starts it. That is the invention worth keeping: a swipe as
// transport rather than as navigation.
//
// scrollend rather than scroll, and a threshold rather than a position, both
// taken from the original: a swipe is judged once it has settled, so a finger
// dragged halfway and released does not start anything.
const THRESHOLD = 0.95 * 0.8;

export const Presence = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const url = el.dataset.media;
    const kind = el.dataset.kind || "voice";

    const layer = el.querySelector<HTMLElement>(".presence-layer");
    const status = el.querySelector<HTMLElement>(".presence-status");
    const elapsed = el.querySelector<HTMLElement>(".presence-elapsed");
    const video = el.querySelector<HTMLVideoElement>(".presence-video");
    const text = el.querySelector<HTMLTextAreaElement>(".presence-text");

    // ── the field grows with what is in it ──────────────────────────────────
    // Height must be cleared before it is measured: scrollHeight of an element
    // already stretched to fit reports the stretched height, so without the
    // reset the field can only ever grow and never shrink back.
    const grow = () => {
      if (!text) return;
      text.style.height = "auto";
      text.style.height = `${text.scrollHeight}px`;
    };
    text?.addEventListener("input", grow);
    grow();

    if (!url || !layer) return;

    // Voice plays through an Audio element and leaves the screen black; face
    // plays in the screen itself. One transport, two surfaces.
    const media: HTMLMediaElement = kind === "face" && video ? video : new Audio();
    if (media !== video) media.preload = "none";

    const clock = (s: number) =>
      `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;

    let raf = 0;
    const tick = () => {
      if (elapsed) elapsed.textContent = clock(media.currentTime);
      raf = requestAnimationFrame(tick);
    };

    const play = () => {
      if (!media.getAttribute("src")) media.setAttribute("src", url);
      media.play().catch(() => {});
      el.classList.add("is-playing");
      // Heard is not a thing you undo. Once played, it stops asking.
      el.classList.remove("is-unheard");
      if (status) status.textContent = kind === "face" ? "playing face" : "playing voice";
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

    media.addEventListener("ended", () => {
      pause();
      if (elapsed) elapsed.textContent = clock(0);
      // Slide the card back, so a finished presence returns to being a card
      // rather than sitting open on a screen with nothing on it.
      layer.scrollTo({ left: 0, behavior: "smooth" });
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

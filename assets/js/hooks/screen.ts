// THE SCREEN under the band. It READIES the captured presence — it does not
// play it. That distinction is the whole reason this file changed: the box
// captures whatever settles in it, but settling is exactly what browsing looks
// like, and the interface cannot tell "I am scanning past this" from "I want
// this one." Auto-playing on capture answered that question wrong on every
// scroll, so it ambushed the reader with a voice or a face they never asked
// for. Now it does not guess. A tap is the answer.
//
// Its id carries the captured index, so scrolling to another presence replaces
// the element outright and this hook is destroyed with it — which is what stops
// one clip playing on underneath the next, and what leaves the new one readied
// and silent rather than inheriting the old one's playback.
export const Screen = {
  mounted(this: { el: HTMLElement; cleanup?: () => void }) {
    const el = this.el;
    const url = el.dataset.media;
    const kind = el.dataset.kind;
    if (!url) return;

    const video = el.querySelector<HTMLVideoElement>(".screen-video");
    const fill = el.querySelector<HTMLElement>(".screen-fill");
    const clock = el.querySelector<HTMLElement>(".screen-time");

    // A face plays in the screen itself. A voice has nothing to look at, so it
    // plays through an Audio element and the strip is all there is to see.
    const media: HTMLMediaElement = kind === "face" && video ? video : new Audio();
    media.preload = "metadata";
    media.setAttribute("src", url);

    // A READIED FACE IS ITS FIRST FRAME, not a black rectangle — otherwise the
    // screen gives no sign there is anything to play. preload="metadata" only
    // reaches the header, which paints nothing, so nudge the time a hair: a seek
    // forces the browser to decode and show that one frame. Done once, and only
    // before anything has actually played.
    if (media === video) {
      video.addEventListener(
        "loadedmetadata",
        () => {
          if (video.currentTime === 0) {
            try {
              video.currentTime = 0.05;
            } catch {
              /* a source that refuses the seek stays black; not fatal */
            }
          }
        },
        { once: true },
      );
    }

    // The count runs UP from zero, the way the old recorder counted — a presence
    // is a length of someone's time, not a countdown to being done with them.
    const clockFace = (t: number) =>
      `${Math.floor(t / 60)}:${String(Math.floor(t % 60)).padStart(2, "0")}`;

    // Only while playing. A readied screen is completely idle — no rAF spinning,
    // nothing moving — which is the point of readying rather than playing.
    let raf = 0;
    const follow = () => {
      if (fill && media.duration) {
        el.style.setProperty("--played", `${(media.currentTime / media.duration) * 100}%`);
      }
      if (clock) clock.textContent = clockFace(media.currentTime);
      raf = requestAnimationFrame(follow);
    };

    // ONE TAP ON THE SCREEN plays or pauses it, with sound. Reaching a tap is a
    // user activation, so the audio is allowed; a refusal is policy, not a
    // fault, and must not throw.
    const toggle = () => {
      if (media.paused) media.play().catch(() => {});
      else media.pause();
    };
    el.addEventListener("click", toggle);

    // The play mark and the ticking follow the media's OWN state rather than the
    // tap, so a clip that ends, or is paused by the browser, still tells the
    // truth. is-playing is what clears the play mark in CSS.
    media.addEventListener("play", () => {
      el.classList.add("is-playing");
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(follow);
    });
    media.addEventListener("pause", () => {
      el.classList.remove("is-playing");
      cancelAnimationFrame(raf);
    });
    media.addEventListener("ended", () => {
      el.classList.remove("is-playing");
      cancelAnimationFrame(raf);
      el.style.setProperty("--played", "0%");
      if (clock) clock.textContent = "0:00";
      // Rewound to its first frame, readied to be played again.
      if (media === video) {
        try {
          video.currentTime = 0.05;
        } catch {
          /* ignore */
        }
      }
    });

    this.cleanup = () => {
      cancelAnimationFrame(raf);
      el.removeEventListener("click", toggle);
      media.pause();
      media.removeAttribute("src");
    };
  },

  destroyed(this: { cleanup?: () => void }) {
    this.cleanup?.();
  },
};

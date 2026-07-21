// A LEFT PRESENCE, playing.
//
// The hook sits on the presence rectangle itself rather than on a control inside
// it: the rectangle is the press target, so it is what knows how to play. There
// is no separate button to wire up and nothing above it has to coordinate — a
// presence is self-contained and can be dropped straight into a chat column.
//
// It drives exactly one thing now: whether the rectangle is running. Position is
// no longer shown, so nothing here tracks it — a pulse answers "is this going",
// which is a question about a presence, where a fill answered "how far through",
// which is a question about a bar.
export const Waveform = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const url = el.dataset.media;
    if (!url) return;

    const audio = new Audio();
    audio.preload = "none";

    const play = () => {
      if (!audio.src) audio.src = url;
      audio.play().catch(() => {});
      el.classList.add("is-playing");
      // Heard is not a thing you undo. Once played, it stops asking.
      el.classList.remove("is-unheard");
    };

    const stop = () => {
      audio.pause();
      el.classList.remove("is-playing");
    };

    const toggle = () => (audio.paused ? play() : stop());
    this.toggle = toggle;

    el.addEventListener("click", toggle);

    // role="button" earns a keyboard, and a rectangle you can press with a mouse
    // but not with a key is a button in costume only.
    el.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        toggle();
      }
    });

    audio.addEventListener("ended", stop);

    this.cleanup = () => {
      audio.pause();
      audio.removeAttribute("src");
    };
  },

  destroyed(this: { cleanup?: () => void }) {
    this.cleanup?.();
  },
};

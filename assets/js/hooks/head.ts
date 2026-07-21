// THE MARK, as a control. Clicking it flips the theme and plays the entrance
// again from the top, so the thing you pressed visibly answers rather than the
// page just changing colour underneath you.
export const Head = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const svg = el.querySelector<SVGElement>(".head");

    // WHAT YOU ARE LOOKING AT, not what is stored. With no data-theme the page
    // is following the OS, so the honest opposite of what is on screen comes
    // from the media query rather than from an attribute that is not there.
    const showingDark = () => {
      const explicit = document.documentElement.getAttribute("data-theme");
      if (explicit) return explicit === "dark";
      return window.matchMedia("(prefers-color-scheme: dark)").matches;
    };

    // Removing the class is not enough on its own: the browser coalesces the
    // removal and the re-add into one style recalculation, sees no net change,
    // and never restarts the animation. Reading a layout property in between
    // forces the recalculation to happen, which is what makes the replay real.
    const replay = () => {
      if (!svg) return;
      svg.classList.remove("is-animated");
      void svg.getBoundingClientRect().width;
      svg.classList.add("is-animated");
    };

    el.addEventListener("click", () => {
      const next = showingDark() ? "light" : "dark";
      replay();
      // The listener in root.html.heex reads the theme off the event's target,
      // so the attribute has to be in place before the event goes out.
      el.dataset.phxTheme = next;
      el.dispatchEvent(new CustomEvent("phx:set-theme", { bubbles: true }));
      el.setAttribute("aria-label", `Switch to ${next === "dark" ? "light" : "dark"} theme`);
    });
  },
};

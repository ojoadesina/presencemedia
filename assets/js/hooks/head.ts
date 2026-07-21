// THE MARK, as a control. Clicking it flips the theme, replays the entrance,
// and washes the incoming colour out across the screen from under the logo, so
// the thing you pressed visibly delivers the change rather than the page
// swapping colour on its own.
export const Head = {
  mounted(this: { el: HTMLElement }) {
    const el = this.el;
    const svg = el.querySelector<SVGElement>(".head");
    const still = window.matchMedia("(prefers-reduced-motion: reduce)");

    // WHAT YOU ARE LOOKING AT, not what is stored. With no data-theme the page
    // is following the OS, so the honest opposite of what is on screen comes
    // from the media query rather than from an attribute that is not there.
    const showingDark = () => {
      const explicit = document.documentElement.getAttribute("data-theme");
      if (explicit) return explicit === "dark";
      return window.matchMedia("(prefers-color-scheme: dark)").matches;
    };

    const applyTheme = (next: string) => {
      // The listener in root.html.heex reads the theme off the event's target,
      // so the attribute has to be in place before the event goes out.
      el.dataset.phxTheme = next;
      el.dispatchEvent(new CustomEvent("phx:set-theme", { bubbles: true }));
      el.setAttribute("aria-label", `Switch to ${next === "dark" ? "light" : "dark"} theme`);
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

    const wash = (next: string) => {
      // Only ever one in flight. Clicking twice quickly should leave the second
      // wash on screen, not race the first one's cleanup.
      document.querySelectorAll(".theme-wash").forEach((n) => n.remove());

      const box = el.getBoundingClientRect();
      const cx = box.left + box.width / 2;
      const cy = box.top + box.height / 2;

      // Reach the FURTHEST corner, or the disc stops short of one and leaves a
      // wedge of the old colour behind at the moment we swap themes.
      const r = Math.hypot(
        Math.max(cx, window.innerWidth - cx),
        Math.max(cy, window.innerHeight - cy),
      );

      const disc = document.createElement("div");
      disc.className = "theme-wash";
      disc.dataset.target = next;
      disc.style.left = `${cx - r}px`;
      disc.style.top = `${cy - r}px`;
      disc.style.width = disc.style.height = `${r * 2}px`;

      // INSIDE #regions, not on the body, and this is not a detail. #regions
      // carries z-0, which on a positioned element opens a stacking context —
      // so the mark's z-30 is only meaningful against its siblings INSIDE that
      // context. A disc parented to the body competes with #regions as a whole
      // and wins outright, burying the logo no matter what number it carries.
      // Same parent, same context, and the z-indexes mean what they say.
      (document.getElementById("regions") ?? document.body).appendChild(disc);

      const spread = disc.animate(
        [{ transform: "scale(0)" }, { transform: "scale(1)" }],
        { duration: 620, easing: "cubic-bezier(0.32, 0, 0.2, 1)", fill: "forwards" },
      );

      spread.finished
        .then(() => {
          // Covered. Swap underneath and re-launch the mark, then uncover a
          // page that has already changed — which is what makes the disc look
          // like the cause rather than a curtain drawn over a repaint.
          //
          // The replay waits until HERE on purpose. Restarting it at click time
          // shrinks the mark to a near-invisible speck for the whole held
          // phase, so the colour would appear to spread out of nothing at all —
          // and the source being visible is the entire illusion.
          applyTheme(next);
          replay();
          return disc.animate([{ opacity: 1 }, { opacity: 0 }], {
            duration: 300,
            easing: "ease-out",
            fill: "forwards",
          }).finished;
        })
        .catch(() => {})
        .finally(() => disc.remove());
    };

    el.addEventListener("click", () => {
      const next = showingDark() ? "light" : "dark";

      // Reduced motion gets the theme and none of the theatre. Note this is
      // read per click rather than captured at mount, so changing the OS
      // setting mid-session is respected without a reload.
      if (still.matches || typeof document.body.animate !== "function") {
        applyTheme(next);
        return;
      }
      // wash() owns the theme swap and the replay, because both belong to the
      // moment of full coverage rather than to the click.
      wash(next);
    });
  },
};

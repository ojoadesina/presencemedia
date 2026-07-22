// THE SCOPES LIST. A fixed band a third of the way down the list is the
// selection: rows scroll THROUGH it, and whichever lands there is chosen. It is
// MODAL — the same scroller and band carry the people you hold (SCOPED), the
// people you don't (UNSCOPED), and a roll of countries (LOCATION); the server
// swaps the rows by changing the element's id, which re-runs this hook fresh.
//
// Selection resolves on SETTLE, not continuously — a highlight strobing past
// every row during a flick reads as noise, not as choosing. That single choice
// is what gives the line its rule too: the line and the marker ARE the settled
// choice made visible, so they leave the moment the list moves and return only
// once it has come to rest on a row.
//
// On settling, the nearest row PULLS ITSELF to the band's centre rather than
// sitting wherever the scroll happened to stop. A row only does that from
// within one row's reach; beyond that the band stands genuinely empty, which is
// what lets the list rest unselected at the top instead of magnetising the
// first row in.
type HookCtx = { el: HTMLElement; pushEvent: (event: string, payload: object) => void };

export const Scopes = {
  mounted(this: HookCtx) {
    const scroll = this.el;
    const push = this.pushEvent.bind(this);
    // THE TRANSIENT CLASSES LIVE ON THE SCROLLER, not on #scopes, and that is
    // not a preference. #scopes is the LiveView root: every patch rewrites its
    // class attribute back to whatever the server rendered, so a hook-set
    // `has-selection` survived only until the next update — which is why the
    // frame vanished and the placeholder came back the moment an item was
    // picked. The scroller carries phx-update="ignore", so it is the one
    // element in the tree LiveView will not touch. The CSS reaches the bar from
    // here with a sibling combinator.
    const items = Array.from(scroll.querySelectorAll<HTMLElement>(".scopes-item"));
    const root = document.getElementById("scopes");
    if (!root || !items.length) return;

    // THE FRAME is ONE element that every row borrows in turn, rather than one
    // frame per row: nineteen <video> tags would each hold a buffer for a
    // picture nobody is looking at. The cost of sharing is that the media must
    // be torn down on the way out as deliberately as it is set up on the way in.
    const frame = document.getElementById("frame");
    const video = frame?.querySelector<HTMLVideoElement>(".frame-video") ?? null;
    const audio = frame?.querySelector<HTMLAudioElement>(".frame-audio") ?? null;
    const restart = frame?.querySelector<HTMLButtonElement>(".frame-restart") ?? null;

    // THE FRAME'S STATE IS CLASSES, NOT DATA ATTRIBUTES, and that is forced by
    // LiveView rather than chosen: on a patched element it strips a client-set
    // src, and on an ignored one it still merges data-* from the server's copy
    // and deletes any the client added. Classes it leaves alone in both cases,
    // so the frame keeps its own mind across a re-render. `mode` is tracked in a
    // plain variable because reading it back out of a class list would be
    // guessing at what we ourselves wrote.
    const MODES = ["is-empty", "is-voice", "is-face"];
    const STATES = ["is-present", "is-live", "is-absent"];
    let mode = "empty";
    let src = "";

    const setFrame = (nextMode: string, nextState: string) => {
      if (!frame) return;
      frame.classList.remove(...MODES, ...STATES);
      frame.classList.add(`is-${nextMode}`, `is-${nextState}`);
      mode = nextMode;
    };

    // Which element the current mode is actually driving. Everything that acts
    // on "the media" goes through here, so play, replay and teardown can never
    // disagree about what they are addressing.
    const current = (): HTMLMediaElement | null =>
      mode === "face" ? video : mode === "voice" ? audio : null;

    // Pausing alone leaves the last frame of the previous person frozen on
    // screen and the file still downloading. Dropping the src and calling
    // load() is what actually stops the transfer and blanks the picture.
    const stopMedia = () => {
      for (const m of [video, audio]) {
        if (!m) continue;
        m.pause();
        if (m.getAttribute("src")) {
          m.removeAttribute("src");
          m.load();
        }
      }
    };

    const showFrame = (el: HTMLElement) => {
      if (!frame) return;
      const nextMode = el.dataset.frame || "empty";
      const nextSrc = el.dataset.media || "";
      const nextState = el.dataset.state || "present";

      // Re-selecting the row that is already playing must not restart it.
      if (mode === nextMode && src === nextSrc) {
        setFrame(nextMode, nextState);
        return;
      }

      stopMedia();
      setFrame(nextMode, nextState);
      src = nextSrc;
      // A new person has arrived, so the previous one's finished-clip control
      // must go with them.
      frame.classList.remove("is-ended");

      const media = current();
      if (!media || !nextSrc) return;

      media.src = nextSrc;
      // Autoplay with sound needs a user activation. A scroll is not one, so
      // the first selection of a session can legitimately be refused — that is
      // the browser's policy, not a failure, and it must not throw an unhandled
      // rejection. Any click on a row satisfies it from then on.
      //
      // A REFUSAL IS TREATED AS ENDED. Sound is the default and staying muted
      // is not on offer, so the honest thing when the browser says no is to
      // show the replay control — one click both satisfies the policy and
      // starts the clip, instead of leaving a dead frame with no way in.
      media.play().catch(() => {
        if (src === nextSrc) frame.classList.add("is-ended");
      });
    };

    const hideFrame = () => {
      if (!frame) return;
      stopMedia();
      setFrame("empty", "present");
      src = "";
      frame.classList.remove("is-ended");
    };

    // A clip that runs out has not gone away — the person is still selected and
    // the frame still theirs, so it keeps the last picture and offers the clip
    // again rather than blanking.
    for (const m of [video, audio]) {
      m?.addEventListener("ended", () => frame?.classList.add("is-ended"));
    }

    restart?.addEventListener("click", (e) => {
      // The frame beneath toggles size on click. Replay is a different intent
      // that happens to live inside it, so it must not also resize.
      e.stopPropagation();
      const media = current();
      if (!media) return;
      media.currentTime = 0;
      media.play().catch(() => {});
      frame?.classList.remove("is-ended");
    });

    // EXPAND is a toggle on the frame itself, so the size lives in one
    // attribute and CSS decides what that is worth in pixels.
    const toggleExpand = () => {
      if (!frame) return;
      const open = frame.classList.toggle("is-expanded");
      frame.setAttribute("aria-label", open ? "Collapse frame" : "Expand frame");
    };

    frame?.addEventListener("click", toggleExpand);
    // role="button" earns a keyboard, and a keyboard expects both of these.
    frame?.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        toggleExpand();
      }
    });

    let settleTimer: number | undefined;
    // A snap scrolls, which settles, which may snap again. Bounded, so a snap
    // the scroller cannot actually perform (already at either end) gives up
    // instead of retrying forever.
    let snaps = 0;

    const rowHeight = () => items[0].getBoundingClientRect().height;
    const bandCentre = () => {
      const r = scroll.getBoundingClientRect();
      // The band sits at 34% of the list, not its middle.
      return r.top + r.height * 0.34;
    };

    // The nearest row and how far it is from the band, signed: positive means
    // the row sits below the band, so scrolling down by that much lifts it in.
    const nearest = (): { el: HTMLElement; delta: number } | null => {
      const centre = bandCentre();
      let best: { el: HTMLElement; delta: number } | null = null;
      for (const el of items) {
        const r = el.getBoundingClientRect();
        const delta = r.top + r.height / 2 - centre;
        if (!best || Math.abs(delta) < Math.abs(best.delta)) best = { el, delta };
      }
      return best;
    };

    const clear = () => items.forEach((i) => i.classList.remove("is-focused"));

    // WHO IS SELECTED NOW BELONGS TO THE SERVER. The hook is still the only
    // thing that can DECIDE it — it owns the scroll, and the answer is a
    // question about pixels — but the panel is real content about a real
    // person, so the process holding the data has to be told. Sent only on
    // change: a settle that lands on the row already chosen is not news.
    let reported: number | null = null;
    const report = (index: number | null) => {
      if (index === reported) return;
      reported = index;
      if (index === null) push("deselect", {});
      else push("select", { index });
    };

    const settle = () => {
      scroll.classList.remove("is-scrolling");
      clear();
      const near = nearest();

      // Out of reach — the band is genuinely empty and says so.
      if (!near || Math.abs(near.delta) > rowHeight()) {
        scroll.classList.remove("has-selection");
        hideFrame();
        report(null);
        snaps = 0;
        return;
      }

      // In reach but off-centre — draw it in, and settle again when it lands.
      // No media yet: the row is still travelling, and a clip that started here
      // would be cut off by the next settle a few hundred milliseconds later.
      //
      // A SCROLLER AT ITS END CANNOT MOVE, and then no scroll event arrives to
      // settle again with — so this retry, which is driven entirely by that
      // event, stops and nothing is ever selected. It does not bite here today
      // only because the lead padding leaves the band out of reach at rest; the
      // presence stream has the same code and different padding, and there it
      // hung the box empty forever. Watch for the scroll that did not happen.
      if (Math.abs(near.delta) > 1 && snaps < 3) {
        const before = scroll.scrollTop;
        snaps++;
        scroll.scrollBy({ top: near.delta, behavior: "smooth" });
        window.setTimeout(() => {
          if (scroll.scrollTop === before) {
            snaps = 0;
            take(near.el);
          }
        }, 200);
        return;
      }

      snaps = 0;
      take(near.el);
    };

    const take = (el: HTMLElement) => {
      clear();
      el.classList.add("is-focused");
      scroll.classList.add("has-selection");
      showFrame(el);
      report(items.indexOf(el));
    };

    scroll.addEventListener(
      "scroll",
      () => {
        // Moving: no selection, no line, and no placeholder either — a row is
        // passing through the band and they would collide.
        scroll.classList.add("is-scrolling");
        scroll.classList.remove("has-selection");
        clear();
        // The frame leaves with the selection. Sound continuing over a moving
        // list would be a voice with nobody attached to it.
        hideFrame();
        window.clearTimeout(settleTimer);
        settleTimer = window.setTimeout(settle, 140);
      },
      { passive: true },
    );

    // Tapping a row is the same act as scrolling it in — it travels to the band
    // and the band decides, rather than being selected behind the band's back.
    items.forEach((el) =>
      el.addEventListener("click", () => {
        const r = el.getBoundingClientRect();
        scroll.scrollBy({ top: r.top + r.height / 2 - bandCentre(), behavior: "smooth" });
      }),
    );

    window.addEventListener("resize", settle);
    settle();
  },
};

defmodule PresencemediaWeb.HomeLive do
  @moduledoc """
  The presence app's home.

  A scroll of the users you hold, with a fixed band a third of the way down that
  IS the selection: rows pass THROUGH it and whichever lands there is chosen.
  The band shows your name for them with their own name beside it, faded, and
  the frame at the far edge comes alive with whatever they are sending.

  The users are FIXTURE DATA. This app has no database at all yet — it does not
  even depend on Ecto — so nothing here is loaded, only rendered. That is
  deliberate: the surface is being designed before the spine is built. The MEDIA
  those fixtures point at is real, though, and fetched from Wikimedia Commons at
  play time, so what you are looking at is the actual behaviour and not a mime
  of it.
  """
  use PresencemediaWeb, :live_view

  # Wikimedia Commons serves a permanent MP3/WebM transcode alongside every
  # upload. We point at those rather than the .ogg and .webm originals for one
  # blunt reason: Safari cannot play Ogg Vorbis at all, and the originals are
  # 9–14 MB apiece for a screen that is forty-five pixels square. The 360p
  # transcodes are roughly a tenth of that.
  @commons "https://upload.wikimedia.org/wikipedia/commons/transcoded"

  # A USER is a label YOU gave them, the name they came with, and what their
  # frame is currently carrying. The label leads because it is how you actually
  # think of them; the name follows, faded, and only once the row is in the band.
  #
  # STATE and FRAME are two different questions and are kept apart on purpose.
  # State asks about the PERSON and the line to them; frame asks what is coming
  # THROUGH it. The two are orthogonal, and every combination means something:
  #
  #   "absent"  — not reachable. The screen drains to neutral rather than to a
  #               paler terracotta, because terracotta is the colour of someone
  #               being there and a weak version of it reads as a weak signal
  #               rather than as nobody.
  #   "present" — reachable. The screen keeps its colour and sits still unless
  #               there is media to move it.
  #   "live"    — the line is open right now. The screen breathes EVEN WITH
  #               NOTHING COMING THROUGH, which is the whole point of the state:
  #               a live line with no voice and no face is still a live line,
  #               and a still screen could not say so. The frame breathes with
  #               it, on the same period, so the two read as one thing being
  #               alive rather than two things blinking.
  #
  # Absence pairs with an empty frame here for the obvious reason — you cannot
  # be away and talking — but nothing in the code enforces that, because a line
  # can perfectly well carry a recording of someone who has since gone. Live is
  # deliberately spread across all three frame modes below, so the empty case
  # that proves the state is worth having actually appears.
  #
  # FRAME is the state of the line to them, and it is deliberately three-valued
  # rather than a boolean, because "nothing coming through" and "audio coming
  # through" are different facts and the frame renders them differently:
  #
  #   "empty" — no signal. The screen sits still.
  #   "voice" — audio only. The screen breathes, because there is nothing to
  #             look at and the sound is the whole message.
  #   "face"  — video. The screen holds still and shows it.
  #
  # THE MEDIA IS REAL, and chosen to match what this app is for. The voices come
  # from Commons' Voice Intro Project, where people record a short introduction
  # of themselves — the closest thing to a real first contact that exists under
  # a free licence. The faces come from Wikitongues, whose recordings are single
  # speakers talking to camera. Every clip is under a minute. Licences run CC0
  # to CC BY-SA; attribution lives in ATTRIBUTION.md at the repo root.
  @users [
    %{
      label: "MUM",
      name: "SARAH",
      state: "present",
      frame: "voice",
      media:
        "#{@commons}/4/4f/Simone_Giertz_introducing_herself.ogg/" <>
          "Simone_Giertz_introducing_herself.ogg.mp3"
    },
    %{
      label: "DAD",
      name: "MICHAEL",
      state: "present",
      frame: "face",
      media:
        "#{@commons}/6/67/WIKITONGUES-_Paulus_speaking_Mentuka.webm/" <>
          "WIKITONGUES-_Paulus_speaking_Mentuka.webm.360p.vp9.webm"
    },
    %{
      label: "BIG BROTHER",
      name: "DANIEL OLUWASEUN",
      state: "present",
      frame: "voice",
      media: "#{@commons}/0/0a/Charles_Duke_Intro.ogg/Charles_Duke_Intro.ogg.mp3"
    },
    %{label: "BROTHER", name: "JOSEPH", state: "absent", frame: "empty", media: nil},
    %{
      label: "SISTER",
      name: "AMAKA",
      state: "live",
      frame: "face",
      media:
        "#{@commons}/0/01/WIKITONGUES-_Hermica_speaking_Bengape.webm/" <>
          "WIKITONGUES-_Hermica_speaking_Bengape.webm.360p.vp9.webm"
    },
    %{
      label: "GRANDMA",
      name: "ROSE",
      state: "live",
      frame: "voice",
      media: "#{@commons}/c/ca/Robin_Owain_en_Voice.ogg/Robin_Owain_en_Voice.ogg.mp3"
    },
    %{label: "COACH", name: "IBRAHIM", state: "live", frame: "empty", media: nil},
    %{
      label: "BEST FRIEND",
      name: "TUNDE ADEBAYO",
      state: "present",
      frame: "face",
      media:
        "#{@commons}/3/31/WIKITONGUES-_C%C3%A9lestin_speaking_Kilega.webm/" <>
          "WIKITONGUES-_C%C3%A9lestin_speaking_Kilega.webm.360p.vp9.webm"
    },
    %{label: "NEIGHBOUR", name: "ELENA", state: "absent", frame: "empty", media: nil},
    %{
      label: "COUSIN",
      name: "KEMI",
      state: "present",
      frame: "voice",
      media:
        "#{@commons}/4/46/Dan_Barker_introducing_himself.ogg/" <>
          "Dan_Barker_introducing_himself.ogg.mp3"
    },
    %{label: "UNCLE", name: "PETER", state: "absent", frame: "empty", media: nil},
    %{
      label: "AUNT",
      name: "BLESSING",
      state: "present",
      frame: "face",
      media:
        "#{@commons}/0/04/WIKITONGUES-_Donald_speaking_Tswana.webm/" <>
          "WIKITONGUES-_Donald_speaking_Tswana.webm.360p.vp9.webm"
    },
    %{
      label: "MENTOR",
      name: "ADEOLA",
      state: "present",
      frame: "voice",
      media:
        "#{@commons}/e/ed/Richard_Rogers_-_voice_-_en.ogg/Richard_Rogers_-_voice_-_en.ogg.mp3"
    },
    %{label: "ROOMMATE", name: "LUCAS", state: "present", frame: "empty", media: nil},
    %{label: "BOSS", name: "HANNAH", state: "absent", frame: "empty", media: nil},
    %{label: "DOCTOR", name: "NGOZI", state: "live", frame: "empty", media: nil},
    %{label: "BARBER", name: "FEMI", state: "absent", frame: "empty", media: nil},
    %{label: "PASTOR", name: "EMMANUEL", state: "present", frame: "empty", media: nil},
    %{label: "TEAMMATE", name: "CHIDI", state: "absent", frame: "empty", media: nil}
  ]

  # A LEFT PRESENCE is one someone recorded and left behind, as opposed to the
  # live presence the frame carries. The two are not the same object and must
  # not look alike: a live presence has no duration and no shape, which is why
  # it breathes; a left one is FINISHED, so it has a beginning, an end and a
  # length you can see. Shape is what a recording earns by being over.
  #
  # `from` is here from the start because this row becomes the chat row later —
  # the only difference then is the order they are stacked in. `heard` is the
  # one piece of state a left presence has that a live one cannot: you can miss
  # it, and it should say so.
  @presence_pool [
    %{
      kind: "voice",
      when: "07:12",
      len: "0:10",
      from: "them",
      heard: true,
      media: "#{@commons}/9/96/Andy_Mabbett_voice.ogg/Andy_Mabbett_voice.ogg.mp3"
    },
    %{
      kind: "face",
      when: "08:03",
      len: "0:37",
      from: "you",
      heard: true,
      media:
        "#{@commons}/8/8e/WIKITONGUES-_Sedang_speaking_Iban.webm/" <>
          "WIKITONGUES-_Sedang_speaking_Iban.webm.360p.vp9.webm"
    },
    %{
      kind: "voice",
      when: "09:41",
      len: "0:15",
      from: "them",
      heard: true,
      media: "#{@commons}/b/bb/Bettany_Hughes_voice.ogg/Bettany_Hughes_voice.ogg.mp3"
    },
    %{
      kind: "voice",
      when: "11:26",
      len: "0:17",
      from: "you",
      heard: true,
      media: "#{@commons}/0/01/David_Lammy_voice.ogg/David_Lammy_voice.ogg.mp3"
    },
    %{
      kind: "face",
      when: "12:58",
      len: "0:46",
      from: "them",
      heard: true,
      media:
        "#{@commons}/2/26/WIKITONGUES-_Tarkhan_speaking_Jek.webm/" <>
          "WIKITONGUES-_Tarkhan_speaking_Jek.webm.360p.vp9.webm"
    },
    %{
      kind: "voice",
      when: "14:07",
      len: "0:16",
      from: "them",
      heard: true,
      media: "#{@commons}/e/ec/David_Harewood_voice.ogg/David_Harewood_voice.ogg.mp3"
    },
    %{
      kind: "face",
      when: "15:34",
      len: "0:54",
      from: "you",
      heard: true,
      media:
        "#{@commons}/e/ea/WIKITONGUES-_Uladzislau_speaking_Belarusian.webm/" <>
          "WIKITONGUES-_Uladzislau_speaking_Belarusian.webm.360p.vp9.webm"
    },
    %{
      kind: "voice",
      when: "17:19",
      len: "0:18",
      from: "them",
      heard: true,
      media: "#{@commons}/0/0f/Alison_Balsom_voice.ogg/Alison_Balsom_voice.ogg.mp3"
    },
    %{
      kind: "face",
      when: "18:45",
      len: "0:48",
      from: "them",
      heard: false,
      media:
        "#{@commons}/c/c9/WIKITONGUES-_Jeries_speaking_Syriac.webm/" <>
          "WIKITONGUES-_Jeries_speaking_Syriac.webm.360p.vp9.webm"
    },
    %{
      kind: "voice",
      when: "20:02",
      len: "0:16",
      from: "you",
      heard: true,
      media: "#{@commons}/f/fa/Brian_Schmidt_voice.ogg/Brian_Schmidt_voice.ogg.mp3"
    },
    %{
      kind: "face",
      when: "21:30",
      len: "0:56",
      from: "them",
      heard: false,
      media:
        "#{@commons}/2/20/WIKITONGUES-_Yernur_speaking_Kazakh.webm/" <>
          "WIKITONGUES-_Yernur_speaking_Kazakh.webm.360p.vp9.webm"
    },
    %{
      kind: "face",
      when: "22:51",
      len: "0:58",
      from: "them",
      heard: false,
      media:
        "#{@commons}/0/05/WIKITONGUES-_Rizki_speaking_Malay.webm/" <>
          "WIKITONGUES-_Rizki_speaking_Malay.webm.360p.vp9.webm"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    users =
      @users
      |> Enum.with_index()
      |> Enum.map(fn {user, i} -> Map.put(user, :presences, presences_for(user, i)) end)

    {:ok,
     socket
     |> assign(users: users, scope: "SCOPED", selected: nil, mode: :list)
     |> put_current()}
  end

  # DORMANT. Nothing renders `user.presences` since the presence panel was
  # emptied — it is kept computed rather than torn out because it is real,
  # curated, voice/face-only media, the raw material the rebuilt panel will
  # draw on. When the new panel lands, this is what it reads; until then it
  # simply rides along, built and unshown.
  #
  # Newest first, the way a feed reads. `by` is resolved here rather than stored
  # on the pool, because who left a presence depends on whose stream it is
  # appearing in — the same clip is "them" in one and "YOU" in another.
  defp presences_for(user, index) do
    n = length(@presence_pool)

    # A CONVERSATION HAS TWO COLOURS, always maximally apart. Where /presence is
    # a feed of many creators each holding their own hue, a relationship's stream
    # is between exactly two people — you and them — so it reads as two tones
    # rather than a spread. The person's hue comes off their place in the roster
    # by the golden angle, and YOU take its complement, 180 degrees round, so
    # whoever you are talking to your two sides of the exchange never blur into
    # each other.
    person_hue = index |> Kernel.*(137.508) |> round() |> Integer.mod(360)
    you_hue = Integer.mod(person_hue + 180, 360)

    # Rotated so no two people's streams are identical, then SORTED, because a
    # rotation would otherwise leave the times out of order — and a stream that
    # is not chronological is not a stream.
    for k <- 0..5 do
      Enum.at(@presence_pool, rem(index * 4 + k, n))
    end
    |> Enum.sort_by(& &1.when)
    |> Enum.map(fn presence ->
      presence
      |> Map.put(:by, (presence.from == "you" && "YOU") || user.name)
      |> Map.put(:hue, (presence.from == "you" && you_hue) || person_hue)
      |> Map.put(:rule, rule_width(presence.len))
    end)
  end

  # HOW LONG, AS A LENGTH. A collapsed presence needs to say more than who left
  # it, but a second line of text would clutter the list and a filled block would
  # read as the captured card and make the screen argue with itself.
  #
  # A rule does neither. It is a line, so it cannot be confused with a
  # rectangle, and its LENGTH is the duration — the same idea as a highlight
  # running short on its last line: you read "this much" without reading a
  # number. Floored well above zero so a ten-second presence is still a mark
  # rather than a speck, and capped so a minute cannot run into the time.
  # Text has no duration, so it gets no rule at all rather than an invented one.
  defp rule_width(nil), do: nil

  defp rule_width(len) do
    [minutes, seconds] = String.split(len, ":")
    secs = String.to_integer(minutes) * 60 + String.to_integer(seconds)
    "#{Float.round(1.5 + min(secs, 60) / 60 * 8.5, 2)}rem"
  end

  # SELECTION NOW REACHES THE SERVER. It used to live only in the hook, which was
  # enough for a highlight and nowhere near enough for a panel: the open view is
  # real content about a real person, so the process that owns the data has to
  # know which person that is. The hook still decides WHO — it is the only thing
  # that can, since it owns the scroll — and reports the answer here.
  @impl true
  def handle_event("select", %{"index" => index}, socket) do
    {:noreply, socket |> assign(selected: index) |> put_current()}
  end

  def handle_event("deselect", _params, socket) do
    # Losing the selection closes the panel with it. There is no such thing as an
    # open view of nobody.
    {:noreply, socket |> assign(selected: nil, mode: :list) |> put_current()}
  end

  # One event for both directions, because the band is one target and which way
  # it goes is a fact the server already holds. Clicking it with nothing selected
  # does nothing at all — there is no item to pick up.
  def handle_event("toggle_open", _params, socket) do
    case {socket.assigns.selected, socket.assigns.mode} do
      {nil, _} -> {:noreply, socket}
      {_, :open} -> {:noreply, assign(socket, mode: :list)}
      {_, :list} -> {:noreply, assign(socket, mode: :open)}
    end
  end

  def handle_event("toggle_scope", _params, socket) do
    {:noreply,
     update(socket, :scope, fn
       "SCOPED" -> "UNSCOPED"
       _ -> "SCOPED"
     end)}
  end

  # The chosen user is resolved ONCE, here, and stored. Looking it up inside the
  # template would mean calling a function with `assigns`, which switches
  # LiveView's change tracking off for that whole block — the panel would then be
  # re-sent on every unrelated update.
  defp put_current(socket) do
    assign(
      socket,
      :current,
      socket.assigns.selected && Enum.at(socket.assigns.users, socket.assigns.selected)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- ── THE RELATIONSHIP LIST ──────────────────────────────────────────────
         The reference overlay, MIRRORED: list left, frame at the far right.
         No globe, no background grid.

         A fixed band a third of the way down the list IS the selection: rows
         scroll THROUGH it and whichever lands there is chosen, snapping itself
         to the centre. Band and frame are ONE flex row, so the two cannot fall
         out of line. TYPE is responsive where the geometry is fixed — one clamp
         ramp shared by the rows and the band's placeholder, so those two can
         never disagree. Styles Tailwind cannot express — the corner brackets,
         the two fade masks, the voice pulse, the state rules — live under
         "THE RELATIONSHIP LIST" in app.css.
    --%>
    <div
      id="regions"
      class={[
        "fixed inset-0 z-0 bg-light-50 font-mono dark:bg-dark-950",
        @mode == :open && "is-open"
      ]}
    >
      <%!-- THE MARK sits ABSOLUTELY, not in the flow, and that is the whole
           trick of putting it here. The band's position is derived from the
           list's — 37vh of lead, then 34% down the container — so anything
           added above the heading would push the list down and take the band
           with it. Out of flow, the mark cannot move the one piece of geometry
           this screen is built on.

           It shares the rows' 1.95rem inset rather than the container's, which
           is what puts it on the same left edge as "19+", RELATIONSHIPS, and
           every label below them. --%>
      <%!-- z-30 clears the theme wash at z-20. The colour has to look like it is
           coming OUT of the mark, which it cannot do while painting over it. --%>
      <div class="mark-slot pointer-events-none absolute inset-x-0 top-32 z-30">
        <div class="mx-auto w-full max-w-6xl px-4">
          <%!-- A BUTTON, not a link. It used to point home, but home is this
               page — there is only one route — so the click was doing nothing
               and the affordance was lying. It flips the theme instead, and
               replays its own entrance while doing it, so the thing you pressed
               answers rather than the page just changing colour underneath
               you. --%>
          <button
            id="logo"
            type="button"
            phx-hook="Head"
            class="pointer-events-auto inline-block cursor-pointer px-[1.95rem] outline-none focus-visible:ring-2 focus-visible:ring-primary-500/40"
            aria-label="Switch theme"
          >
            <.head class="h-20 text-primary-600 dark:text-primary-500" />
          </button>
        </div>
      </div>

      <%!-- the OLD design's measure, kept: the same mx-auto max-w-6xl px-4 the
           slot grid sat in, so this surface lines up with what came before. --%>
      <div class="mx-auto h-full w-full max-w-6xl px-4">
        <div class="pt-[max(1rem,calc(37vh-84px))]">
          <%!-- The heading is NOT held to the list's width — a line of prose
               needs the room to be a line of prose. It shares only the rows'
               inset, which is what puts every left edge on one line. --%>
          <div class="lede max-w-2xl px-[1.95rem]">
            <%!-- w-fit is the whole mechanism, and it is load-bearing. A block
                 <p> is as wide as its CONTAINER, not as its text, so anything
                 right-aligned inside one lands at the container's edge and
                 drifts away from the words the moment the copy changes length.
                 Shrink-wrapping the pair means the box hangs off the end of the
                 SENTENCE — shorten the line and the box comes with it, lengthen
                 it and the box follows, with no measurement written down
                 anywhere to go stale. --%>
            <div class="w-fit">
              <p class="mt-2 text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.15em] text-neutral-300 dark:text-neutral-200">
                SO YOU DON'T DO LIFE ALONE
              </p>

              <div class="flex justify-end">
                <button
                  type="button"
                  phx-click="toggle_scope"
                  aria-pressed={to_string(@scope == "SCOPED")}
                  class="scope-box relative mt-3 cursor-pointer px-3 py-1.5 text-sm tracking-[0.18em] text-sky-600 transition-colors outline-none hover:text-sky-500 focus-visible:ring-2 focus-visible:ring-sky-500/40 dark:text-sky-400 dark:hover:text-sky-300"
                >
                  {@scope}
                </button>
              </div>
            </div>
          </div>

          <%!-- The list steps aside for the panel by FADING, never by
               unmounting. The bar is positioned against this box, so a
               container that collapsed would drag the header off its own line
               halfway through the flight — and keeping the DOM is also what
               makes the return free: same scroll offset, same focused row,
               because nothing was ever destroyed. --%>
          <div class={["relative mt-5 w-[32rem]", @mode == :open && "list-away"]}>
            <%!-- phx-update="ignore": the hook marks the focused row with a
                 class, and a patch must never wipe it. --%>
            <div
              id="regions-scroll"
              phx-hook="Regions"
              phx-update="ignore"
              class="regions-scroll h-[50vh] overflow-y-auto overscroll-contain"
            >
              <%!-- The lead and trail are what let the first and last row REACH
                   the band. The lead is one row deeper than the band, which
                   leaves the band standing empty at rest — the unselected
                   state. --%>
              <ul class="pt-[calc(17vh+4rem)] pb-[33vh]">
                <%!-- The row CARRIES its own frame, as data rather than as
                     markup. One shared frame reads these on settle, which is
                     why nineteen rows cost nineteen attributes instead of
                     nineteen media elements. --%>
                <li
                  :for={user <- @users}
                  data-state={user.state}
                  data-frame={user.frame}
                  data-media={user.media}
                  class="regions-item flex h-[4rem] cursor-pointer items-center whitespace-nowrap px-[1.95rem] text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-light-900 dark:text-dark-100"
                >
                  <span>{user.label}</span>
                  <%!-- their own name, quiet beside the label: it arrives only
                       when the row is in the band, and never competes with it.
                       It keeps its own colour on purpose — the focused row turns
                       terracotta, and the name staying muted is what stops the
                       band reading as two labels shouting at once. --%>
                  <span class="regions-name ml-3 text-light-300 opacity-0 transition-opacity duration-200 dark:text-dark-600">
                    {user.name}
                  </span>
                </li>
              </ul>
            </div>

            <%!-- band · frame — two things in one row, so they cannot fall out
                 of line with each other. The row spans the container's whole
                 measure, and the frame takes ml-auto to hold the far edge
                 itself: the line used to be the flex-1 that pushed it there,
                 and the line is not coming back.

                 Both appear only on a settled selection — the band is the
                 question and the frame is who answered it. --%>
            <div
              id="bar"
              phx-hook="Bar"
              class={[
                "bar pointer-events-none absolute left-0 top-[34%] flex w-[calc(min(100vw,72rem)-2rem)] -translate-y-1/2 items-center",
                @mode == :open && "is-picked"
              ]}
            >
              <%!-- THE LEFT HALF IS THE HANDLE. Clicking here picks the whole
                   bar up and carries it to the top; clicking the frame at the
                   other end still only resizes the frame. Two targets, two
                   jobs, one bar — which is why neither had to be given up.

                   pointer-events-auto against the row's none: the bar as a whole
                   must let a moving list through, but this half of it is the one
                   thing in that row you are meant to press. --%>
              <div
                phx-click="toggle_open"
                class={[
                  "focus-box pointer-events-auto relative flex h-[3.5rem] w-[32rem] shrink-0 items-center",
                  "bg-primary-600/15 px-[1.95rem] dark:bg-primary-500/20",
                  @selected && "cursor-pointer"
                ]}
              >
                <%!-- ABSOLUTE, not merely transparent. It was opacity-0 and
                     still in flow, so its 27px of width sat in front of the
                     header's label and pushed the text to 59px from the box
                     edge where the list's rows start at 31px. Invisible is not
                     the same as absent. --%>
                <span class="focus-empty absolute text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-primary-600 opacity-0 transition-opacity duration-200 dark:text-primary-500">
                  --
                </span>
                <%!-- THE BAR TAKES OVER THE TEXT at the moment of the pick, and
                     not before. In the list the words you read are the ROW's,
                     showing through a translucent band — lift the bar then and
                     it would fly away leaving its own label behind. Rendering
                     them here only once open means the handover happens while
                     the two are still exactly on top of each other, so there is
                     nothing to see. --%>
                <%!-- Neutral, not terracotta. Once this is a header it is no
                     longer the thing being chosen — it is the label on what is
                     below it, and terracotta is this surface's word for "look
                     here". Spending it on the header would leave the content
                     arguing with its own title. --%>
                <%!-- min-w-0 so the flex child may actually shrink, and the
                     fade so a name too long for the box FADES OUT at its edge
                     rather than pushing the box wider or spilling past the
                     brackets. Same treatment the rows already use, so a long
                     name reads identically in either place. --%>
                <span
                  :if={@mode == :open && @current}
                  class="focus-name flex min-w-0 flex-1 items-baseline overflow-hidden whitespace-nowrap text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-light-900 dark:text-dark-100"
                >
                  {@current.label}
                  <span class="ml-3 text-light-500 dark:text-dark-500">{@current.name}</span>
                </span>
              </div>
              <%!-- THE FRAME — one element that is both the box's target and the
                   person it landed on. The brackets aim it; the fill behind them
                   is that person, and the fill's breathing is their VOICE, which
                   is what presence sounds like before there is anything to see.

                   The same element takes a call later without changing shape:
                   video replaces the fill, the brackets stay aiming, and the dot
                   goes on meaning connected. That is why voice had to be the
                   surface rather than a ring around the dot — a ring expands
                   past its own bounds, and a frame that will one day hold a
                   picture cannot have its contents leaking outside it. --%>
              <%!-- pointer-events-auto: the row this sits in turns them off, so
                   a moving list is never blocked by an overlay. The frame is
                   the one thing in that row you are meant to reach.

                   EXPANDING grows it in place rather than lifting it into a
                   modal. ml-auto pins its right edge, so the extra width opens
                   leftward into the empty half of the screen and the frame
                   never leaves the line the band put it on. --%>
              <%!-- phx-update="ignore" IS LOAD-BEARING HERE, and for the media
                   rather than for the styling. Without it a patch rewrites this
                   subtree and strips the src the hook put on the <video>, which
                   stops a face mid-sentence. With it, LiveView leaves the
                   children alone entirely.

                   Its state is all in CLASSES for the matching reason: on an
                   ignored element LiveView still merges data-* from the server's
                   copy and deletes any the client added, so hook-set data
                   attributes would survive only until the next patch. Classes it
                   does not touch. The frame is therefore wholly client-owned,
                   which is honest — a playing media element cannot be driven
                   from the server anyway. --%>
              <div
                id="frame"
                phx-update="ignore"
                role="button"
                tabindex="0"
                aria-label="Expand frame"
                class="frame is-empty pointer-events-auto relative ml-auto flex h-[3.8rem] w-[3.8rem] shrink-0 cursor-pointer items-center justify-center p-2 opacity-0 transition-[opacity,width,height,padding] duration-300"
              >
                <%!-- THE SCREEN is inset from the frame, so the brackets bracket
                     the picture instead of cropping it, and it is square on
                     every corner — a screen has corners, and rounding them
                     would turn it into a widget. --%>
                <div class="frame-screen relative h-full w-full overflow-hidden bg-primary-600/15 dark:bg-primary-500/20">
                  <video
                    class="frame-video h-full w-full object-cover"
                    playsinline
                    preload="none"
                  >
                  </video>

                  <%!-- Sits ON the screen, covering it, because after a clip
                       ends the screen is the only thing there — a control
                       tucked into a corner of a 45px square would be a target
                       nobody can hit. --%>
                  <button
                    type="button"
                    class="frame-restart absolute inset-0 hidden items-center justify-center bg-light-950/15 text-light-50 transition-colors hover:bg-light-950/30 dark:bg-dark-950/25 dark:hover:bg-dark-950/40"
                    aria-label="Play again"
                  >
                    <%!-- Inline rather than a heroicon: this is a three-quarter
                         arc with an arrowhead, which reads as "again" in a way
                         heroicons' closed two-arrow loop does not — that one
                         says "sync". Sized by class, not by the width/height
                         the source carried, so it can grow with the frame. --%>
                    <svg
                      viewBox="0 0 1024 1024"
                      fill="currentColor"
                      stroke="currentColor"
                      stroke-width="0"
                      aria-hidden="true"
                      class="size-4"
                    >
                      <path d="M909.1 209.3l-56.4 44.1C775.8 155.1 656.2 92 521.9 92 290 92 102.3 279.5 102 511.5 101.7 743.7 289.8 932 521.9 932c181.3 0 335.8-115 394.6-276.1 1.5-4.2-.7-8.9-4.9-10.3l-56.7-19.5a8 8 0 0 0-10.1 4.8c-1.8 5-3.8 10-5.9 14.9-17.3 41-42.1 77.8-73.7 109.4A344.77 344.77 0 0 1 655.9 829c-42.3 17.9-87.4 27-133.8 27-46.5 0-91.5-9.1-133.8-27A341.5 341.5 0 0 1 279 755.2a342.16 342.16 0 0 1-73.7-109.4c-17.9-42.4-27-87.4-27-133.9s9.1-91.5 27-133.9c17.3-41 42.1-77.8 73.7-109.4 31.6-31.6 68.4-56.4 109.3-73.8 42.3-17.9 87.4-27 133.8-27 46.5 0 91.5 9.1 133.8 27a341.5 341.5 0 0 1 109.3 73.8c9.9 9.9 19.2 20.4 27.8 31.4l-60.2 47a8 8 0 0 0 3 14.1l175.6 43c5 1.2 9.9-2.6 9.9-7.7l.8-180.9c-.1-6.6-7.8-10.3-13-6.2z" />
                    </svg>
                  </button>
                </div>
                <%!-- No controls, so the UA never renders it — the screen is the
                     only thing a voice is allowed to look like. --%>
                <audio class="frame-audio" preload="none"></audio>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ── THE PRESENCE PANEL ───────────────────────────────────────────────
           What opens under the header once a relationship has been picked up.
           It is a SIBLING of the list rather than a child, and fixed rather than
           in flow, because the list must keep its geometry while hidden: the bar
           is positioned against the list's box, so a collapsing container would
           drag the header off its own line mid-flight.

           It carries the relationship list's own design, one level in: the
           same rows, the same band a third of the way down, the same scroll
           that chooses. What is different is the content — these are the
           presences that relationship left, named by whoever left them — and
           what selection does. There is no frame on the right. The chosen box
           is the player: a voice breathes it, a face fills it, and it plays the
           moment it lands, so the frame's whole job is delegated to the
           selection and nothing sits off to the side. --%>
      <div
        :if={@mode == :open && @current}
        id="presence-panel"
        class="presence-panel fixed inset-x-0 top-30 bottom-0 z-20"
      >
        <div class="mx-auto h-full w-full max-w-6xl px-4">
          <div class="relative h-full w-[32rem]">
            <%!-- THE BOX — the relationship list's own selection box, kept
                 whole: the wash, the brackets, the "--" placeholder for the
                 empty band. The ONLY thing left behind is the frame off to the
                 side; its job moves in here. The box stands at the band always,
                 and a landing presence fills it — a voice breathes it, a face
                 shows in it. It sits BEHIND the rows (z-0 to their z-10) so the
                 chosen row's own name reads over whatever is playing, and the
                 brackets, being at the corners, clear the words entirely.

                 phx-update="ignore" so a re-render never strips the src the hook
                 set; the id carries the selection so a different relationship
                 gets a clean element rather than a patched one. --%>
            <div
              id={"stage-#{@selected}"}
              phx-update="ignore"
              class="stage pointer-events-none absolute top-[34%] left-0 z-0 flex h-16 w-[32rem] -translate-y-8 items-center overflow-hidden bg-primary-600/15 px-[1.95rem] dark:bg-primary-500/20"
            >
              <video
                class="stage-video absolute inset-0 h-full w-full object-cover"
                playsinline
                preload="none"
              >
              </video>
              <div class="stage-fill absolute inset-0"></div>
              <span class="focus-empty text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-primary-600 opacity-0 transition-opacity duration-200 dark:text-primary-500">
                --
              </span>
              <audio class="stage-audio" preload="none"></audio>
            </div>

            <%!-- THE LIST. Presence names, one per row, scrolling through the
                 band. Lead and trail are set by the hook, not here, so the list
                 rests unselected and every row can still reach the band. --%>
            <div
              id={"presence-scroll-#{@selected}"}
              phx-hook="PresencePanel"
              phx-update="ignore"
              class="presence-scroll relative z-10 h-full overflow-y-auto overscroll-contain"
            >
              <ul class="pt-[calc(34vh+4rem)] pb-[30vh]">
                <li
                  :for={presence <- @current.presences}
                  data-kind={presence.kind}
                  data-media={presence.media}
                  class="presence-item flex h-16 cursor-pointer items-center justify-between whitespace-nowrap px-[1.95rem] text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-light-900 dark:text-dark-100"
                >
                  <span>{presence.by}</span>
                  <%!-- WHEN it was left, on every row — the one fact a presence
                       carries besides who and what. Held to its own muted colour
                       so it never competes with the name, even when the row goes
                       terracotta in the band. --%>
                  <span class="presence-when ml-4 text-sm text-light-400 dark:text-dark-500">
                    {presence.when}
                  </span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

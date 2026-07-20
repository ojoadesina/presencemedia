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
  # State asks whether the person is THERE; frame asks what is coming THROUGH.
  # An absent user's frame drains to neutral rather than to a paler terracotta,
  # because terracotta is the colour of someone being there and a weak version
  # of it reads as a weak signal, not as nobody. Absence pairs with an empty
  # frame here for the obvious reason — you cannot be away and talking — but
  # nothing in the code enforces that, because a line can perfectly well carry
  # a recording of someone who has since gone.
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
      state: "present",
      frame: "face",
      media:
        "#{@commons}/0/01/WIKITONGUES-_Hermica_speaking_Bengape.webm/" <>
          "WIKITONGUES-_Hermica_speaking_Bengape.webm.360p.vp9.webm"
    },
    %{
      label: "GRANDMA",
      name: "ROSE",
      state: "present",
      frame: "voice",
      media: "#{@commons}/c/ca/Robin_Owain_en_Voice.ogg/Robin_Owain_en_Voice.ogg.mp3"
    },
    %{label: "COACH", name: "IBRAHIM", state: "present", frame: "empty", media: nil},
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
    %{label: "DOCTOR", name: "NGOZI", state: "present", frame: "empty", media: nil},
    %{label: "BARBER", name: "FEMI", state: "absent", frame: "empty", media: nil},
    %{label: "PASTOR", name: "EMMANUEL", state: "present", frame: "empty", media: nil},
    %{label: "TEAMMATE", name: "CHIDI", state: "absent", frame: "empty", media: nil}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: @users)}
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
      class="fixed inset-0 z-0 bg-background-50 font-mono dark:bg-background-950"
    >
      <%!-- the OLD design's measure, kept: the same mx-auto max-w-6xl px-4 the
           slot grid sat in, so this surface lines up with what came before. --%>
      <div class="mx-auto h-full w-full max-w-6xl px-4">
        <div class="pt-[max(1rem,calc(37vh-84px))]">
          <%!-- The heading is NOT held to the list's width — a line of prose
               needs the room to be a line of prose. It shares only the rows'
               inset, which is what puts every left edge on one line. --%>
          <div class="max-w-2xl px-[1.95rem]">
            <p class="text-[clamp(var(--text-4xl),1rem+0.7vw,var(--text-6xl))] leading-none text-background-950 dark:text-background-50">
              19+
            </p>
            <p class="mt-2 text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.15em] text-background-600 dark:text-background-500">
              RELATIONSHIPS
            </p>
          </div>

          <div class="relative mt-5 w-[32rem]">
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
                  class="regions-item flex h-[4rem] cursor-pointer items-center whitespace-nowrap px-[1.95rem] text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-background-900 transition-colors duration-200 dark:text-background-100"
                >
                  <span>{user.label}</span>
                  <%!-- their own name, quiet beside the label: it arrives only
                       when the row is in the band, and never competes with it.
                       It keeps its own colour on purpose — the focused row turns
                       terracotta, and the name staying muted is what stops the
                       band reading as two labels shouting at once. --%>
                  <span class="regions-name ml-3 text-background-300 opacity-0 transition-opacity duration-200 dark:text-background-700">
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
            <div class="pointer-events-none absolute left-0 top-[34%] flex w-[calc(min(100vw,72rem)-2rem)] -translate-y-1/2 items-center">
              <div class="focus-box relative flex h-[3.5rem] w-[32rem] shrink-0 items-center bg-primary-600/15 px-[1.95rem] dark:bg-primary-500/20">
                <span class="focus-empty text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-primary-600 opacity-0 transition-opacity duration-200 dark:text-primary-500">
                  --
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
              <div
                id="frame"
                data-mode="empty"
                data-state="present"
                role="button"
                tabindex="0"
                aria-label="Expand frame"
                class="frame group pointer-events-auto relative ml-auto flex h-[3.8rem] w-[3.8rem] shrink-0 cursor-pointer items-center justify-center p-2 opacity-0 transition-[opacity,width,height,padding] duration-300 data-expanded:h-[18rem] data-expanded:w-[18rem] data-expanded:p-4"
              >
                <%!-- THE SCREEN is inset from the frame, so the brackets bracket
                     the picture instead of cropping it, and it is square on
                     every corner — a screen has corners, and rounding them
                     would turn it into a widget. --%>
                <div class="frame-screen relative h-full w-full overflow-hidden bg-primary-600/30 dark:bg-primary-500/35">
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
                    class="frame-restart absolute inset-0 hidden items-center justify-center bg-background-950/35 text-background-50 transition-colors hover:bg-background-950/50 dark:bg-background-950/50 dark:hover:bg-background-950/65"
                    aria-label="Play again"
                  >
                    <.icon name="hero-arrow-path" class="size-4 group-data-expanded:size-10" />
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
    </div>
    """
  end
end

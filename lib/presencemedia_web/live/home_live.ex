defmodule PresencemediaWeb.HomeLive do
  @moduledoc """
  The presence app's home.

  A scroll of the relationships you hold, with a fixed band a third of the way
  down that IS the selection: rows pass THROUGH it and whichever lands there is
  chosen. The band shows your name for them with their own name beside it,
  faded, and a live dot in the box at the far edge.

  The rows are FIXTURE DATA. This app has no database at all yet — it does not
  even depend on Ecto — so nothing here is loaded, only rendered. That is
  deliberate: the surface is being designed before the spine is built.
  """
  use PresencemediaWeb, :live_view

  # Each is a label YOU gave them plus the name they came with. The label leads
  # because it is how you actually think of them; the name follows, faded, and
  # only once the row is in the band — see the focus rules in app.css.
  @relationships [
    %{label: "MUM", name: "SARAH"},
    %{label: "DAD", name: "MICHAEL"},
    %{label: "BIG BROTHER", name: "DANIEL OLUWASEUN"},
    %{label: "BROTHER", name: "JOSEPH"},
    %{label: "SISTER", name: "AMAKA"},
    %{label: "GRANDMA", name: "ROSE"},
    %{label: "COACH", name: "IBRAHIM"},
    %{label: "BEST FRIEND", name: "TUNDE ADEBAYO"},
    %{label: "NEIGHBOUR", name: "ELENA"},
    %{label: "COUSIN", name: "KEMI"},
    %{label: "UNCLE", name: "PETER"},
    %{label: "AUNT", name: "BLESSING"},
    %{label: "MENTOR", name: "ADEOLA"},
    %{label: "ROOMMATE", name: "LUCAS"},
    %{label: "BOSS", name: "HANNAH"},
    %{label: "DOCTOR", name: "NGOZI"},
    %{label: "BARBER", name: "FEMI"},
    %{label: "PASTOR", name: "EMMANUEL"},
    %{label: "TEAMMATE", name: "CHIDI"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, relationships: @relationships)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- ── THE RELATIONSHIP LIST ──────────────────────────────────────────────
         The reference overlay, MIRRORED: list left, dashed line running right,
         marker at its end. No globe, no background grid.

         A fixed band a third of the way down the list IS the selection: rows
         scroll THROUGH it and whichever lands there is chosen, snapping itself
         to the centre. Band, line and marker are ONE flex row, so the three
         cannot fall out of line. TYPE is responsive where the geometry is
         fixed — one clamp ramp shared by the rows and the band's placeholder,
         so those two can never disagree. Styles Tailwind cannot express — the
         corner brackets, the two fade masks, the state rules — live under
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
                <li
                  :for={rel <- @relationships}
                  class="regions-item flex h-[4rem] cursor-pointer items-center whitespace-nowrap px-[1.95rem] text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-background-900 transition-colors duration-200 dark:text-background-100"
                >
                  <span>{rel.label}</span>
                  <%!-- their own name, quiet beside the label: it arrives only
                       when the row is in the band, and never competes with it.
                       It keeps its own colour on purpose — the focused row turns
                       terracotta, and the name staying muted is what stops the
                       band reading as two labels shouting at once. --%>
                  <span class="regions-name ml-3 text-background-300 opacity-0 transition-opacity duration-200 dark:text-background-700">
                    {rel.name}
                  </span>
                </li>
              </ul>
            </div>

            <%!-- band · box — two things in one row, so they cannot fall out
                 of line with each other. The row spans the container's whole
                 measure, and the box takes ml-auto to hold the far edge itself:
                 the line used to be the flex-1 that pushed it there, and the
                 line is not coming back.

                 THE MARKER lives inside the box: two circles, one solid and one
                 pinging out from under it. Both box and dot appear only on a
                 settled selection. --%>
            <div class="pointer-events-none absolute left-0 top-[34%] flex w-[calc(min(100vw,72rem)-2rem)] -translate-y-1/2 items-center">
              <div class="focus-box relative flex h-[3.5rem] w-[32rem] shrink-0 items-center bg-primary-600/15 px-[1.95rem] dark:bg-primary-500/20">
                <span class="focus-empty text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em] text-primary-600 opacity-0 transition-opacity duration-200 dark:text-primary-500">
                  --
                </span>
              </div>
              <%!-- THE FRAME, then the marker. One right-aligned group, so the
                   gap between the two is fixed and neither can drift.

                   The frame is the marker's box DUPLICATED and then emptied: the
                   same 3.8rem square on the same horizontal line, but flat and
                   faded instead of bracketed. It stands where a person's live
                   frame will be rendered, and it pulsates rather than sitting
                   still because that is the difference between a slot and a
                   feed. Brackets are the language of TARGETING, which is the
                   marker's job — the frame borrows the box's geometry and none
                   of its furniture. --%>
              <div class="ml-auto flex items-center gap-4">
                <div class="frame h-[3.8rem] w-[3.8rem] shrink-0 bg-primary-600/15 dark:bg-primary-500/20">
                </div>

                <div class="focus-marker relative flex h-[3.8rem] w-[3.8rem] shrink-0 items-center justify-center opacity-0 transition-opacity duration-200">
                  <span class="relative flex size-3.5">
                    <span class="presence-ping absolute inline-flex h-full w-full rounded-full">
                    </span>
                    <span class="presence-dot relative inline-flex size-3.5 rounded-full bg-secondary-600 dark:bg-secondary-300">
                    </span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

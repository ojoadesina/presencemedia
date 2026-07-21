defmodule PresencemediaWeb.PresenceLive do
  @moduledoc """
  THE PRESENCE FEED, built on the relationship list's mechanism rather than
  beside it.

  Same box a third of the way down, same settle, same snap, same brackets. What
  changes is what a row says and what the box does with it.

  ## A row is a sentence

  Where a relationship row is the name you gave someone with their real name
  faded beside it, a presence row is the creator, then what kind of presence it
  is, then the words that came with it — one continuous line at one size,
  separated only by ink. Pure text names no kind: the words are already the
  whole of it.

  It is at least as tall as a relationship row and never taller than two lines,
  so a long note does not turn a list into a wall.

  ## The chosen one rises

  The box sits at the TOP of this list rather than a third of the way down. A
  presence is chosen in order to be watched, and what is being watched belongs
  directly beneath the screen watching it — so the selection is always the first
  row, with the rest queued below it. The relationship list keeps its third:
  there you are looking along a row of people, and a person at the top of the
  screen would have no one either side of them.

  ## The screen belongs to the selection

  Under the band sits a screen, and its HEIGHT is the kind. A face gets the full
  recorder measure and plays there. A voice gets a strip no thicker than a
  progress bar, because there is nothing to look at and a tall black rectangle
  would be pretending otherwise. Text gets nothing at all — no screen, no
  height, no space held for something that will never arrive.

  That is the honest version of "the screen changes based on selected item
  type": not one box showing three things, but a box that is only as big as it
  has cause to be.
  """
  use PresencemediaWeb, :live_view

  alias Presencemedia.Fixtures

  @impl true
  def mount(_params, _session, socket) do
    presences = Fixtures.presences()

    {:ok,
     socket
     |> assign(presences: presences, captured: 0)
     |> put_current()}
  end

  # Resolved once and stored, rather than looked up in the template: calling a
  # function with `assigns` in HEEx switches change tracking off for that block.
  defp put_current(socket) do
    assign(
      socket,
      :current,
      socket.assigns.captured && Enum.at(socket.assigns.presences, socket.assigns.captured)
    )
  end

  @impl true
  def handle_event("capture_presence", %{"index" => index}, socket) do
    {:noreply, socket |> assign(captured: index) |> put_current()}
  end

  def handle_event("release_presence", _params, socket) do
    {:noreply, socket |> assign(captured: nil) |> put_current()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="presence-page" class="fixed inset-0 z-0 bg-light-50 font-mono dark:bg-dark-950">
      <div class="mx-auto h-full w-full max-w-6xl px-4">
        <%!-- The list takes whatever is left. Pulling the screen to the top of
             the device only moved the empty page to the bottom; given the rest
             of the height it becomes rows instead. --%>
        <div class="flex h-full flex-col pt-4">
          <%!-- THE SCREEN IS THE TOP OF THE PAGE, and it keeps its room whether
               or not there is a face in it. Sizing it to its contents was
               honest and wrong: scrolling a list is one continuous act, and a
               page that rearranges itself under every third row turns that act
               into a series of interruptions. Held open, the list below never
               moves and the only thing that changes is what is in the screen —
               which is the only thing that should.

               A voice therefore sits in the MIDDLE of that room rather than at
               the top of it. Centred, the hairline is a thing placed in a space;
               pinned high, it would read as a small thing in a big empty box.

               Nothing is titled: a page with one thing on it does not need to
               announce which thing. --%>
          <.presence_screen id={"screen-#{@captured}"} presence={@current} />

          <div id="stream-slot" class="relative mt-8 min-h-0 w-[32rem] flex-1">
            <div
              id="stream-scroll"
              phx-hook="Stream"
              phx-update="ignore"
              data-anchor="top"
              class="stream-scroll h-full overflow-y-auto overscroll-contain"
            >
              <%!-- Gapped, so each presence is its own object rather than one
                   ruled sheet — and gapped generously, because a filled card
                   needs more room around it than an outlined one did to stop
                   the column reading as a single striped block. --%>
              <ul class="space-y-5">
                <%!-- THE ITEM IS THE BOX. A bordered rectangle with the sentence
                     inside it — creator, then kind, then the words — at one size
                     throughout, separated only by ink. No highlight behind the
                     text: the box already does that job, and a second one would
                     be saying it twice.

                     Every card is the same height, which is what lets the band
                     fit one exactly. Two lines is the most a note gets; a
                     shorter one simply leaves room. --%>
                <%!-- No border anywhere. The wash is the edge — the recorder
                     filled its layers rather than outlining them, and a fill
                     that stops is a stronger boundary than a line drawn round
                     nothing. The hue comes from the creator's name, so a person
                     keeps their colour wherever they turn up. --%>
                <li :for={presence <- @presences} class="stream-item">
                  <div
                    class="presence-row h-27 w-[32rem] p-[1.95rem]"
                    style={"--wash-h: #{presence.hue}"}
                  >
                    <p class="stream-line text-md tracking-[0.14em]">
                      <span class="stream-name font-semibold">{presence.by}</span>
                      <%!-- Lower case, because the name is the only thing in the
                           sentence entitled to raise its voice. --%>
                      <span :if={presence.kind != "text"} class="text-light-500 dark:text-dark-500">
                        {presence.kind}
                      </span>
                      <%!-- GREY, and dark enough to actually read. The content is
                           the reason the row exists; it was set two steps paler
                           than the label announcing it, which had the sentence
                           fading out exactly where it started to matter. Grey
                           rather than a step up the warm ramp, so it reads as
                           body text and not as a quieter kind of heading. --%>
                      <span :if={presence.note} class="text-neutral-800 dark:text-neutral-200">
                        {presence.note}
                      </span>
                    </p>
                  </div>
                </li>
              </ul>
            </div>

            <%!-- THE BAND IS BRACKETS AND NOTHING ELSE now. The chosen row keeps
                 its own colour — a wash laid over it would be two washes on one
                 card — so all the band has to do is mark which card that is. --%>
            <div class="band pointer-events-none absolute top-0 left-0 h-27 w-[32rem]"></div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

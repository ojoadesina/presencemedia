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
        <div class="pt-[max(1rem,calc(37vh-84px))]">
          <div class="max-w-2xl px-[1.95rem]">
            <p class="text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.15em] text-light-500 dark:text-dark-500">
              PRESENCE
            </p>
          </div>

          <%!-- THE SCREEN SITS BETWEEN THE HEADING AND THE LIST, at exactly the
               size of what it is showing and no larger.

               THE SLOT ALWAYS EXISTS, and carries an id, even for text where it
               holds nothing and stands zero pixels tall. Not for layout — it
               reserves no space — but because a sibling that comes and goes
               unkeyed makes the patch match the wrong children and re-slot the
               list below it. Re-inserting a scroller resets its scrollTop, and
               the list would snap back to its first row every time a text
               presence came round. Same node, moved, scrolled home. --%>
          <div id="screen-slot" class="w-[32rem]">
            <div
              :if={@current && @current.kind != "text"}
              id={"screen-#{@captured}"}
              phx-hook="Screen"
              phx-update="ignore"
              data-media={@current.media}
              data-kind={@current.kind}
              class={[
                "screen relative mt-6 w-[32rem] overflow-hidden",
                @current.kind == "face" && "h-54 bg-black",
                @current.kind == "voice" && "h-[3px] bg-secondary-500/30"
              ]}
            >
              <video
                :if={@current.kind == "face"}
                class="screen-video absolute inset-0 h-full w-full object-cover"
                playsinline
                preload="none"
              >
              </video>

              <%!-- THE COUNT, where the old recorder kept it: bottom left, over
                   the picture, counting up. It is the one thing the frame
                   cannot say for itself — how far into someone you are. --%>
              <div :if={@current.kind == "face"} class="absolute bottom-4 left-8">
                <span class="screen-time text-sm text-dark-400">0:00</span>
              </div>

              <%!-- At a hairline there is no room for a count and none is
                   needed: the row already said VOICE, so the only thing left to
                   say is how far along. --%>
              <div
                :if={@current.kind == "voice"}
                class="screen-fill h-full bg-secondary-500"
                style="width: var(--played, 0%)"
              >
              </div>
            </div>
          </div>

          <div id="stream-slot" class="relative mt-8 w-[32rem]">
            <div
              id="stream-scroll"
              phx-hook="Stream"
              phx-update="ignore"
              data-anchor="top"
              class="stream-scroll h-[46vh] overflow-y-auto overscroll-contain"
            >
              <%!-- Gapped, so each presence is its own object rather than one
                   ruled sheet. The gap is smaller than the border is quiet. --%>
              <ul class="space-y-3">
                <%!-- THE ITEM IS THE BOX. A bordered rectangle with the sentence
                     inside it — creator, then kind, then the words — at one size
                     throughout, separated only by ink. No highlight behind the
                     text: the box already does that job, and a second one would
                     be saying it twice.

                     Every card is the same height, which is what lets the band
                     fit one exactly. Two lines is the most a note gets; a
                     shorter one simply leaves room. --%>
                <li :for={presence <- @presences} class="stream-item">
                  <div class="presence-row h-27 w-[32rem] border border-light-200 p-[1.95rem] dark:border-dark-800">
                    <p class="stream-line text-md tracking-[0.14em]">
                      <span class={[
                        presence.heard && "text-light-900 dark:text-dark-100",
                        !presence.heard && "text-primary-600 dark:text-primary-500"
                      ]}>
                        {presence.by}
                      </span>
                      <span :if={presence.kind != "text"} class="text-light-500 dark:text-dark-500">
                        {String.upcase(presence.kind)}
                      </span>
                      <span :if={presence.note} class="text-light-300 dark:text-dark-700">
                        {presence.note}
                      </span>
                    </p>
                  </div>
                </li>
              </ul>
            </div>

            <%!-- THE BAND, brackets only. The cards carry their own edges now,
                 so a filled band over one would be a second rectangle on top of
                 a rectangle. Aiming is all that is left for it to do. --%>
            <div class="band pointer-events-none absolute top-0 left-0 h-27 w-[32rem]"></div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

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

          <div class="relative mt-5 w-[32rem]">
            <div
              id="stream-scroll"
              phx-hook="Stream"
              phx-update="ignore"
              class="stream-scroll h-[50vh] overflow-y-auto overscroll-contain"
            >
              <ul>
                <%!-- ONE SENTENCE, THREE INKS. Creator, then the kind, then the
                     words — the relationship row's own two-weight trick with a
                     third weight in the middle, so the two lists are the same
                     idea rather than two designs sharing a screen. --%>
                <li
                  :for={presence <- @presences}
                  class="stream-item flex min-h-16 cursor-pointer items-center px-[1.95rem]"
                >
                  <p class="stream-line text-[clamp(var(--text-xl),0.85rem+0.38vw,var(--text-4xl))] tracking-[0.14em]">
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
                </li>
              </ul>
            </div>

            <%!-- THE BAND, and beneath it the screen. Both are pinned to the
                 same 34% the relationship list uses; the band never moves and
                 the screen grows downward from it, so a face arriving does not
                 shove the chosen line off its own place. --%>
            <div class="pointer-events-none absolute top-[34%] left-0 w-[32rem] -translate-y-1/2">
              <div class="focus-box relative flex h-16 items-center bg-primary-600/15 px-[1.95rem] dark:bg-primary-500/20">
              </div>

              <%!-- THE SCREEN IS AS BIG AS IT HAS CAUSE TO BE. Face takes the
                   recorder's own measure; voice takes a strip, because there is
                   nothing to look at and a tall black rectangle would pretend
                   otherwise; text takes nothing at all. --%>
              <div
                :if={@current && @current.kind != "text"}
                id={"screen-#{@captured}"}
                phx-hook="Screen"
                phx-update="ignore"
                data-media={@current.media}
                data-kind={@current.kind}
                class={[
                  "screen relative w-[32rem] overflow-hidden",
                  @current.kind == "face" && "h-54 bg-black",
                  @current.kind == "voice" && "h-1.5 bg-secondary-500/30"
                ]}
              >
                <video
                  :if={@current.kind == "face"}
                  class="screen-video absolute inset-0 h-full w-full object-cover"
                  playsinline
                  preload="none"
                >
                </video>

                <%!-- A strip that fills. At this thickness there is no room for
                     a status line, and none is needed: the row already said
                     VOICE, so the only thing left to say is how far along. --%>
                <div
                  :if={@current.kind == "voice"}
                  class="screen-fill h-full bg-secondary-500"
                  style="width: var(--played, 0%)"
                >
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

defmodule PresencemediaWeb.PresenceLive do
  @moduledoc """
  A BLANK CANVAS, on purpose.

  What lived here was a feed of presences you scrolled — the content model. The
  app's direction changed under it: people are the content now, not the things
  they leave behind, and you meet them by looking rather than by reading a
  stream. So the old feed came out whole, and the page is empty again, holding
  only its header while we work out what discovery here actually is.

  Nothing is deleted that will be missed — the mechanism, the screen and the
  wash rows all still live on the home surface. This is the drawing board, wiped.
  """
  use PresencemediaWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

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
        </div>
      </div>
    </div>
    """
  end
end

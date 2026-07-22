defmodule PresencemediaWeb.HomeLiveTest do
  use PresencemediaWeb.ConnCase
  import Phoenix.LiveViewTest

  test "the surface renders its heading and every user", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/")

    assert html =~ "SO YOU DON&#39;T DO LIFE ALONE"
    # the label leads, their own name follows it
    assert html =~ "MUM"
    assert html =~ "SARAH"
    # one row per user, and a band for them to pass through
    assert html |> String.split(~s(class="scopes-item)) |> length() == 20
    assert html =~ "focus-box"
  end

  test "every user carries the frame its row will hand to the screen", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/")

    # All three frame modes and all three states must actually appear, or the
    # fixtures have drifted into exercising only some of what the frame renders.
    for mode <- ~w(empty voice face), do: assert(html =~ ~s(data-frame="#{mode}"))
    for state <- ~w(absent present live), do: assert(html =~ ~s(data-state="#{state}"))

    # The case that justifies `live` existing at all: an open line with nothing
    # coming through it. Without one, nothing on screen would ever pulse on
    # state alone.
    assert html =~ ~r/data-state="live" data-frame="empty"/
  end

  test "picking an item lifts it into a header and opens its panel", %{conn: conn} do
    {:ok, live, html} = live(conn, ~p"/")

    # Nothing is picked until something is selected, and the band says nothing.
    refute html =~ "id=\"presence-panel\""
    refute has_element?(live, "#bar.is-picked")

    # Clicking the band with no selection must be inert — there is no item to
    # pick up, and inventing one would be worse than doing nothing.
    live |> element(".focus-box") |> render_click()
    refute has_element?(live, "#bar.is-picked")

    # The hook is what decides WHO; here we stand in for it.
    render_hook(live, "select", %{"index" => 1})
    refute has_element?(live, "#bar.is-picked")

    opened = live |> element(".focus-box") |> render_click()
    assert has_element?(live, "#bar.is-picked")
    assert has_element?(live, "#scopes.is-open")
    assert has_element?(live, "#presence-panel")
    # The bar now carries its own label, which is what lets it fly without
    # leaving its words behind in the list.
    assert opened =~ "DAD"
    assert opened =~ "MICHAEL"

    closed = live |> element(".focus-box") |> render_click()
    refute has_element?(live, "#bar.is-picked")
    refute has_element?(live, "#presence-panel")
    refute closed =~ "id=\"presence-panel\""
  end

  test "losing the selection closes the panel with it", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    render_hook(live, "select", %{"index" => 0})
    live |> element(".focus-box") |> render_click()
    assert has_element?(live, "#presence-panel")

    # Scrolling the band empty must not leave an open view of nobody.
    render_hook(live, "deselect", %{})
    refute has_element?(live, "#presence-panel")
    refute has_element?(live, "#bar.is-picked")
  end

  test "the scoped button flips the people list and back", %{conn: conn} do
    {:ok, live, html} = live(conn, ~p"/")

    assert html =~ "SCOPED"
    # Lit means the people list is what the scroller is showing.
    assert has_element?(live, ~s(button[phx-click="toggle_scope"][aria-pressed="true"]))

    toggled = live |> element(~s(button[phx-click="toggle_scope"])) |> render_click()
    assert toggled =~ "UNSCOPED"
    # A stranger only the unscoped world holds, so this proves the list swapped.
    assert toggled =~ "AMINA"

    back = live |> element(~s(button[phx-click="toggle_scope"])) |> render_click()
    # "SCOPED" is a substring of "UNSCOPED", so proving we came back means
    # proving the longer label is GONE, not that the shorter one is present.
    refute back =~ "UNSCOPED"
    assert back =~ "SCOPED"
  end

  test "location swaps the list for countries and a pick sets the button", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/")

    # Entering location swaps people out for a roll of the world; Finland is the
    # default the button already carried.
    opened = live |> element(~s(button[phx-click="to_location"])) |> render_click()
    assert has_element?(live, ~s(button[phx-click="to_location"][aria-pressed="true"]))
    assert opened =~ "Nigeria"

    # A country settles in the band, then the band is picked — no panel, just the
    # LOCATION button taking on the chosen place as its state.
    render_hook(live, "select", %{"index" => 1})
    picked = live |> element(".focus-box") |> render_click()
    refute has_element?(live, "#presence-panel")
    assert picked =~ "NIGERIA"

    # SCOPED brings the people back, on the scope we left.
    back = live |> element(~s(button[phx-click="toggle_scope"])) |> render_click()
    assert back =~ "MUM"
  end
end

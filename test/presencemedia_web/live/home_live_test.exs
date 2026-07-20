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
    assert html |> String.split(~s(class="regions-item)) |> length() == 20
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

  test "scope toggles between its two labels and back", %{conn: conn} do
    {:ok, live, html} = live(conn, ~p"/")

    assert html =~ "SCOPED"
    assert has_element?(live, ~s(.scope-box[aria-pressed="true"]))

    toggled = live |> element(".scope-box") |> render_click()
    assert toggled =~ "UNSCOPED"
    assert has_element?(live, ~s(.scope-box[aria-pressed="false"]))

    back = live |> element(".scope-box") |> render_click()
    # "SCOPED" is a substring of "UNSCOPED", so proving we came back means
    # proving the longer label is GONE, not that the shorter one is present.
    refute back =~ "UNSCOPED"
    assert back =~ "SCOPED"
    assert has_element?(live, ~s(.scope-box[aria-pressed="true"]))
  end
end

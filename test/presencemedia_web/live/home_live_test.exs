defmodule PresencemediaWeb.HomeLiveTest do
  use PresencemediaWeb.ConnCase
  import Phoenix.LiveViewTest

  test "the surface renders its heading and every relationship", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/")

    assert html =~ "RELATIONSHIPS"
    # the label leads, their own name follows it
    assert html =~ "MUM"
    assert html =~ "SARAH"
    # one row per relationship, and a band for them to pass through
    assert html |> String.split(~s(class="regions-item)) |> length() == 20
    assert html =~ "focus-box"
  end
end

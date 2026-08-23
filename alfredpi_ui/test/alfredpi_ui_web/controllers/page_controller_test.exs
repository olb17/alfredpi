defmodule AlfredpiUiWeb.PageControllerTest do
  use AlfredpiUiWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "a.menu-active", "Tests")
  end
end

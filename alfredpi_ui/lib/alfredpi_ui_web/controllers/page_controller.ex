defmodule AlfredpiUiWeb.PageController do
  use AlfredpiUiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

defmodule AlfredpiUiWeb.SurpriseComponent do
  use AlfredpiUiWeb, :live_component
  require Logger

  alias Alfredpi.Surprise

  @impl true
  def update(_assigns, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("play", _params, socket) do
    :ok = Surprise.play()
    {:reply, %{reply: :ok}, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.button phx-target={@myself} phx-click="play" class="ml-2">{gettext("Play now")}</.button>
    </div>
    """
  end
end

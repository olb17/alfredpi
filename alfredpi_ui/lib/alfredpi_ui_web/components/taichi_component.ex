defmodule AlfredpiUiWeb.TaichiComponent do
  use AlfredpiUiWeb, :live_component
  require Logger

  alias Alfredpi.Taichi

  @impl true
  def update(_assigns, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("play", _params, socket) do
    :ok = Taichi.play()
    {:reply, %{reply: :ok}, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.button phx-target={@myself} phx-click="play" class="ml-2">Play now</.button>
    </div>
    """
  end
end

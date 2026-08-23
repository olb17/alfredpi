defmodule AlfredpiUiWeb.GeneralLive do
  use AlfredpiUiWeb, :live_view
  require Logger

  alias Alfredpi.RabbitManager
  alias Alfredpi.RabbitManager.Parameters

  @impl true
  def mount(_params, _session, socket) do
    parameters = RabbitManager.get_parameters()

    changeset =
      RabbitManager.Parameters.changeset(%{}, parameters)

    socket =
      socket
      |> assign(form: to_form(changeset))
      |> assign(main_title: "Configuration d'Alfredpi")
      |> assign(page_title: "Param")
      |> assign(selected_menu: :general)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validation", %{"parameters" => params}, socket) do
    form =
      params
      |> Parameters.changeset()
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"parameters" => params}, socket) do
    changeset =
      params
      |> Parameters.changeset()
      |> Map.put(:action, :insert)

    socket =
      if changeset.valid? do
        case RabbitManager.set_parameters(changeset) do
          :ok ->
            socket
            |> put_flash(:info, "Parameters saved.")
            |> redirect(to: ~p"/config")

          error ->
            put_flash(socket, :error, "Parameters not saved #{inspect(error)}")
        end
      else
        socket
      end

    {:noreply, assign(socket, form_move: to_form(changeset))}
  end

  def handle_event("reboot", _params, socket) do
    :ok = RabbitManager.reboot()
    {:noreply, socket}
  end

  def handle_event("halt", _params, socket) do
    :ok = RabbitManager.halt()
    {:noreply, socket}
  end

  def handle_event("factory_reset", _params, socket) do
    :ok = RabbitManager.factory_reset()
    {:noreply, socket}
  end
end

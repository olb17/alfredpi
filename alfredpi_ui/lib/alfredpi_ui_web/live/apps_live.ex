defmodule AlfredpiUiWeb.AppsLive do
  use AlfredpiUiWeb, :live_view
  require Logger

  @app_components %{
    Alfredpi.Surprise => AlfredpiUiWeb.SurpriseComponent,
    Alfredpi.Taichi => AlfredpiUiWeb.TaichiComponent
  }

  @impl true
  def mount(_params, _session, socket) do
    applications =
      Alfredpi.RabbitManager.get_application()
      |> Enum.map(fn app ->
        {app,
         %{
           id: app,
           is_started: Alfredpi.RabbitManager.is_started?(app),
           component: Map.get(@app_components, app)
         }}
      end)
      |> Map.new()

    Phoenix.PubSub.subscribe(RabbitManager.PubSub, "alfredpi")

    socket =
      socket
      |> assign(main_title: "Applications")
      |> assign(page_title: "Apps")
      |> assign(selected_menu: :apps)
      |> assign(applications: applications)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:put_flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  def handle_info({:application, application, :start}, socket) do
    applications = socket.assigns.applications

    applications =
      put_in(applications[application][:is_started], true)

    {:noreply, assign(socket, applications: applications)}
  end

  def handle_info({:application, application, :stop}, socket) do
    applications = socket.assigns.applications

    applications =
      put_in(applications[application][:is_started], false)

    {:noreply, assign(socket, applications: applications)}
  end

  def handle_info(event, socket) do
    Logger.debug("Uncaught event", event)
    {:noreply, socket}
  end
end

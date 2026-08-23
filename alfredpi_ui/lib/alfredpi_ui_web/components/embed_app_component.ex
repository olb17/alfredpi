defmodule AlfredpiUiWeb.EmbedAppComponent do
  use AlfredpiUiWeb, :live_component
  require Logger

  alias Alfredpi.RabbitManager

  @impl true
  def update(assigns, socket) do
    app_state =
      if RabbitManager.is_started?(assigns.application) do
        "on"
      else
        nil
      end

    {:ok, changeset} = RabbitManager.get_application_changeset(assigns.application)

    config_form =
      changeset
      |> to_form(as: form_name(assigns.application))

    socket =
      socket
      |> assign(title: RabbitManager.application_name(assigns.application))
      |> assign(application: assigns.application)
      |> assign(inner_block: assigns.inner_block)
      |> assign(form_config: config_form)
      |> assign(form: to_form(%{"app_state" => app_state}))
      |> assign(modal_opened: false)

    {:ok, socket}
  end

  @impl true
  def handle_event("update-state", %{"app_state" => "on"}, socket) do
    Logger.debug("starting application #{socket.assigns.application}")
    RabbitManager.start_application(socket.assigns.application)
    {:reply, %{reply: :ok}, socket}
  end

  def handle_event("update-state", _params, socket) do
    Logger.debug("Stopping application #{socket.assigns.application}")
    RabbitManager.stop_application(socket.assigns.application)
    {:reply, %{reply: :ok}, socket}
  end

  def handle_event("modal", %{"action" => action}, socket) when action in ["open", "close"] do
    modal_opened = action == "open"
    socket = assign(socket, modal_opened: modal_opened)
    {:noreply, socket}
  end

  def handle_event("change-config", params, socket) do
    changeset =
      RabbitManager.set_application_changeset(
        socket.assigns.application,
        params[form_name(socket.assigns.application)]
      )

    form = changeset |> to_form(as: form_name(socket.assigns.application))

    socket = assign(socket, form_config: form)

    {:noreply, socket}
  end

  def handle_event("update-config", params, socket) do
    Logger.debug("Updating config #{inspect(params)}")

    changeset =
      RabbitManager.set_application_changeset(
        socket.assigns.application,
        params[form_name(socket.assigns.application)]
      )

    form = changeset |> to_form(as: form_name(socket.assigns.application))

    socket = assign(socket, form_config: form)

    socket =
      if changeset.valid? do
        send(self(), {:put_flash, :info, "Configuration sauvegardée"})

        socket
        |> assign(modal_opened: false)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="flex-1 bg-base-100 p-6 border border-gray-200 rounded-lg shadow">
      <.simple_form for={@form} class="mt-2">
        <div class="flex justify-items-start items-bottom place-content-between">
          <h3 class="mb-2 text-2xl font-bold tracking-tight text-base-content">
            {@title}
          </h3>
          <div class="flex-1 ml-2">
            <svg
              phx-click="modal"
              phx-value-action="open"
              phx-target={@myself}
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-6 h-6 cursor-pointer"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"
              />
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
              />
            </svg>
          </div>
          <div phx-feedback-for={@title <> "_app_state"}>
            <label class="switch">
              <input
                type="checkbox"
                class="checkbox"
                id={@title <> "_app_state"}
                name="app_state"
                checked={@form.source["app_state"] == "on"}
                phx-change="update-state"
                phx-target={@myself}
              />
              <span class="slider round"></span>
            </label>
          </div>
        </div>
        {render_slot(@inner_block)}
      </.simple_form>

      <input type="checkbox" id={modal_id(@title)} class="modal-toggle" checked={@modal_opened} />
      <div class="modal" role="dialog">
        <div class="modal-box">
          <h2 class="font-bold text-lg">{gettext("Configuration of %{title}", title: @title)}</h2>
          <p class="py-4">
            {gettext(
              "You can configure the application here. Changes will be applied after restarting the application."
            )}
          </p>
          <.simple_form
            method="dialog"
            for={@form_config}
            phx-target={@myself}
            phx-submit="update-config"
            phx-change="change-config"
          >
            <div :for={k <- find_fields(@form_config)}>
              <.input field={@form_config[k]} label={k} />
            </div>
            <.input field={@form_config[:autostart]} type="checkbox" label={gettext("Auto start")} />
            <:actions>
              <.button type="submit">{gettext("Save")}</.button>
            </:actions>
          </.simple_form>
          <form method="dialog">
            <button
              class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
              phx-click="modal"
              phx-value-action="close"
              phx-target={@myself}
            >
              ✕
            </button>
          </form>
        </div>
        <label
          class="modal-backdrop"
          for={modal_id(@title)}
          phx-click="modal"
          phx-value-action="close"
          phx-target={@myself}
        >
          Close
        </label>
      </div>
    </section>
    """
  end

  defp modal_id(title) do
    title <> "_modal"
  end

  defp find_fields(form) do
    form.data
    |> Map.keys()
    |> Enum.filter(&(&1 != :id and &1 != :__struct__ and &1 != :autostart))
  end

  defp form_name(application) do
    Atom.to_string(application)
  end
end

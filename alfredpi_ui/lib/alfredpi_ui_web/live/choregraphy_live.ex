defmodule AlfredpiUiWeb.ChoregraphyLive do
  use AlfredpiUiWeb, :live_view
  require Logger

  alias Alfredpi.RabbitManager
  alias Alfredpi.ChoregraphyManager
  alias Alfredpi.ChoregraphyManager.Choregraphy

  @actions [
    "var Delay = 200",
    "sleep 1_000",
    "led_color ~3d34eb, Led0",
    "move_ear Right, -5",
    "set_ear Left, 12",
    "wait_ear",
    "play Url, Sound",
    "repeat 5 move_ear Left end",
    "exec move_ear Left, 5 and led_color ~123456, Led2 end"
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(actions: @actions)
      |> assign(main_title: "Paramétrage des chorégraphies")
      |> assign(page_title: "Choregraphy")
      |> assign(selected_menu: :choregraphy)
      |> assign(is_running: ChoregraphyManager.is_choregraphy_running())

    RabbitManager.subscribe_event()
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if socket.assigns.live_action == :edit do
      choregraphy = ChoregraphyManager.get_choregraphy_by_code(params["code"])

      form =
        %{}
        |> Choregraphy.changeset(choregraphy)
        |> Map.put(:action, :edit)
        |> to_form()

      socket =
        socket
        |> assign(form: form)
        |> assign(:choregraphies, ChoregraphyManager.list_choregraphy())
        |> assign(is_system_code: Choregraphy.is_system(choregraphy))

      {:noreply, socket}
    else
      changeset =
        Choregraphy.changeset(%{})

      socket =
        socket
        |> assign(form: to_form(changeset))
        |> assign(:choregraphies, ChoregraphyManager.list_choregraphy())
        |> assign(is_system_code: false)
        |> assign(is_running: ChoregraphyManager.is_choregraphy_running())

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"choregraphy" => params}, socket) do
    form =
      if socket.assigns.is_system_code do
        params
        |> Choregraphy.changeset_execute()
      else
        params
        |> Choregraphy.changeset()
      end
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"choregraphy" => params, "action" => "save"}, socket) do
    if socket.assigns.live_action == :edit do
      changeset =
        params
        |> Choregraphy.changeset()
        |> Map.put(:action, :edit)

      socket =
        if changeset.valid? do
          code = Ecto.Changeset.fetch_field!(changeset, :code)

          choregraphy =
            ChoregraphyManager.get_choregraphy_by_code(code)
            |> Map.put(:name, Ecto.Changeset.fetch_field!(changeset, :name))
            |> Map.put(:actions, Ecto.Changeset.fetch_field!(changeset, :actions))

          case ChoregraphyManager.update_choregraphy(choregraphy) do
            {:ok, _} ->
              put_flash(socket, :info, "Choregraphy saved.")
              |> push_patch(to: ~p"/choregraphy/#{choregraphy.code}")

            {:error, error} ->
              put_flash(socket, :error, "Cannot save Choregraphy : #{inspect(error)}.")
          end
        else
          socket
        end

      {:noreply, assign(socket, form_move: to_form(changeset))}
    else
      changeset =
        params
        |> Choregraphy.changeset()
        |> Map.put(:action, :insert)

      socket =
        if changeset.valid? do
          choregraphy =
            %Choregraphy{}
            |> Map.put(:code, Ecto.Changeset.fetch_field!(changeset, :code))
            |> Map.put(:name, Ecto.Changeset.fetch_field!(changeset, :name))
            |> Map.put(:actions, Ecto.Changeset.fetch_field!(changeset, :actions))

          case ChoregraphyManager.update_choregraphy(choregraphy) do
            {:ok, _} ->
              put_flash(socket, :info, "Choregraphy saved.")
              |> push_patch(to: ~p"/choregraphy/#{choregraphy.code}")

            {:error, error} ->
              put_flash(socket, :error, "Cannot save Choregraphy : #{inspect(error)}.")
          end
        else
          socket
        end

      {:noreply, assign(socket, form_move: to_form(changeset))}
    end
  end

  def handle_event("save", %{"choregraphy" => params, "action" => "execute"}, socket) do
    changeset =
      params
      |> Choregraphy.changeset_execute()
      |> Map.put(:action, :insert)

    socket =
      if changeset.valid? do
        actions =
          Ecto.Changeset.fetch_field!(changeset, :actions)

        case ChoregraphyManager.execute_choregraphy_actions(actions) do
          :ok ->
            put_flash(socket, :info, "Choregraphy executed.")

          %{error: error} ->
            put_flash(socket, :error, inspect(error))
        end
      else
        socket
      end

    {:noreply, assign(socket, form_move: to_form(changeset))}
  end

  def handle_event("save", %{"choregraphy" => params, "action" => "delete"}, socket) do
    changeset =
      params
      |> Choregraphy.changeset()
      |> Map.put(:action, :delete)

    socket =
      if changeset.valid? do
        with {:choregraphy, chor} when chor != nil <-
               {:choregraphy,
                ChoregraphyManager.get_choregraphy_by_code(
                  Ecto.Changeset.fetch_field!(changeset, :code)
                )},
             :ok <-
               ChoregraphyManager.delete_choregraphy(chor) do
          socket
          |> put_flash(:info, "Choregraphy deleted.")
          |> push_patch(to: ~p"/choregraphy")
        else
          {:choregraphy, nil} ->
            put_flash(socket, :error, "Unknown code")

          %{error: error} ->
            put_flash(socket, :error, inspect(error))
        end
      else
        socket
      end

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_info({:choregraphy, evt}, socket) do
    socket =
      case evt do
        {:running, _} -> assign(socket, :is_running, true)
        :stopped -> assign(socket, :is_running, false)
      end

    {:noreply, socket}
  end

  def handle_info({:choregraphy_error, error}, socket) do
    socket = put_flash(socket, :error, "Choregraphy error: #{inspect(error)}")
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end

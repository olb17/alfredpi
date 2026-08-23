defmodule AlfredpiUiWeb.HomeLive do
  use AlfredpiUiWeb, :live_view
  require Logger

  alias Alfredpi.RabbitManager

  @ear_options %{"Left" => :left, "Right" => :right}
  @led_options %{
    "All" => :all,
    "Led 0" => :led_0,
    "Led 1" => :led_1,
    "Led 2" => :led_2,
    "Led 3" => :led_3,
    "Led 4" => :led_4
  }
  @ear_options_values ["left", "right"]

  def ear_option_values(), do: @ear_options_values

  defmodule EarMove do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:ear, :string)
      field(:clicks, :integer)
    end

    def changeset(params) do
      %EarMove{}
      |> cast(params, [:ear, :clicks])
      |> validate_required([:ear, :clicks])
      |> validate_number(:clicks, greater_than: -40, less_than: 40)
      |> validate_inclusion(:ear, AlfredpiUiWeb.HomeLive.ear_option_values())
      |> AlfredpiUiWeb.HomeLive.ear_to_atom()
    end
  end

  defmodule EarPosition do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:ear, :string)
      field(:position, :integer)
    end

    def changeset(params) do
      %EarPosition{}
      |> cast(params, [:ear, :position])
      |> validate_required([:ear, :position])
      |> validate_number(:position, greater_than: -18, less_than: 18)
      |> validate_inclusion(:ear, AlfredpiUiWeb.HomeLive.ear_option_values())
      |> AlfredpiUiWeb.HomeLive.ear_to_atom()
    end
  end

  defmodule LedColor do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:led, :string)
      field(:color, :string)
    end

    def changeset(params) do
      %LedColor{}
      |> cast(params, [:led, :color])
      |> validate_required([:led, :color])
      |> validate_inclusion(:led, ["all", "led_0", "led_1", "led_2", "led_3", "led_4"])
      |> led_to_index()
    end

    def led_to_index(changeset) do
      led =
        changeset
        |> fetch_field!(:led)
        |> String.to_existing_atom()

      put_change(changeset, :led, led)
    end
  end

  def ear_to_atom(changeset) do
    ear = Ecto.Changeset.fetch_field!(changeset, :ear) |> decode_ear()
    Ecto.Changeset.put_change(changeset, :ear, ear)
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset_move =
      EarMove.changeset(%{"ear" => "left", "clicks" => 8})

    changeset_position =
      EarPosition.changeset(%{"ear" => "left", "position" => 3})

    changeset_color = LedColor.changeset(%{"led" => "all", "color" => "#FF0000"})

    socket =
      socket
      |> assign(form_move: to_form(changeset_move))
      |> assign(form_pos: to_form(changeset_position))
      |> assign(form_color: to_form(changeset_color))
      |> assign(options: @ear_options)
      |> assign(options_leds: @led_options)
      |> assign(position_left: "N/A")
      |> assign(position_right: "N/A")
      |> allow_upload(:sound_file, accept: ~w(.mp3), max_entries: 1)
      |> assign(sound_state: :pending)
      |> assign(main_title: "Tests des fonctions d'Alfredpi")
      |> assign(page_title: "Tests")
      |> assign(selected_menu: :tests)

    # States for sound 
    # :pending
    # :loading
    # {:loaded, file}
    # {:recording, file}

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("val-move", %{"ear_move" => params}, socket) do
    form =
      params
      |> EarMove.changeset()
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form_move: form)}
  end

  def handle_event("move", %{"ear_move" => params}, socket) do
    changeset =
      params
      |> EarMove.changeset()
      |> Map.put(:action, :insert)

    socket =
      if changeset.valid? do
        ear = Ecto.Changeset.fetch_field!(changeset, :ear)
        clicks = Ecto.Changeset.fetch_field!(changeset, :clicks)

        :ok = RabbitManager.ear_move(ear, clicks)

        put_flash(socket, :info, "Ear moved")
      else
        socket
      end

    {:noreply, assign(socket, form_move: to_form(changeset))}
  end

  def handle_event("val-sound", _params, socket) do
    {:noreply, assign(socket, sound_state: :loading)}
  end

  def handle_event("play-sound", _params, socket) do
    case socket.assigns.sound_state do
      {:loaded, file} ->
        Logger.debug("Playing uploaded sound #{file}")
        Task.start_link(fn -> RabbitManager.play_file(file) end)

      _ ->
        true
    end

    {:noreply, socket}
  end

  def handle_event("reset-sound", _params, socket) do
    Logger.debug("Reset sound file")

    socket =
      case socket.assigns.sound_state do
        :loading ->
          Enum.reduce(socket.assigns.uploads.sound_file.entries, socket, fn entry, socket ->
            cancel_upload(socket, :sound_file, entry.ref)
          end)

        {:recording, file} ->
          RabbitManager.stop_recording_file()
          File.rm!(file)
          socket

        {:loaded, file} ->
          File.rm!(file)
          socket
      end
      |> assign(sound_state: :pending)

    {:noreply, socket}
  end

  def handle_event("record-sound", _params, socket) do
    socket =
      case socket.assigns.sound_state do
        :pending ->
          {:ok, tmp_path} = Briefly.create(extname: ".wav")
          Logger.debug("Recording sound #{tmp_path}")

          :ok = RabbitManager.record_file(tmp_path)

          socket
          |> assign(sound_state: {:recording, tmp_path})

        {:recording, file} ->
          Logger.debug("Stopping recording sound")
          :ok = RabbitManager.stop_recording_file()

          socket
          |> assign(sound_state: {:loaded, file})

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("sound", _params, socket) do
    [file] =
      consume_uploaded_entries(socket, :sound_file, fn %{path: path}, _entry ->
        {:ok, tmp_path} = Briefly.create()
        File.cp!(path, tmp_path)
        {:ok, tmp_path}
      end)

    {:noreply, assign(socket, sound_state: {:loaded, file})}
  end

  def handle_event("val-pos", %{"ear_position" => params}, socket) do
    form =
      params
      |> EarPosition.changeset()
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form_pos: form)}
  end

  def handle_event("position", %{"ear_position" => params}, socket) do
    changeset =
      params
      |> EarPosition.changeset()
      |> Map.put(:action, :insert)

    socket =
      if changeset.valid? do
        ear = Ecto.Changeset.fetch_field!(changeset, :ear)
        position = Ecto.Changeset.fetch_field!(changeset, :position)

        :ok = RabbitManager.ear_position(ear, position)

        put_flash(socket, :info, "Ear Positioned")
      else
        socket
      end

    {:noreply, assign(socket, form_pos: to_form(changeset))}
  end

  def handle_event("get-pos", _params, socket) do
    [position_left, position_right] =
      [:left, :right]
      |> Enum.map(fn ear ->
        Task.async(fn ->
          {:ok, position} = RabbitManager.ear_get(ear)
          position
        end)
      end)
      |> Task.await_many(6_000 * 2)

    socket =
      socket
      |> assign(position_left: position_left)
      |> assign(position_right: position_right)

    {:noreply, socket}
  end

  def handle_event("val-color", %{"led_color" => params}, socket) do
    form =
      params
      |> LedColor.changeset()
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form_color: form)}
  end

  def handle_event("color", %{"led_color" => params}, socket) do
    changeset =
      LedColor.changeset(params)
      |> Map.put(:action, :insert)

    socket =
      if changeset.valid? do
        led = Ecto.Changeset.fetch_change!(changeset, :led)
        color = Ecto.Changeset.fetch_change!(changeset, :color)

        :ok = RabbitManager.leds_color(color, led)

        case led do
          :all ->
            put_flash(socket, :info, "Couleur enregistrée pour toutes les leds")

          index ->
            put_flash(socket, :info, "Couleur enregistrée pour la led #{index}")
        end
      else
        socket
      end

    {:noreply, assign(socket, form_color: to_form(changeset))}
  end

  defp decode_ear("left"), do: :left
  defp decode_ear("right"), do: :right
  defp decode_ear("both"), do: :both

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end

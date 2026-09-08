defmodule Alfredpi.RabbitManager do
  @moduledoc """
  Coordinates access to the rabbit's hardware and embedded applications.

  On a rabbit, the functions in the hardware API can be called directly from
  the Elixir shell opened over SSH. For example:

      Alfredpi.RabbitManager.ear_move(:left, 5)
      Alfredpi.RabbitManager.leds_color("#ff0000", :all)
      Alfredpi.RabbitManager.play_file("/path/to/sound.mp3")

  Use `h Alfredpi.RabbitManager.function_name` in IEx for help with a specific
  function. Ear selectors are `:left` and `:right`; LED selectors are `:led_0`
  through `:led_4`, or `:all`.
  """

  use GenServer
  require Logger

  alias Alfredpi.ChoregraphyManager

  @hw_timeout 30_000

  defmodule EmbedApplication do
    @callback application_name() :: binary()
    @callback child_spec(args :: [any()]) :: Supervisor.child_spec()
    @callback kill() :: any()
    @callback default_config() :: term()
    @callback changeset(map()) :: %Ecto.Changeset{}
  end

  defmodule Parameters do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:startup_choregraphy_code, :string, default: "SYSTEM_STARTUP_CHOREGRAPHY")
      field(:language, Ecto.Enum, values: [:fr_FR, :en_GB], default: :fr_FR)
    end

    def changeset(params, parameters \\ %Parameters{}) do
      parameters
      |> cast(params, [:startup_choregraphy_code, :language])
      |> validate_required([:startup_choregraphy_code, :language])
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  #
  # Parameters Management
  #

  def get_parameters() do
    GenServer.call(__MODULE__, :get_parameters)
  end

  def set_parameters(parameters) do
    GenServer.call(__MODULE__, {:set_parameters, parameters})
  end

  #
  # Application Management
  #

  def get_application() do
    GenServer.call(__MODULE__, :get_application)
  end

  def is_started?(application) do
    Process.whereis(application) != nil
  end

  def start_application(application) do
    GenServer.call(__MODULE__, {:start_application, application})
  end

  def stop_application(application) do
    Kernel.apply(application, :kill, [])
  end

  def application_name(application) do
    Kernel.apply(application, :application_name, [])
  end

  def get_application_config(application) do
    GenServer.call(__MODULE__, {:get_application_config, application})
  end

  def get_application_changeset(application) do
    GenServer.call(__MODULE__, {:get_application_changeset, application})
  end

  def set_application_changeset(application, changeset) do
    GenServer.call(__MODULE__, {:set_application_changeset, application, changeset})
  end

  #
  # Event management 
  #

  def publish_event(event),
    do: Phoenix.PubSub.broadcast(RabbitManager.PubSub, "alfredpi", event)

  def subscribe_event(),
    do: Phoenix.PubSub.subscribe(RabbitManager.PubSub, "alfredpi")

  #
  # Hardware link
  #

  def wifi_ready() do
    GenServer.call(__MODULE__, :wifi_ready)
  end

  def sound_ready() do
    GenServer.call(__MODULE__, :sound_ready)
  end

  def platform_ready() do
    GenServer.call(__MODULE__, :platform_ready)
  end

  @doc """
  Moves `ear` by a relative number of motor clicks.

  Pass `:left` or `:right` as the ear. A positive or negative `clicks` value
  selects the direction.

      Alfredpi.RabbitManager.ear_move(:left, 5)
  """
  def ear_move(ear, clicks) do
    GenServer.call(__MODULE__, {:ear_move, ear, clicks}, @hw_timeout)
  end

  @doc """
  Moves `ear` to an absolute position.

      Alfredpi.RabbitManager.ear_position(:right, 10)
  """
  def ear_position(ear, position) do
    GenServer.call(__MODULE__, {:ear_position, ear, position}, @hw_timeout)
  end

  @doc """
  Waits until the selected ear has stopped moving.

      Alfredpi.RabbitManager.ear_wait(:left)
  """
  def ear_wait(ear) do
    GenServer.call(__MODULE__, {:ear_wait, ear}, @hw_timeout)
  end

  @doc """
  Reads the current position of an ear.

  Returns `{:ok, position}` on success.

      Alfredpi.RabbitManager.ear_get(:left)
  """
  def ear_get(ear) do
    GenServer.call(__MODULE__, {:ear_get, ear}, @hw_timeout)
  end

  @doc """
  Sets one or all LEDs to a color.

  `color` is a hexadecimal RGB string such as `"#ff0000"`. The LED selector
  can be `:led_0` through `:led_4`; it defaults to `:all`.

      Alfredpi.RabbitManager.leds_color("#00ff00")
      Alfredpi.RabbitManager.leds_color("#0000ff", :led_2)
  """
  def leds_color(color, index \\ :all) do
    GenServer.call(__MODULE__, {:leds_color, color, index})
  end

  @doc """
  Downloads and plays the named audio resource relative to `root`.

      Alfredpi.RabbitManager.play_url("https://example.com/sounds/", "hello.mp3")
  """
  def play_url(root, name) do
    GenServer.call(__MODULE__, {:play_url, root, name}, @hw_timeout)
  end

  @doc """
  Plays an MP3 or WAV file from the rabbit's local filesystem.

      Alfredpi.RabbitManager.play_file("/data/hello.mp3")
  """
  def play_file(file) do
    GenServer.call(__MODULE__, {:play_file, file}, @hw_timeout)
  end

  @doc """
  Starts recording audio to a WAV file on the rabbit's local filesystem.

  Call `stop_recording_file/0` to finish the recording.

      Alfredpi.RabbitManager.record_file("/data/recording.wav")
  """
  def record_file(file) do
    GenServer.call(__MODULE__, {:record_file, file})
  end

  @doc """
  Stops the active audio recording.

      Alfredpi.RabbitManager.stop_recording_file()
  """
  def stop_recording_file() do
    GenServer.call(__MODULE__, :stop_recording_file)
  end

  @doc """
  Reboots the rabbit.

  The SSH session disconnects when this function succeeds.
  """
  def reboot() do
    GenServer.call(__MODULE__, :reboot)
  end

  @doc """
  Shuts down the rabbit.

  The SSH session disconnects when this function succeeds. Wait for shutdown
  to complete before removing power.
  """
  def halt() do
    GenServer.call(__MODULE__, :halt)
  end

  @doc """
  Erases persistent device data and reboots the rabbit.

  This operation is destructive and cannot be undone.
  """
  def factory_reset() do
    GenServer.call(__MODULE__, :factory_reset)
  end

  def trigger_event({:click, :single} = event) do
    Logger.debug("Single click event")
    publish_event(event)
  end

  #
  # Callbacks
  #

  @impl true
  def init(_opts) do
    Logger.debug("Starting Application Manager")

    state = %{
      config: Alfredpi.RabbitConfig.load(),
      running_apps: %{},
      hw: Application.fetch_env!(:rabbit_manager, :hardware),
      recording: false
    }

    :ok = apply(state.hw, :init, [])
    {:ok, state, {:continue, :autostart_applications}}
  end

  @impl true

  def handle_continue(:autostart_applications, state) do
    state =
      state.config
      |> Map.filter(fn {_app, config} -> Map.get(config, "autostart", false) end)
      |> Map.keys()
      |> Enum.reduce(state, fn app, state ->
        {:ok, state} = start_application(app, state)
        state
      end)

    {:noreply, state}
  end

  defp start_application(application, state) do
    app_config =
      Map.get(state.config, application, Kernel.apply(application, :default_config, []))

    child_spec = Kernel.apply(application, :child_spec, [app_config])

    case DynamicSupervisor.start_child(Alfredpi.DynamicSupervisor, child_spec) do
      {:ok, pid} ->
        publish_event({:application, application, :start})
        ref = Process.monitor(pid)
        state = put_in(state[:running_apps][ref], application)
        {:ok, state}

      {:error, {:already_started, pid}} ->
        ref = Process.monitor(pid)
        state = put_in(state[:running_apps][ref], application)
        {:ok, state}

      {:error, err} ->
        {:error, err}
    end
  end

  @impl true
  def handle_call(:get_parameters, _from, state) do
    {:reply, Alfredpi.Parameters.load_parameters(), state}
  end

  def handle_call({:set_parameters, parameters}, _from, state) do
    {:reply, Alfredpi.Parameters.save_parameters(parameters), state}
  end

  def handle_call({:start_application, application}, _from, state) do
    case start_application(application, state) do
      {:ok, state} ->
        {:reply, :ok, state}

      {:error, err} ->
        {:reply, {:error, err}, state}
    end
  end

  def handle_call(:get_application, _from, state) do
    {:reply, Application.fetch_env!(:rabbit_manager, :application_list), state}
  end

  def handle_call({:get_application_config, application}, _from, state) do
    {:reply,
     {:ok, Map.get(state.config, application, Kernel.apply(application, :default_config, []))},
     state}
  end

  def handle_call({:get_application_changeset, application}, _from, state) do
    config = Map.get(state.config, application, Kernel.apply(application, :default_config, []))
    changeset = Kernel.apply(application, :changeset, [config])
    {:reply, {:ok, changeset}, state}
  end

  def handle_call({:set_application_changeset, application, config}, _from, state) do
    changeset = Kernel.apply(application, :changeset, [config])

    state =
      if changeset.valid? do
        app_config = changeset_to_data(changeset)
        config = Map.put(state.config, application, app_config)
        Alfredpi.RabbitConfig.save(config)
        %{state | config: config}
      else
        state
      end

    changeset = changeset |> Map.put(:action, :update)
    {:reply, changeset, state}
  end

  def handle_call(:wifi_ready, _from, state) do
    :ok = apply(state.hw, :wifi_ready, [])
    {:reply, :ok, state}
  end

  def handle_call(:sound_ready, _from, state) do
    :ok = apply(state.hw, :sound_ready, [])
    {:reply, :ok, state}
  end

  def handle_call(:platform_ready, _from, state) do
    chor =
      Alfredpi.Parameters.load_parameters()
      |> Map.get(:startup_choregraphy_code)

    Task.start_link(fn ->
      ChoregraphyManager.execute_choregraphy(chor)
    end)

    :ok = apply(state.hw, :platform_ready, [])
    {:reply, :ok, state}
  end

  def handle_call({:ear_move, ear, clicks}, _from, state) do
    resp = apply(state.hw, :ear_move, [ear, clicks])
    {:reply, resp, state}
  end

  def handle_call({:ear_position, ear, position}, _from, state) do
    Logger.debug("Setting ear position")
    Logger.debug("Ear: #{inspect(ear)}")
    :ok = apply(state.hw, :ear_position, [ear, position])
    {:reply, :ok, state}
  end

  def handle_call({:ear_wait, ear}, _from, state) do
    :ok = apply(state.hw, :ear_wait, [ear])
    {:reply, :ok, state}
  end

  def handle_call({:ear_get, ear}, _from, state) do
    Logger.debug("Getting ear position")
    Logger.debug("Ear: #{inspect(ear)}")
    {:ok, pos} = apply(state.hw, :ear_get, [ear])
    {:reply, {:ok, pos}, state}
  end

  def handle_call({:head_clicked, event}, _from, state) do
    :ok = apply(state.hw, :head_clicked, [event])
    {:reply, :ok, state}
  end

  def handle_call({:leds_color, color, index}, _from, state) do
    :ok = apply(state.hw, :leds_color, [color, index])
    {:reply, :ok, state}
  end

  def handle_call({:play_url, root, name}, _from, state) do
    :ok = apply(state.hw, :play_url, [root, name])
    {:reply, :ok, state}
  end

  def handle_call({:play_file, file}, _from, state) do
    :ok = apply(state.hw, :play_file, [file])
    {:reply, :ok, state}
  end

  def handle_call({:record_file, file}, _from, %{recording: false} = state) do
    :ok = apply(state.hw, :record_file, [file])
    {:reply, :ok, %{state | recording: true}}
  end

  def handle_call({:record_file, _file}, _from, %{recording: true} = state) do
    {:reply, {:error, :already_recording}, state}
  end

  def handle_call(:stop_recording_file, _from, %{recording: true} = state) do
    :ok = apply(state.hw, :stop_recording_file, [])
    {:reply, :ok, %{state | recording: false}}
  end

  def handle_call(:stop_recording_file, _from, %{recording: false} = state) do
    {:reply, {:error, :not_recording}, state}
  end

  def handle_call(:stop_recording_file, _from, state) do
    :ok = apply(state.hw, :stop_recording_file, [])
    {:reply, :ok, state}
  end

  def handle_call(:reboot, _from, state) do
    :ok = apply(state.hw, :reboot, [])
    {:reply, :ok, state}
  end

  def handle_call(:halt, _from, state) do
    :ok = apply(state.hw, :halt, [])
    {:reply, :ok, state}
  end

  def handle_call(:factory_reset, _from, state) do
    :ok = apply(state.hw, :factory_reset, [])
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _exit_status} = _event, state) do
    running_apps = state[:running_apps]
    application = running_apps[ref]
    publish_event({:application, application, :stop})
    state = Map.put(state, :running_apps, Map.delete(running_apps, ref))
    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  defp changeset_to_data(changeset) do
    data =
      changeset
      |> Ecto.Changeset.apply_changes()

    data
    |> Map.keys()
    |> Enum.filter(&(&1 != :id and &1 != :__struct__))
    |> Enum.map(fn field -> {Atom.to_string(field), Map.get(data, field)} end)
    |> Map.new()
  end
end

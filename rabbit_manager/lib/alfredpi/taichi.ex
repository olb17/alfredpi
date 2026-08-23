defmodule Alfredpi.Taichi do
  @behaviour Alfredpi.RabbitManager.EmbedApplication
  use GenServer

  require Logger
  import Ecto.Changeset
  alias Alfredpi.ChoregraphyManager

  # Every hour
  @default_timer_interval 63 * 60 * 1_000

  defstruct timer: nil,
            timer_interval_in_msec: nil

  defmodule Param do
    use Ecto.Schema

    embedded_schema do
      field(:choregraphy_code, :string)
      field(:timer_interval_in_msec, :integer)
      field(:autostart, :boolean)
    end
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def application_name(), do: "Taichi"

  @impl Alfredpi.RabbitManager.EmbedApplication
  def default_config() do
    %{"timer_interval_in_msec" => @default_timer_interval}
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def changeset(params \\ %{}) do
    %Alfredpi.Taichi.Param{}
    |> cast(params, [:choregraphy_code, :timer_interval_in_msec, :autostart])
    |> validate_required([:choregraphy_code, :timer_interval_in_msec, :autostart])
    |> validate_choregraphy_code(:choregraphy_code)
  end

  defp validate_choregraphy_code(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn _field, value ->
      case ChoregraphyManager.get_choregraphy_by_code(value) do
        nil ->
          [{field, "Choregraphy with code '#{value}' not found"}]

        _ ->
          []
      end
    end)
  end

  def start_link(config) do
    Logger.debug("[Alfredpi.Taichi] Starting")
    timer_interval_in_msec = Map.get(config, "timer_interval_in_msec")

    if timer_interval_in_msec == nil do
      {:error, :invalid_config}
    else
      GenServer.start_link(__MODULE__, timer_interval_in_msec, name: __MODULE__)
    end
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def child_spec(config) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [config]}, restart: :transient}
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def kill() do
    GenServer.call(__MODULE__, :kill)
  end

  def play() do
    GenServer.call(__MODULE__, :play)
  end

  @impl GenServer
  def init(timer_interval_in_msec) do
    state =
      %__MODULE__{timer_interval_in_msec: timer_interval_in_msec}

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:kill, _from, state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    {:stop, :normal, :ok, %{state | timer: nil}}
  end

  def handle_call(:play, _from, state) do
    {:noreply, state} = handle_info(:play_next_taichi, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:play_next_taichi, state) do
    {:noreply, taichi(state)}
  end

  defp taichi(state) do
    state
    |> play_taichi()
    |> schedule_next_taichi()
  end

  defp play_taichi(state) do
    ChoregraphyManager.execute_choregraphy("SYSTEM_TAICHI")
    state
  end

  defp schedule_next_taichi(state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    timer_ref = Process.send_after(self(), :play_next_taichi, state.timer_interval_in_msec)
    Map.put(state, :timer, timer_ref)
  end
end

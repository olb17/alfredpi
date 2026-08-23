defmodule Alfredpi.Surprise do
  @behaviour Alfredpi.RabbitManager.EmbedApplication
  use GenServer

  require Logger
  import Ecto.Changeset
  alias Alfredpi.RabbitManager

  @available_files "available_sounds.txt"

  # Every hour
  @default_timer_interval 60 * 60 * 1_000

  defstruct next_file: nil,
            timer: nil,
            timer_interval_in_msec: nil,
            available_files: nil

  defmodule Param do
    use Ecto.Schema

    embedded_schema do
      field(:timer_interval_in_msec, :integer)
      field(:autostart, :boolean)
    end
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def application_name(), do: "Surprise"

  @impl Alfredpi.RabbitManager.EmbedApplication
  def default_config() do
    %{"timer_interval_in_msec" => @default_timer_interval}
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def changeset(params \\ %{}) do
    %Alfredpi.Surprise.Param{}
    |> cast(params, [:timer_interval_in_msec, :autostart])
    |> validate_required([:timer_interval_in_msec, :autostart])
  end

  def start_link(config) do
    Logger.debug("[Alfredpi.Surprise] Starting")
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

    {:ok, state, {:continue, :schedule_next_surprise}}
  end

  @impl GenServer
  def handle_continue(:schedule_next_surprise, state) do
    surprise_dir()
    |> File.mkdir_p()

    available_files =
      Path.join([:code.priv_dir(:rabbit_manager), "surprise", @available_files])
      |> File.read!()
      |> String.split("\n")
      |> MapSet.new()

    state =
      state
      |> Map.put(:available_files, available_files)
      |> schedule_next_surprise()

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:kill, _from, state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    {:stop, :normal, :ok, %{state | timer: nil}}
  end

  def handle_call(:play, _from, state) do
    {:noreply, state} = handle_info(:play_next_file, state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:play_next_file, state) do
    state =
      if state.next_file do
        surprise(state)
      else
        Logger.warning("[Alfredpi.Surprise] Unknown next file")
        state
      end

    {:noreply, state}
  end

  defp surprise(state) do
    state
    |> play_file()
    |> schedule_next_surprise()
  end

  defp play_file(state) do
    state.next_file
    |> file_path()
    |> RabbitManager.play_file()

    state
  end

  defp schedule_next_surprise(state) do
    state
    |> select_next_file()
    |> schedule()
  end

  defp schedule(state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    timer_ref = Process.send_after(self(), :play_next_file, state.timer_interval_in_msec)
    Map.put(state, :timer, timer_ref)
  end

  defp select_next_file(state) do
    downloaded_files = find_downloaded_files()
    not_downloaded_yet = MapSet.difference(state.available_files, downloaded_files)

    if MapSet.size(not_downloaded_yet) == 1 do
      # Choose 1 file randomly
      selected = Enum.random(downloaded_files)
      Map.put(state, :next_file, selected)
    else
      selected = Enum.random(not_downloaded_yet)

      case download_file(selected) do
        :ok ->
          Map.put(state, :next_file, selected)

        :error ->
          available_files = MapSet.delete(state.available_files, selected)

          state
          |> Map.put(:available_file, available_files)
          |> select_next_file()
      end
    end
  end

  defp file_path(file) do
    Path.join(surprise_dir(), file)
  end

  defp build_url(file) do
    language = Alfredpi.RabbitManager.get_parameters() |> Map.get(:language)

    "https://raw.githubusercontent.com/nabaztag2018/pynab/master/nabsurprised/sounds/#{language}/nabsurprised/#{file}"
  end

  defp download_file(file) do
    url = build_url(file)

    case Req.get(url) do
      {:ok, response} ->
        file_path(file) |> File.write(response.body, [:binary])
        :ok

      {:error, err} ->
        Logger.warning("[Alfredpi.Surprise] Cannot download #{url}: #{inspect(err)}")
        :error
    end
  end

  defp find_downloaded_files do
    surprise_dir() |> File.ls!() |> MapSet.new()
  end

  defp surprise_dir() do
    Path.join(Application.fetch_env!(:rabbit_manager, :dir), "surprise")
  end
end

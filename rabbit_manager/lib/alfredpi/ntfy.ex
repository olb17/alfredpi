defmodule Alfredpi.Ntfy do
  @behaviour Alfredpi.RabbitManager.EmbedApplication
  use WebSockex

  require Logger
  import Ecto.Changeset

  defmodule Param do
    use Ecto.Schema

    embedded_schema do
      field(:ntfy_server, :string)
      field(:topic, :string)
      field(:autostart, :boolean)
    end
  end

  @ntfy_server ""
  @topic ""

  @impl Alfredpi.RabbitManager.EmbedApplication
  def application_name(), do: "Ntfy"

  @impl Alfredpi.RabbitManager.EmbedApplication
  def default_config() do
    %{"ntfy_server" => @ntfy_server, "topic" => @topic}
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def changeset(params \\ %{}) do
    %Alfredpi.Ntfy.Param{}
    |> cast(params, [:ntfy_server, :topic, :autostart])
    |> validate_required([:ntfy_server, :topic, :autostart])
  end

  def start_link(config) do
    Logger.debug("[Alfredpi.Ntfy] Starting with config: #{inspect(config)}")
    ntfy_server = Map.get(config, "ntfy_server")
    topic = Map.get(config, "topic")

    if ntfy_server == nil or topic == nil do
      {:error, :invalid_config}
    else
      WebSockex.start_link(ntfy_server <> topic <> "/ws", __MODULE__, nil,
        async: true,
        handle_initial_conn_failure: true,
        name: __MODULE__
      )
    end
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def child_spec(config) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [config]}, restart: :transient}
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def kill() do
    GenServer.stop(__MODULE__)
  end

  @impl WebSockex
  def handle_frame({_type, msg}, state) do
    msg = Jason.decode!(msg)

    if msg["event"] != "open" do
      Alfredpi.RabbitManager.ear_move(:left, -17)
    end

    {:ok, state}
  end

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.debug("[Alfredpi.Ntfy] Connected")
    {:ok, state}
  end

  @impl true
  def handle_disconnect(_status, state) do
    Logger.debug("[Alfredpi.Ntfy] Cannot connect -- sleeping")
    Process.sleep(2_000)
    {:reconnect, state}
  end
end

defmodule Rainbow do
  @behaviour Alfredpi.RabbitManager.EmbedApplication
  use GenServer

  require Logger

  import Ecto.Changeset

  defmodule Param do
    use Ecto.Schema

    embedded_schema do
    end
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def application_name(), do: "Rainbow"

  @impl Alfredpi.RabbitManager.EmbedApplication
  def default_config() do
    %{}
  end

  def start_link(opts) do
    Logger.debug("Starting Rainbow")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def child_spec(_opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [nil]}, restart: :transient}
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def changeset(params \\ %{}) do
    %Rainbow.Param{}
    |> cast(params, [])
  end

  @impl Alfredpi.RabbitManager.EmbedApplication
  def kill() do
    GenServer.call(__MODULE__, :kill)
  end

  @impl GenServer
  def init(_opts) do
    :ok = Rainbow.Worker.begin_animation(colors())
    {:ok, nil}
  end

  @impl GenServer
  def handle_call(:kill, _from, state) do
    # :ok = Rainbow.Worker.stop_animation()
    :ok = Rainbow.Worker.color("#000000")
    :ok = Rainbow.Worker.color("#0000FF", :led_0)
    {:stop, :normal, :ok, state}
  end

  @moduledoc """
  This is the top-level API for this example project.
  """

  alias Blinkchain.Color

  # We might as well compute these at compile time instead of every time
  # the `colors` function gets called.
  @colors [
    Color.parse("#9400D3"),
    Color.parse("#4B0082"),
    Color.parse("#0000FF"),
    Color.parse("#00FF00"),
    Color.parse("#FFFF00"),
    Color.parse("#FF7F00"),
    Color.parse("#FF0000")
  ]

  def colors(), do: @colors
end

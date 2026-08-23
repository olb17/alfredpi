defmodule Alfredpi.Ear do
  use Supervisor
  require Logger

  @type ear :: :right | :left

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @spec move(ear(), integer()) :: {:ok, :ok} | {:error, any()}
  def move(ear, clicks) when is_integer(clicks) do
    GenServer.call(select_ear(ear), {:move, clicks})
  end

  @spec position(ear(), integer()) :: {:ok, :ok} | {:error, any()}
  def position(ear, pos) when is_integer(pos) do
    GenServer.call(select_ear(ear), {:position, pos})
  end

  @spec wait(ear()) :: {:ok, :ok} | {:error, any()}
  def wait(ear) do
    GenServer.call(select_ear(ear), :wait)
  end

  @spec get(ear()) :: {:ok, integer()} | {:error, any()}
  def get(ear) do
    Logger.debug("Getting ear position hw")
    GenServer.call(select_ear(ear), :get)
  end

  @impl true
  def init(_opts) do
    Logger.debug("Starting Ear Manager")

    left =
      Supervisor.child_spec(
        {Alfredpi.EarExecutor, {"0", Alfredpi.EarLeft}},
        id: Alfredpi.EarLeft
      )

    right =
      Supervisor.child_spec(
        {Alfredpi.EarExecutor, {"1", Alfredpi.EarRight}},
        id: Alfredpi.EarRight
      )

    children = [left, right]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp select_ear(:left), do: Alfredpi.EarLeft
  defp select_ear(:right), do: Alfredpi.EarRight
end

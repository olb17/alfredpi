defmodule Alfredpi.EarExecutor do
  use GenServer
  require Logger

  @base_device "/dev/ear"

  def start_link({ear_id, name}) do
    GenServer.start_link(__MODULE__, ear_id, name: name)
  end

  @impl true
  def init(ear_id) do
    Logger.debug("Starting Ear Executor #{ear_id}")
    {:ok, nil, {:continue, {:ear_continue, ear_id}}}
  end

  @impl true
  def handle_continue({:ear_continue, ear_id}, _state) do
    Process.sleep(4_000)
    {:ok, ear} = File.open(@base_device <> ear_id, [:raw, :write, :read])

    {:noreply, ear}
  end

  @impl true
  def handle_call({:move, clicks}, _from, state) do
    ret = move_device(state, clicks)

    {:reply, ret, state}
  end

  def handle_call({:position, pos}, _from, state) do
    ret = position_device(state, pos)

    {:reply, ret, state}
  end

  def handle_call(:wait, _from, state) do
    ret = writeEar(state, <<?.>>)

    {:reply, ret, state}
  end

  def handle_call(:get, _from, state) do
    ret = get_position(state)

    {:reply, ret, state}
  end

  defp move_device(device, clicks) do
    cond do
      clicks > 0 and clicks < 255 ->
        writeEar(device, <<?+, clicks>>)

      clicks < 0 and clicks > -255 ->
        writeEar(device, <<?-, -clicks>>)

      true ->
        {:error, :invalid_clicks_value}
    end
  end

  defp position_device(device, pos) do
    cond do
      pos >= 0 ->
        writeEar(device, <<?>, pos>>)

      pos < 0 ->
        writeEar(device, <<?<, -pos>>)
    end
  end

  defp writeEar(device, msg) do
    Logger.debug("Writing #{inspect(device)} with msg: #{inspect(msg)}")
    :ok = IO.binwrite(device, msg)
  end

  defp get_position(device) do
    :ok = IO.binwrite(device, ~c"?")

    case IO.binread(device, 1) do
      <<255>> ->
        :ok = IO.binwrite(device, ~c"!")
        get_position([device])

      <<pos>> ->
        {:ok, pos}

      :eof ->
        {:error, :eof}

      err ->
        err
    end
  end
end

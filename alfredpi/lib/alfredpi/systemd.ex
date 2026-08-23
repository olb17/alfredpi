defmodule Alfredpi.Systemd do
  use GenServer
  require Logger

  def systemd_childspec(id, app, param \\ []) do
    %{id: id, start: {Alfredpi.Systemd, :start_link, [id, app, param]}, restart: :transient}
  end

  def stop_child(id) do
    GenServer.call(id, :stop)
  end

  def start_link(id, program, params) do
    GenServer.start_link(__MODULE__, {program, params}, name: id)
  end

  @impl true
  def init({program, params}) do
    state = %{
      process: nil,
      program: program,
      params: params
    }

    {:ok, state, {:continue, :start_systemd}}
  end

  @impl true
  def handle_continue(:start_systemd, state) do
    cmd = System.find_executable(state.program)
    Logger.debug("Starting #{cmd} / #{inspect(state.params)}")

    process =
      Porcelain.spawn(cmd, state.params,
        in: :receive,
        out: {:send, self()},
        err: {:send, self()},
        result: :discard
      )

    state = Map.put(state, :process, process)
    {:noreply, state}
  end

  @impl true
  def handle_call(:kill, _from, state) do
    cmd = System.find_executable(state.program)
    Logger.debug("Stopping #{cmd}: #{inspect(state.process)}")
    Porcelain.Process.signal(state.process, :kill)
    {:stop, :normal, :ok, %{state | process: nil}}
  end

  @impl true
  def handle_info({_from, :data, :err, data}, state) do
    Logger.debug("Receiving err message from port: #{data}")
    Logger.debug("Restarting program")
    {:stop, :subprocess_died, state}
  end

  def handle_info({_from, :data, :out, data}, state) do
    Logger.debug("Receiving out message from port: #{data}")
    {:noreply, state}
  end

  def handle_info({_from, :data, data}, state) do
    Logger.debug("Receiving message from port: #{data}")
    {:noreply, state}
  end

  def handle_info({_from, :result, _data}, state) do
    Logger.debug("Restarting program")
    {:stop, :subprocess_died, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Receiving info from port: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) when state.process != nil do
    cmd = System.find_executable(state.program)
    Logger.debug("Stopping #{cmd}: #{inspect(state.process)}")
    Porcelain.Process.signal(state.process, :kill)
    :ok
  end

  def terminate(_reason, _state) do
    :ok
  end
end

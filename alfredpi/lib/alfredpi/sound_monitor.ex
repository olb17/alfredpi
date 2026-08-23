defmodule Alfredpi.SoundMonitor do
  use GenServer
  require Logger

  alias Alfredpi.RabbitManager

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    Logger.debug("Monitoring Sound Device")

    NervesUEvent.subscribe([
      "devices",
      "platform",
      "soc",
      "soc:sound",
      "sound",
      "card0",
      "controlC0"
    ])

    status =
      NervesUEvent.get([
        "devices",
        "platform",
        "soc",
        "soc:sound",
        "sound",
        "card0",
        "controlC0",
        "uevent"
      ])

    Logger.debug("[SoundMonitor] Initial state: #{inspect(status)}")
    {:ok, nil}
  end

  @impl true
  def handle_info(
        %PropertyTable.Event{
          property: ["devices", "platform", "soc", "soc:sound", "sound", "card0", "controlC0"],
          value: _value
        },
        state
      ) do
    :ok = RabbitManager.sound_ready()
    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end
end

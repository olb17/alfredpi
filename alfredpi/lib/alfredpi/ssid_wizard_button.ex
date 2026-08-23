defmodule Alfredpi.SSIDWizard.Button do
  use GenServer

  require Logger

  @moduledoc """
  This GenServer starts the wizard if a button is depressed for long enough.
  """

  alias Circuits.GPIO

  @doc """
  Start the button monitor

  Pass an index to the GPIO that's connected to the button.
  """
  @spec start_link(non_neg_integer()) :: GenServer.on_start()
  def start_link(gpio_pin) do
    GenServer.start_link(__MODULE__, gpio_pin)
  end

  @impl GenServer
  def init(gpio_pin) do
    {:ok, gpio} = GPIO.open(gpio_pin, :input)
    :ok = GPIO.set_interrupts(gpio, :both)
    {:ok, %{pin: gpio_pin, gpio: gpio, on_going_wizard: false}}
  end

  @impl GenServer
  def handle_info({:circuits_gpio, gpio_pin, _timestamp, 0}, %{pin: gpio_pin} = state) do
    # Button pressed. Start a timer to launch the wizard when it's long enough
    {:noreply, %{state | on_going_wizard: false}, 5_000}
  end

  def handle_info(
        {:circuits_gpio, gpio_pin, _timestamp, 1},
        %{pin: gpio_pin, on_going_wizard: false} = state
      ) do
    # Button released. The GenServer timer is implicitly cancelled by receiving this message.
    Alfredpi.RabbitManager.trigger_event({:click, :single})
    {:noreply, state}
  end

  def handle_info({:circuits_gpio, gpio_pin, _timestamp, 1}, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    Logger.debug("Starting Wizard")
    Alfredpi.RabbitManager.leds_color("#a51d2d", :all)
    Application.stop(:alfredpi_ui)

    VintageNetWizard.run_wizard(
      on_exit: {Alfredpi.Application, :exit_ap_mode, []},
      device_info: Alfredpi.Application.get_device_info()
    )

    {:noreply, %{state | on_going_wizard: true}}
  end
end

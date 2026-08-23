defmodule Rainbow.Worker do
  use GenServer
  require Logger
  alias Blinkchain.Color

  # Arrangement looks like this:
  # Y  X: 0  1  2  3  4  5  6  7
  # 0  [  0  1  2  3  4  5  6  7 ] <- Adafruit NeoPixel Stick on Channel 1 (pin 13)
  #    |-------------------------|
  # 1  |  0  1  2  3  4  5  6  7 |
  # 2  |  8  9 10 11 12 13 14 15 | <- Pimoroni Unicorn pHat on Channel 0 (pin 18)
  # 3  | 16 17 18 19 20 21 22 23 |
  # 4  | 24 25 26 27 28 29 30 31 |
  #    |-------------------------|

  alias Blinkchain.Point

  defmodule State do
    defstruct [:timer, :colors]
  end

  def begin_animation(colors), do: GenServer.call(__MODULE__, {:begin, colors})
  def stop_animation(), do: GenServer.call(__MODULE__, :end)

  def color(color, index \\ :all), do: GenServer.call(__MODULE__, {:color, color, index})

  def die(), do: GenServer.call(__MODULE__, :die)

  def start_link(opts \\ []) do
    Logger.debug("[Rainbow.Worker] Starting")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start(opts \\ []) do
    GenServer.start(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    state = %State{
      timer: nil,
      colors: nil
    }

    {:ok, state}
  end

  def handle_call({:begin, colors}, _from, %{timer: nil} = state) do
    Logger.debug("Playing colors : #{inspect(colors)}")

    {:ok, ref} = :timer.send_interval(250, :draw_frame)
    {:reply, :ok, %{state | timer: ref, colors: colors}}
  end

  def handle_call(:begin, _from, state) do
    {:reply, :already_running, state}
  end

  def handle_call(:end, _from, %{timer: timer} = state) when timer != nil do
    :timer.cancel(state.timer)
    {:reply, :ok, %{state | timer: nil, colors: nil}}
  end

  def handle_call(:end, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:color, color, :all}, _from, state) do
    if state.timer, do: :timer.cancel(state.timer)

    c = Color.parse(color)

    for i <- 0..4 do
      Blinkchain.set_pixel(%Point{x: i, y: 0}, c)
    end

    Blinkchain.render()
    {:reply, :ok, %{state | timer: nil}}
  end

  def handle_call({:color, color, led}, _from, state) do
    index = led_to_index(led)
    if state.timer, do: :timer.cancel(state.timer)

    c = Color.parse(color)

    Blinkchain.set_pixel(%Point{x: index, y: 0}, c)

    Blinkchain.render()
    {:reply, :ok, %{state | timer: nil}}
  end

  def handle_call(:die, _from, state) do
    {:stop, :ok, state}
  end

  def handle_info(:draw_frame, state) do
    [c1, c2, c3, c4, c5] = Enum.slice(state.colors, 0..4)
    tail = Enum.slice(state.colors, 1..-1//-1)

    # Shift all pixels to the right
    Blinkchain.copy(%Point{x: 0, y: 0}, %Point{x: 1, y: 0}, 4, 0)

    # Populate the five leftmost pixels with new colors
    Blinkchain.set_pixel(%Point{x: 0, y: 0}, c1)
    Blinkchain.set_pixel(%Point{x: 1, y: 0}, c2)
    Blinkchain.set_pixel(%Point{x: 2, y: 0}, c3)
    Blinkchain.set_pixel(%Point{x: 3, y: 0}, c4)
    Blinkchain.set_pixel(%Point{x: 4, y: 0}, c5)

    Blinkchain.render()
    {:noreply, %State{state | colors: tail ++ [c1]}}
  end

  defp led_to_index(:led_0), do: 0
  defp led_to_index(:led_1), do: 1
  defp led_to_index(:led_2), do: 2
  defp led_to_index(:led_3), do: 3
  defp led_to_index(:led_4), do: 4
end

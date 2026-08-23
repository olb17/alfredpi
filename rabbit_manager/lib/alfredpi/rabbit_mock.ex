defmodule Alfredpi.RabbitMock do
  require Logger

  def init() do
    :ok
  end

  def ear_move(ear, clicks) do
    Logger.debug("[ RabbitMock ] Ear move #{inspect(ear)} of clicks #{clicks}")
    :ok
  end

  def ear_position(ear, position) do
    Logger.debug("[ RabbitMock ] Ear move #{inspect(ear)} of position #{position}")
    :ok
  end

  def ear_wait(ear) do
    Logger.debug("[ RabbitMock ] Ear wait #{inspect(ear)}")
    :ok
  end

  def ear_get(ear) do
    Logger.debug("[ RabbitMock ] Ear get #{inspect(ear)}")
    {:ok, 10}
  end

  def leds_color(color, index) do
    Logger.debug("[ RabbitMock ] Leds color #{inspect(color)} for led #{index}")
    :ok
  end

  def play_url(root, name) do
    Logger.debug("[ RabbitMock ] Playing file from #{inspect(root)} with name #{inspect(name)}")
    :ok
  end

  def play_file(file) do
    Logger.debug("[ RabbitMock ] Playing file #{inspect(file)}")
    :ok
  end

  def record_file(file) do
    Logger.debug("[ RabbitMock ] Recording file #{inspect(file)}")
    :ok
  end

  def stop_recording_file() do
    Logger.debug("[ RabbitMock ] Stop recording file")
    :ok
  end

  def wifi_ready() do
    Logger.debug("[ RabbitMock ] Wifi ready")
    :ok
  end

  def sound_ready() do
    Logger.debug("[ RabbitMock ] Sound ready")
    :ok
  end

  def reboot() do
    Logger.debug("[ RabbitMock ] Reboot requested")
    :ok
  end

  def halt() do
    Logger.debug("[ RabbitMock ] Halt requested")
    :ok
  end

  def factory_reset() do
    Logger.debug("[ RabbitMock ] Factory Reset requested")
    :ok
  end

  def platform_ready() do
    Logger.debug("[ RabbitMock ] Plateform ready")
    :ok
  end
end

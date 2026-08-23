defmodule Alfredpi.RabbitHardware do
  @mixer "tagtagtag-mixerd"

  require Logger

  def init() do
    :ok
  end

  def ear_move(ear, clicks), do: Alfredpi.Ear.move(ear, clicks)

  def ear_position(ear, position), do: Alfredpi.Ear.position(ear, position)

  def ear_wait(ear), do: Alfredpi.Ear.wait(ear)

  def ear_get(ear), do: Alfredpi.Ear.get(ear)

  def wifi_ready(), do: :ok

  def play_url(root, name) do
    {:ok, filename} = Alfredpi.ResourceManager.get_resource(root, name)

    program =
      cond do
        String.ends_with?(filename, ".wav") -> "/usr/bin/aplay"
        true -> "/usr/bin/mpg123"
      end

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Alfredpi.DynamicSupervisor,
        system_cmd(:play_file, program, [filename])
      )

    :ok
  end

  def play_file(file) do
    program =
      cond do
        String.ends_with?(file, ".wav") -> "/usr/bin/aplay"
        true -> "/usr/bin/mpg123"
      end

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Alfredpi.DynamicSupervisor,
        system_cmd(:play_file, program, [file])
      )

    :ok
  end

  def record_file(file) do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Alfredpi.DynamicSupervisor,
        Alfredpi.SoundRecorder.child_spec(file)
      )

    :ok
  end

  def stop_recording_file() do
    Alfredpi.SoundRecorder.kill()
  end

  def sound_ready() do
    [
      Alfredpi.Systemd.systemd_childspec(:mixer, @mixer, []),
      system_cmd(:volume, "/usr/bin/amixer", ["sset", "'Playback'", "255"]),
      system_cmd(:volume, "/usr/bin/amixer", ["sset", "'Capture'", "255"]),
      system_cmd(:power, "/usr/bin/amixer", ["sset", "'Playback'", "on"])
    ]
    |> Enum.each(fn childspec ->
      {:ok, _pid} = DynamicSupervisor.start_child(Alfredpi.DynamicSupervisor, childspec)
    end)

    :ok
  end

  def reboot() do
    Logger.debug("[ RabbitHardware ] Reboot requested")
    Nerves.Runtime.reboot()
    :ok
  end

  def halt() do
    Logger.debug("[ RabbitHardware ] Halt requested")
    Nerves.Runtime.poweroff()
    :ok
  end

  def factory_reset() do
    Logger.debug("[ RabbitHardware ] Factory reset requested")
    Nerves.Runtime.FwupOps.factory_reset(reboot: true)
    :ok
  end

  def platform_ready() do
    :ok
  end

  def leds_color(color, index), do: Rainbow.Worker.color(color, index)

  defp system_cmd(id, cmd, cmd_args) do
    %{
      id: id,
      restart: :transient,
      start: {Task, :start_link, [fn -> System.cmd(cmd, cmd_args) end]}
    }
  end
end

defmodule Alfredpi.SoundRecorder do
  @sound_recorder "/usr/bin/arecord"

  alias Alfredpi.Systemd

  def child_spec(file) do
    Systemd.systemd_childspec(__MODULE__, @sound_recorder, ["-q", "-t", "wav", "-f", "cd", file])
  end

  def kill() do
    GenServer.call(__MODULE__, :kill)
  end
end

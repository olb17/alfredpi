defmodule Alfredpi.RabbitConfig do
  def load() do
    filepath = config_filepath()

    if File.exists?(filepath) do
      filepath
      |> File.read!()
      |> Jason.decode!()
      |> Enum.map(fn {app_str, config} ->
        {String.to_existing_atom(app_str), config}
      end)
      |> Map.new()
    else
      %{}
    end
  end

  def save(config) do
    filepath = config_filepath()
    File.write!(filepath, Jason.encode!(config))
  end

  defp config_filepath() do
    config_dir = Path.join(Application.fetch_env!(:rabbit_manager, :dir), "config")
    File.mkdir_p(config_dir)
    Path.join(config_dir, "alfredpi.json")
  end
end

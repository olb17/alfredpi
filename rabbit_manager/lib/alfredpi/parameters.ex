defmodule Alfredpi.Parameters do
  alias Ecto.Changeset

  @param_filename "alfredpi_params.json"

  def load_parameters() do
    case File.read(filepath()) do
      {:ok, str} -> json_to_parameter(str)
      {:error, _err} -> %Alfredpi.RabbitManager.Parameters{}
    end
  end

  def save_parameters(parameters_changeset) do
    parameters =
      %Alfredpi.RabbitManager.Parameters{}
      |> Map.put(
        :startup_choregraphy,
        Changeset.fetch_field!(parameters_changeset, :startup_choregraphy_code)
      )
      |> Map.put(
        :language,
        Changeset.fetch_field!(parameters_changeset, :language)
      )

    str = Jason.encode!(parameters |> Map.from_struct())
    File.write!(filepath(), str, [:write])
  end

  defp json_to_parameter(json) do
    obj = Jason.decode!(json)

    %Alfredpi.RabbitManager.Parameters{
      startup_choregraphy_code: obj["startup_choregraphy"],
      language: obj["language"]
    }
  end

  defp filepath() do
    Path.join(Application.get_env(:rabbit_manager, :dir), @param_filename)
  end
end

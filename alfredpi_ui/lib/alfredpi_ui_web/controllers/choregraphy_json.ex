defmodule AlfredpiUiWeb.ChoregraphyJSON do
  alias Alfredpi.ChoregraphyManager.Choregraphy

  def index(%{choregraphies: choregraphies}) do
    %{
      data:
        for chor <- choregraphies do
          data(chor)
        end
    }
  end

  def play(%{choregraphy: chor}) do
    %{data: data(chor)}
  end

  defp data(%Choregraphy{} = chor) do
    %{
      code: chor.code,
      name: chor.name
    }
  end
end

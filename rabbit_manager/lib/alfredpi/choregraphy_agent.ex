defmodule Alfredpi.ChoregraphyAgent do
  use Agent

  # state : Map( code -> choregraphy)
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def load_state(chors) do
    new_state =
      chors
      |> Enum.map(fn chor -> {chor.code, chor} end)
      |> Map.new()

    Agent.update(__MODULE__, fn _state -> new_state end)
  end

  def list_choregraphy() do
    Agent.get(__MODULE__, fn state ->
      Enum.map(state, fn {_, chor} -> chor end)
    end)
  end

  def get_choregraphy_by_code(code) do
    Agent.get(__MODULE__, fn state -> Map.get(state, code) end)
  end

  def update_choregraphy(choregraphy) do
    Agent.update(__MODULE__, fn state -> Map.put(state, choregraphy.code, choregraphy) end)
  end

  def delete_choregraphy(choregraphy) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, choregraphy.code) end)
  end

  def choregraphy_exists?(code) do
    Agent.get(__MODULE__, fn state -> Map.has_key?(state, code) end)
  end
end

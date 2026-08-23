defmodule ChoregraphyManagerTest do
  use ExUnit.Case, async: true
  # doctest Choregraphy

  alias Alfredpi.ChoregraphyManager

  @chor_dir Path.join(System.tmp_dir!(), "test_choregaphy_manager")

  setup do
    start_supervised!({Alfredpi.RabbitSupervisor, choregraphy_dir: @chor_dir})
    :ok
  end

  test "There are only system choregraphies at blank startup" do
    assert length(ChoregraphyManager.list_choregraphy()) == 2,
           "Invalid number of initial choregraphies"
  end

  test "System choregaphy cannot be edited" do
    sys_chor =
      ChoregraphyManager.list_choregraphy()
      |> Enum.find(&ChoregraphyManager.Choregraphy.is_system/1)

    assert {:error, :cannot_save_system_choregraphy, _} =
             ChoregraphyManager.update_choregraphy(sys_chor),
           "System code should be saved"
  end

  @code "TEST_BLUE"

  @tag :skip2
  test "Inserting a new choregraphy" do
    on_exit(&clean_chor_dir/0)

    chor = %Alfredpi.ChoregraphyManager.Choregraphy{
      name: "Set leds to blue",
      code: @code,
      actions: "led_color Led0, ~3d34eb"
    }

    assert {:ok, _} = ChoregraphyManager.update_choregraphy(chor)
    new_chor = ChoregraphyManager.get_choregraphy_by_code(@code)
    assert chor.name == new_chor.name, "choregraphy name is not saved"

    stop_supervised!(Alfredpi.RabbitSupervisor)
    start_supervised!({Alfredpi.RabbitSupervisor, choregraphy_dir: @chor_dir})

    new_chor = ChoregraphyManager.get_choregraphy_by_code(@code)
    assert chor.name == new_chor.name, "choregraphy name is not saved"
  end

  @tag :skip2
  test "updating a choregraphy" do
    on_exit(&clean_chor_dir/0)

    chor = %Alfredpi.ChoregraphyManager.Choregraphy{
      name: "Set leds to blue",
      code: @code,
      actions: "led_color Led0, ~3d34eb"
    }

    assert {:ok, _} = ChoregraphyManager.update_choregraphy(chor)
    chor = %{chor | name: "New title", actions: "new actions"}
    assert {:ok, _} = ChoregraphyManager.update_choregraphy(chor)

    new_chor = ChoregraphyManager.get_choregraphy_by_code(@code)
    assert chor.name == new_chor.name, "choregraphy title is not updated"
    assert chor.actions == new_chor.actions, "choregraphy title is not updated"

    stop_supervised!(Alfredpi.RabbitSupervisor)
    start_supervised!({Alfredpi.RabbitSupervisor, choregraphy_dir: @chor_dir})

    new_chor = ChoregraphyManager.get_choregraphy_by_code(@code)
    assert chor.name == new_chor.name, "choregraphy name is not saved"
  end

  @tag :skip2
  test "deleting a choregraphy" do
    on_exit(&clean_chor_dir/0)

    chor = %Alfredpi.ChoregraphyManager.Choregraphy{
      name: "Set leds to blue",
      code: @code,
      actions: "led_color Led0, ~3d34eb"
    }

    assert {:ok, _} = ChoregraphyManager.update_choregraphy(chor)
    assert :ok = ChoregraphyManager.delete_choregraphy(chor)

    stop_supervised!(Alfredpi.RabbitSupervisor)
    start_supervised!({Alfredpi.RabbitSupervisor, choregraphy_dir: @chor_dir})
    assert nil == ChoregraphyManager.get_choregraphy_by_code(@code)
  end

  def clean_chor_dir() do
    File.ls!(@chor_dir)
    |> Enum.map(fn file ->
      File.rm!(Path.join(@chor_dir, file))
    end)
  end
end

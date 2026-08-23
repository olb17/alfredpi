defmodule ChoregraphyTest do
  use ExUnit.Case
  # doctest Choregraphy

  @code1 """
    # Ear actions

    move_ear Left, 5
    move_ear Left, +5
    move_ear Right, -5
    set_ear Left, 12

    # LED actions
    led_color ~123456, Led2

    # Control actions
    #sleep 00

    var Variable1 = ~123456
    var Variable2 = 2

    exec
      move_ear Left, 5
      move_ear Left, +5
      move_ear Right, -5
    and
      led_color ~123456, Led2
    end

    # Repeat n times
    repeat 3
      move_ear Right, -5
    end

    repeat 2 # Variable2
      move_ear Right, -5
    end

    # Repeat n times
    #repeat 34
    #  exec
    #    action1
    #    action3
    #    action4
    #  and
    #    action2
    #  end
    #end
  """

  setup_all do
    start_supervised!(Alfredpi.RabbitSupervisor)
    :ok
  end

  test "Parse a complex code" do
    assert :ok = Alfredpi.Choregraphy.Executor.validate(@code1, log: true)
  end

  @code_string """
    play "url, 1", "ressource.mp3"
  """
  test "Parse string" do
    assert :ok = Alfredpi.Choregraphy.Executor.validate(@code_string)
  end

  test "Execute string" do
    assert Alfredpi.Choregraphy.Executor.execute(@code_string)
  end

  @err_code1 """
      action1
      action2 ~4fg
      action3
  """
  test "Find a token error" do
    assert {:error, 2, :illegal, "~4fg"} = Alfredpi.Choregraphy.Executor.validate(@err_code1)
  end

  @err_code2 """
      action1
      action2 Coucou Hello
      action3
  """
  test "Find a grammar error in arguments" do
    assert {:error, 2, "syntax error before: ", ["\"Hello\""]} ==
             Alfredpi.Choregraphy.Executor.validate(@err_code2)
  end

  @err_code3 """
      action1
      repeat action2 end
      action3
  """
  test "Find a grammar error in repeat" do
    assert {:error, 2, "syntax error before: ", ["\"action2\""]} ==
             Alfredpi.Choregraphy.Executor.validate(@err_code3)
  end

  @err_code4 """
      action1
      repeat action2 
      action3
  """
  test "Find a grammar error in repeat withoud end" do
    assert {:error, 2, "syntax error before: ", ["\"action2\""]} ==
             Alfredpi.Choregraphy.Executor.validate(@err_code4)
  end

  @err_code5 """
    exec
      move_ear Left, 1
    and
      move_ear Left, 2
    and
      move_ear Left, 3
    end
  """
  test "Test 3 parallel instructions branches" do
    assert Alfredpi.Choregraphy.Executor.execute(@err_code5)
  end
end

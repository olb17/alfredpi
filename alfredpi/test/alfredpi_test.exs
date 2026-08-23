defmodule AlfredpiTest do
  use ExUnit.Case
  doctest Alfredpi

  test "greets the world" do
    assert Alfredpi.hello() == :world
  end
end

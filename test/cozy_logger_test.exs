defmodule CozyLoggerTest do
  use ExUnit.Case
  doctest CozyLogger

  test "greets the world" do
    assert CozyLogger.hello() == :world
  end
end

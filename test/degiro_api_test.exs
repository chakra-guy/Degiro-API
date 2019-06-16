defmodule DegiroTest do
  use ExUnit.Case
  doctest Degiro

  test "greets the world" do
    assert Degiro.hello() == :world
  end
end

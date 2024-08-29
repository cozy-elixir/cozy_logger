defmodule CozyLogger.Formats.JSONTest do
  use ExUnit.Case, async: true

  alias CozyLogger.Formats.JSON

  defmodule TestStruct do
    defstruct [:field]
  end

  defp encode_as_string!(value) do
    {value, []}
    |> JSON.encode!()
    |> to_string()
  end

  test "it can encode PIDs" do
    assert encode_as_string!(%{pid: :c.pid(0, 250, 0)}) == ~s({"pid":"#PID<0.250.0>"})
  end

  test "it can encode Ports" do
    port = Port.open({:spawn, "cat"}, [:binary])
    assert encode_as_string!(%{port: port}) =~ ~r/{\"port\":\"#Port<.+>\"}/
  end

  test "it can encode References" do
    reference = Process.monitor(self())
    assert encode_as_string!(%{ref: reference}) =~ ~r/{\"ref\":\"#Reference<.+>\"}/
  end

  test "it can encode tuples" do
    assert encode_as_string!(%{tuple: {:test, 1, :c.pid(0, 250, 0)}}) =~
             ~s({"tuple":"{:test, 1, #PID<0.250.0>}"})
  end

  test "it can encode functions" do
    assert encode_as_string!(%{fun: fn -> nil end}) =~ ~r/#Function/
  end

  test "it recursively encodes maps" do
    assert encode_as_string!(%{stuff: %{pid: :c.pid(0, 250, 0)}}) ==
             ~s({"stuff":{"pid":"#PID<0.250.0>"}})
  end

  test "it recursively encodes struct" do
    assert encode_as_string!(%TestStruct{field: %{pid: :c.pid(0, 250, 0)}}) ==
             ~s({"field":{"pid":"#PID<0.250.0>"}})
  end

  test "it encodes map keys" do
    assert encode_as_string!(%{:c.pid(0, 250, 0) => 1}) == ~s({"#PID<0.250.0>":1})
  end

  test "it recursively encodes lists" do
    assert encode_as_string!(%{data: [1, 2, [3, :c.pid(0, 250, 0)]]}) ==
             ~s({"data":[1,2,[3,"#PID<0.250.0>"]]})
  end
end

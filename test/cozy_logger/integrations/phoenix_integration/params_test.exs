defmodule CozyLogger.PhoenixIntegration.ParamsTest do
  use ExUnit.Case

  alias CozyLogger.PhoenixIntegration.Params

  describe "filter/2 with discard strategy" do
    test "in top level map" do
      params = %{"foo" => "bar", "password" => "should_not_show"}

      assert Params.filter(params, ["password"]) ==
               %{"foo" => "bar", "password" => "[FILTERED]"}
    end

    test "when a map has secret key" do
      params = %{"foo" => "bar", "map" => %{"password" => "should_not_show"}}

      assert Params.filter(params, ["password"]) ==
               %{"foo" => "bar", "map" => %{"password" => "[FILTERED]"}}
    end

    test "when a list has a map with secret" do
      params = %{"foo" => "bar", "list" => [%{"password" => "should_not_show"}]}

      assert Params.filter(params, ["password"]) ==
               %{"foo" => "bar", "list" => [%{"password" => "[FILTERED]"}]}
    end

    test "does not filter structs" do
      params = %{"foo" => "bar", "file" => %Plug.Upload{}}

      assert Params.filter(params, ["password"]) ==
               %{"foo" => "bar", "file" => %Plug.Upload{}}

      params = %{"foo" => "bar", "file" => %{__struct__: "s"}}

      assert Params.filter(params, ["password"]) ==
               %{"foo" => "bar", "file" => %{:__struct__ => "s"}}
    end

    test "does not fail on atomic keys" do
      params = %{:foo => "bar", "password" => "should_not_show"}

      assert Params.filter(params, ["password"]) ==
               %{:foo => "bar", "password" => "[FILTERED]"}
    end
  end

  describe "filter/2 with keep strategy" do
    test "discards params not specified in params" do
      params = %{"foo" => "bar", "password" => "abc123", "file" => %Plug.Upload{}}

      assert Params.filter(params, {:keep, []}) ==
               %{"foo" => "[FILTERED]", "password" => "[FILTERED]", "file" => "[FILTERED]"}
    end

    test "keeps params that are specified in params" do
      params = %{"foo" => "bar", "password" => "abc123", "file" => %Plug.Upload{}}

      assert Params.filter(params, {:keep, ["foo", "file"]}) ==
               %{"foo" => "bar", "password" => "[FILTERED]", "file" => %Plug.Upload{}}
    end

    test "keeps all params under keys that are kept" do
      params = %{"foo" => %{"bar" => 1, "baz" => 2}}

      assert Params.filter(params, {:keep, ["foo"]}) ==
               %{"foo" => %{"bar" => 1, "baz" => 2}}
    end

    test "only filters leaf params" do
      params = %{"foo" => %{"bar" => 1, "baz" => 2}, "ids" => [1, 2]}

      assert Params.filter(params, {:keep, []}) ==
               %{
                 "foo" => %{"bar" => "[FILTERED]", "baz" => "[FILTERED]"},
                 "ids" => ["[FILTERED]", "[FILTERED]"]
               }
    end
  end
end

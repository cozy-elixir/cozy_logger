if Code.ensure_loaded?(Phoenix) do
  defmodule CozyLogger.Integrations.Phoenix.Params do
    @moduledoc false

    @doc false
    def filter(params, fields \\ [])
    def filter(params, {:discard, fields}), do: discard(params, fields)
    def filter(params, {:keep, fields}), do: keep(params, fields)
    def filter(params, fields), do: discard(params, fields)

    defp discard(%{__struct__: mod} = struct, _fields) when is_atom(mod) do
      struct
    end

    defp discard(%{} = map, fields) do
      Enum.into(map, %{}, fn {k, v} ->
        if is_binary(k) and String.contains?(k, fields) do
          {k, "[FILTERED]"}
        else
          {k, discard(v, fields)}
        end
      end)
    end

    defp discard([_ | _] = list, fields) do
      Enum.map(list, &discard(&1, fields))
    end

    defp discard(other, _fields), do: other

    defp keep(%{__struct__: mod}, _fields) when is_atom(mod), do: "[FILTERED]"

    defp keep(%{} = map, fields) do
      Enum.into(map, %{}, fn {k, v} ->
        if is_binary(k) and k in fields do
          {k, discard(v, [])}
        else
          {k, keep(v, fields)}
        end
      end)
    end

    defp keep([_ | _] = list, fields) do
      Enum.map(list, &keep(&1, fields))
    end

    defp keep(_other, _fields), do: "[FILTERED]"
  end
end

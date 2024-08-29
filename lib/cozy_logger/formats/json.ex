defmodule CozyLogger.Formats.JSON do
  @moduledoc """
  Provides utilities to format logs as JSON.
  """

  @exclude_metadata_keys [
    :logger_formatter,
    :error_logger,
    :gl,
    :pid,
    :crash_reason,
    :initial_call,
    :report_cb,
    :ansi_color,
    :conn
  ]

  alias Logger.Formatter

  @spec format(atom, term, Logger.Formatter.date_time_ms(), keyword) :: IO.chardata()
  def format(level, message, timestamp, metadata) do
    build({level, message, timestamp}, metadata)
    |> append_source()
    |> append_metadata()
    |> append_hostname()
    |> encode!(pretty: true)
    |> append_new_line()
  rescue
    # This function must not fail. If it does, it will bring that particular logger instance down,
    # causing the system to temporarily lose log messages.
    _ ->
      message = "could not format: #{inspect({level, message, metadata})}"

      build({:critical, message, timestamp}, metadata)
      |> encode!()
      |> append_new_line()
  end

  defp build({level, message, timestamp}, metadata) do
    attrs = %{
      level: level,
      message: to_binary(message),
      timestamp: to_iso8601(timestamp)
    }

    metadata = Keyword.drop(metadata, [:time])

    {attrs, metadata}
  end

  defp append_source({attrs, metadata}) do
    attrs =
      Map.put(attrs, :source, %{
        mfa: metadata[:mfa],
        file: to_binary(metadata[:file]),
        line: metadata[:line]
      })

    metadata = Keyword.drop(metadata, [:mfa, :file, :line, :module, :function])
    {attrs, metadata}
  end

  defp append_metadata({attrs, metadata}) do
    metadata = Keyword.drop(metadata, @exclude_metadata_keys)

    attrs =
      Enum.reduce(metadata, attrs, fn {key, value}, acc ->
        Map.put_new(acc, key, value)
      end)

    {attrs, metadata}
  end

  defp append_hostname({attrs, metadata}) do
    {:ok, hostname} = :inet.gethostname()
    attrs = Map.put(attrs, :hostname, to_binary(hostname))
    {attrs, metadata}
  end

  # Encoding a term to JSON.
  #
  # Uses `Jason` for the JSON encoding, but converts values that are not handled by `Jason`
  # before that, like tuples or PIDs.
  @doc false
  def encode!({attrs, _metadata}, opts \\ []) do
    attrs
    |> encode_value()
    |> Jason.encode_to_iodata!(opts)
  end

  defp encode_value(value)
       when is_pid(value) or
              is_port(value) or
              is_reference(value) or
              is_tuple(value) or
              is_function(value) do
    inspect(value)
  end

  defp encode_value(%{__struct__: _} = value) do
    value
    |> Map.from_struct()
    |> encode_value()
  end

  defp encode_value(value) when is_map(value) do
    Enum.into(value, %{}, fn {k, v} ->
      {encode_value(k), encode_value(v)}
    end)
  end

  defp encode_value(value) when is_list(value) do
    Enum.map(value, &encode_value/1)
  end

  defp encode_value(value) do
    value
  end

  defp to_iso8601({date, time}) do
    to_binary([Formatter.format_date(date), ?T, Formatter.format_time(time), ?Z])
  end

  defp to_binary(term) when is_list(term), do: :erlang.iolist_to_binary(term)
  defp to_binary(term), do: term

  defp append_new_line(iodata) do
    [iodata, ?\n]
  end
end

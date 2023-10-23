defmodule CozyLogger.JSON do
  @moduledoc """
  Formatting log messages as JSON.

  ## Usage

  Elixir v1.15 or later:

      # customize format message with this formatter.
      config :logger, :default_formatter,
        format: {#{inspect(__MODULE__)}, :format},
        truncate: :infinity,
        utc_log: true,
        metadata: :all,
        colors: [enabled: false]

  Prior to Elixir v1.15:

      # use Elixir built-in console backend, and configure other necessary options
      config :logger,
        backends: [:console],
        truncate: :infinity,
        utc_log: true

      # customize format message with this formatter.
      config :logger, :console,
        format: {#{inspect(__MODULE__)}, :format},
        metadata: :all,
        colors: [enabled: false]

  """

  @exclude_metadata_keys [
    :erl_level,
    :gl,
    :pid,
    :time,
    :crash_reason,
    :error_logger,
    :initial_call,
    :mfa,
    :report_cb,
    :ansi_color,
    :conn
  ]

  alias Logger.Formatter

  # credo:disable-for-next-line
  # TODO: remove these types when no longer supporting versions prior to v1.15
  @type date :: {1970..10_000, 1..12, 1..31}
  @type time_ms :: {0..23, 0..59, 0..59, 0..999}
  @type date_time_ms :: {date, time_ms}

  # credo:disable-for-next-line
  # TODO: replace date_time_ms with Logger.Formatter.date_time_ms() when no longer
  # supporting versions prior to v1.15
  @spec format(atom, term, date_time_ms, keyword) :: IO.chardata()
  def format(level, message, timestamp, metadata) do
    build_base_attrs(level, message, timestamp)
    |> append_source_location(metadata)
    |> append_metadata(metadata)
    |> append_hostname()
    |> exclude_keys()
    |> encode!()
    |> append_new_line()
  rescue
    # This function must not fail. If it does, it will bring that particular logger instance down,
    # causing the system to temporarily lose log messages.
    _ ->
      message = "could not format: #{inspect({level, message, metadata})}"

      build_base_attrs(:error, message, timestamp)
      |> encode!()
      |> append_new_line()
  end

  defp build_base_attrs(level, message, timestamp) do
    %{
      level: level,
      message: to_string(message),
      timestamp: format_timestamp(timestamp)
    }
  end

  defp format_timestamp({date, time}) do
    to_string([Formatter.format_date(date), ?T, Formatter.format_time(time), ?Z])
  end

  defp append_source_location(attrs, metadata) do
    Map.merge(attrs, %{
      file: metadata[:file],
      module: metadata[:module],
      function: metadata[:function],
      line: metadata[:line]
    })
  end

  defp append_metadata(attrs, metadata) do
    Enum.reduce(metadata, attrs, fn {key, value}, acc ->
      Map.put_new(acc, key, value)
    end)
  end

  defp append_hostname(attrs) do
    Map.put(attrs, :hostname, hostname())
  end

  defp hostname() do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  defp exclude_keys(attrs) do
    Map.drop(attrs, @exclude_metadata_keys)
  end

  # Encoding a term to JSON.
  #
  # Uses `Jason` for the JSON encoding, but converts values that are not handled by `Jason`
  # before that, like tuples or PIDs.
  @doc false
  def encode!(value, opts \\ []) do
    value
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

  defp append_new_line(iodata) do
    [iodata, ?\n]
  end
end

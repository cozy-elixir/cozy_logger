if Code.ensure_loaded?(Phoenix) do
  defmodule CozyLogger.Integrations.Phoenix do
    @moduledoc """
    `CozyLogger` integration for `Phoenix`.

    Phoenix uses the `:telemetry` library for instrumentation. The following events
    are published by Phoenix:

      * `[:phoenix, :endpoint, :start]`
      * `[:phoenix, :endpoint, :stop]`
      * `[:phoenix, :router_dispatch, :start]`
      * `[:phoenix, :error_rendered]`
      * `[:phoenix, :socket_connected]`
      * `[:phoenix, :channel_joined]`
      * `[:phoenix, :channel_handled_in]`
      * ...

    `Phoenix.Logger`(the default logger) handles these events, and print logs accordingly.

    ## Usage

    Before using this custom logger, you need to disable the default logger:

        config :phoenix, :logger, false

    Then, you need to attach events handlers before starting the application:

        defmodule Demo
          use Application

          def start(_type, _args) do
            unless Application.fetch_env!(:phoenix, :logger) do
              #{inspect(__MODULE__)}.install()
            end

            children = [
              # ...
            ]

            Supervisor.start_link(children, strategy: :one_for_one, name: Demo.Supervisor)
          end
        end

    ## Parameter filtering

    When logging parameters, #{inspect(__MODULE__)} can filter out sensitive parameters
    such as passwords and tokens. Parameters to be filtered can be added via the
    `:filter_params` option:

        #{inspect(__MODULE__)}.install(filter_params: ["password", "secret"])

    With the configuration above, #{inspect(__MODULE__)} will filter any parameter that
    contains the terms `password` or `secret`. The match is case sensitive.

    The default value of `:filter_params` option is `["password"]`.

    #{inspect(__MODULE__)} can also filter all parameters by default and selectively keep
    parameters. This can be configured like so:

        #{inspect(__MODULE__)}.install(filter_params: {:keep, ["id", "order"]})

    With the configuration above, #{inspect(__MODULE__)} will filter all parameters,
    except those that match exactly `id` or `order`. If a kept parameter matches,
    all parameters nested under that one will also be kept.

    ## Dynamic log level

    In some cases you may wish to set the log level dynamically on a per-request basis.

    To do so, set the `:log` option to a tuple, `{Mod, Fun, Args}`. The `Plug.Conn.t()` for the
    request will be prepended to the provided list of arguments.

    When invoked, your function must return a [`Logger.level()`](`t:Logger.level()/0`) or `false`
    to disable logging for the request.

    For example, in your Endpoint you might do something like this:

          # lib/demo_web/endpoint.ex
          plug Plug.Telemetry,
            event_prefix: [:phoenix, :endpoint],
            log: {__MODULE__, :log_level, []}

          # Disables logging for routes like /status/*
          def log_level(%{path_info: ["status" | _]}), do: false
          def log_level(_), do: :info

    ## TODO

    Currently, only the handler for `[:phoenix, :endpoint, :stop]` is implemented.

    If you need handlers for other events, feel free to contribute.

    """

    require Logger
    alias Plug.Conn
    alias __MODULE__.Params

    @events [
      [:phoenix, :endpoint, :stop]
    ]

    def install(opts \\ []) do
      config = Enum.into(opts, %{})
      :telemetry.attach_many(__MODULE__, @events, &__MODULE__.handle_event/4, config)
    end

    def uninstall do
      :telemetry.detach(__MODULE__)
    end

    @doc false
    def handle_event(
          [:phoenix, :endpoint, :stop],
          %{duration: duration},
          %{conn: conn} = metadata,
          config
        ) do
      case log_level(metadata[:options][:log], conn) do
        false ->
          :ok

        level ->
          Logger.log(
            level,
            fn ->
              [
                method(conn),
                ?\s,
                conn |> status_code() |> to_string(),
                ?\s,
                request_path(conn)
              ]
            end,
            logger_metadata(conn, config, %{duration: to_nanoseconds(duration)})
          )
      end
    end

    defp logger_metadata(conn, config, extras) do
      %{
        http: http_metadata(conn, config, extras)
      }
    end

    defp http_metadata(conn, config, extras) do
      params_filter_fields = Keyword.get(config, :filter_params, ["password"])

      %{
        connection_type: connection_type(conn),
        method: method(conn),
        scheme: conn.scheme,
        host: conn.host,
        port: conn.port,
        path: request_path(conn),
        query_string: conn.query_string,
        params: params(conn, params_filter_fields),
        status_code: status_code(conn),
        user_agent: user_agent(conn),
        referrer: referrer(conn),
        remote_ip: remote_ip(conn),
        error_reason: error_reason(conn)
      }
      |> Map.merge(extras)
    end

    defp connection_type(%Conn{state: :set_chunked}), do: "chunked"
    defp connection_type(%Conn{}), do: "sent"

    defp method(%Conn{} = conn), do: conn.method

    defp request_path(%Conn{script_name: script_name, path_info: path_info})
         when is_list(script_name) do
      "/" <> Enum.join(script_name ++ path_info, "/")
    end

    defp request_path(%Conn{request_path: request_path}), do: request_path

    defp params(%Conn{params: %Conn.Unfetched{}}, _fields), do: "[UNFETCHED]"

    defp params(%Conn{} = conn, fields),
      do: conn.params |> Params.filter(fields) |> inspect()

    defp status_code(%Conn{} = conn), do: conn.status

    defp user_agent(%Conn{} = conn), do: get_header(conn, "user-agent")

    defp referrer(%Conn{} = conn), do: get_header(conn, "referer")

    defp remote_ip(%Conn{} = conn) do
      if header_value = get_header(conn, "x-forwarded-for") do
        header_value
        |> String.split(",", parts: 2)
        |> hd()
        |> String.trim()
      else
        conn.remote_ip
        |> :inet_parse.ntoa()
        |> to_string()
      end
    end

    defp error_reason(%Conn{assigns: %{kind: kind, reason: reason, stack: stacktrace}}) do
      Exception.format(kind, reason, stacktrace)
    end

    defp error_reason(%Conn{}), do: nil

    defp to_nanoseconds(duration) do
      System.convert_time_unit(duration, :native, :nanosecond)
    end

    defp get_header(%Conn{} = conn, header) do
      case Conn.get_req_header(conn, header) do
        [] -> nil
        [val | _] -> val
      end
    end

    defp log_level(nil, _conn), do: :info
    defp log_level(level, _conn) when is_atom(level), do: level

    defp log_level({mod, fun, args}, conn) when is_atom(mod) and is_atom(fun) and is_list(args) do
      apply(mod, fun, [conn | args])
    end
  end
end

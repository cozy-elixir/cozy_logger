import Config

elixir_version_current = System.version()
elixir_version_with_new_logger = "1.15.0"
is_old_elixir? = Version.compare(elixir_version_current, elixir_version_with_new_logger) == :lt

if is_old_elixir? do
  # use Elixir built-in console backend
  config :logger, backends: [:console]

  # use log formatter provided by CozyLogger
  config :logger, :console,
    format: {CozyLogger.JsonFormatter, :format},
    metadata: :all,
    colors: [enabled: false],
    utc_log: true
else
  config :logger, :default_formatter,
    format: {CozyLogger.JsonFormatter, :format},
    metadata: :all,
    colors: [enabled: false],
    utc_log: true
end

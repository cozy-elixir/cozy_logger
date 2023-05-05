import Config

if Mix.env() == :test do
  # use Elixir built-in console backend
  config :logger, backends: [:console]

  # use log formatter provided by CozyLogger
  config :logger, :console,
    format: {CozyLogger.JsonFormatter, :format},
    metadata: :all,
    colors: [enabled: false]
end

import Config

config :logger, :default_formatter,
  format: {CozyLogger.JSON, :format},
  truncate: :infinity,
  utc_log: true,
  metadata: :all,
  colors: [enabled: false]

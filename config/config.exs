import Config

config :logger,
  handle_otp_reports: true

config :logger, :default_formatter,
  format: {CozyLogger.Formats, :json},
  truncate: :infinity,
  utc_log: true,
  metadata: :all,
  colors: [enabled: false]

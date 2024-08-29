defmodule CozyLogger.Formats do
  @moduledoc """
  Provides format functions for logger.

  ## Usage

      # configure the default formatter
      config :logger, :default_formatter,
        format: {#{inspect(__MODULE__)}, :json},
        truncate: :infinity,
        utc_log: true,
        metadata: :all,
        colors: [enabled: false]

  """

  alias CozyLogger.Formats.JSON

  defdelegate json(level, message, timestamp, metadata), to: JSON, as: :format
end

if Code.ensure_loaded?(Oban) do
  defmodule CozyLogger.Integrations.Oban do
    @moduledoc """
    `CozyLogger` integration for `Oban`.

    ## Usage

    You need to attach events handlers before starting the application:

        defmodule Demo
          use Application

          def start(_type, _args) do
            :ok = #{inspect(__MODULE__)}.install()

            children = [
              # ...
            ]

            Supervisor.start_link(children, strategy: :one_for_one, name: Demo.Supervisor)
          end
        end

    ## TODO

    Currently, only the handler for `[:oban, :job, :exception]` is implemented.

    If you need handlers for other events, feel free to contribute.

    """

    require Logger

    @events [
      [:oban, :job, :exception]
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
          [:oban, :job, :exception],
          measurements,
          metadata,
          _config
        ) do
      %{kind: kind, reason: reason, stacktrace: stacktrace} = metadata
      message = Exception.format(kind, reason, stacktrace)

      Logger.log(:error, message, %{oban_job: oban_job_metadata(measurements, metadata)})
    end

    defp oban_job_metadata(measurements, metadata) do
      queue_time = measurements.queue_time
      duration = measurements.duration

      job = metadata.job
      state = metadata[:state]

      %{
        args: job.args,
        attempt: job.attempt,
        id: job.id,
        priority: job.priority,
        queue: job.queue,
        worker: job.worker,
        state: state,
        queue_time: queue_time,
        duration: duration
      }
    end
  end
end

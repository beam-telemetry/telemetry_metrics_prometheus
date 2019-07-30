defmodule TelemetryMetricsPrometheus do
  @moduledoc """
  Prometheus Reporter for [`Telemetry.Metrics`](https://github.com/beam-telemetry/telemetry_metrics) definitions.

  Provide a list of metric definitions to the `init/2` function. It's recommended to
  run TelemetryMetricsPrometheus under a supervision tree, usually under Application.

      def start(_type, _args) do
        # List all child processes to be supervised
        children = [
          {TelemetryMetricsPrometheus, [metrics: metrics()]}
        ...
        ]

        opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
        Supervisor.start_link(children, opts)
      end

      defp metrics, do:
        [
          counter("http.request.count"),
          sum("http.request.payload_size", unit: :byte),
          last_value("vm.memory.total", unit: :byte)
        ]

  By default, metrics are exposed on port `9568` at `/metrics`. The port number
  can be configured if necessary. You are not required to use the included server,
  though it is recommended. `https` is not supported yet, in which case the
  `TelemetryMetricsPrometheus.Core` library should be used instead. The
  `TelemetryMetricsPrometheus.Core.scrape/1` function will expose the metrics in
  the Prometheus text format.

  Please see the `TelemetryMetricsPrometheus.Core` docs for information on metric
  types and units.
  """

  require Logger

  @type option ::
          TelemetryMetricsPrometheus.Core.prometheus_option()
          | {:port, pos_integer()}
          | {:metrics, TelemetryMetricsPrometheus.Core.metrics()}

  @type options :: [option]

  @doc """
  Reporter's child spec.

  This function allows you to start the reporter under a supervisor like this:

      children = [
        {TelemetryMetricsPrometheus, options}
      ]


  See `start_link/1` for a list of available options.

  Returns a child specification to supervise the process.
  """
  @spec child_spec(options()) :: Supervisor.child_spec()
  def child_spec(options) do
    opts = ensure_options(options)

    id =
      case Keyword.get(opts, :name, :prometheus_metrics) do
        name when is_atom(name) -> name
        {:global, name} -> name
        {:via, _, name} -> name
      end

    spec = %{
      id: id,
      start: {TelemetryMetricsPrometheus.Supervisor, :start_link, [opts]}
    }

    Supervisor.child_spec(spec, [])
  end

  @doc """
  Starts a reporter and links it to the calling process.

  Available options:
  * `:metrics` - a list of `Telemetry.Metrics` definitions to monitor. **required**
  * `:name` - the name to set the process's id to. Defaults to `:prometheus_metrics`
  * `:port` - port number for the reporter instance's server. Defaults to `9568`

  All other options are forwarded to `TelemetryMetricsPrometheus.Core.init/2`.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    ensure_options(options)
    |> TelemetryMetricsPrometheus.Supervisor.start_link()
  end

  defp ensure_options(options) do
    Keyword.merge(default_options(), options)
  end

  @spec default_options() :: options()
  defp default_options() do
    [port: 9568, protocol: :http, name: :prometheus_metrics]
  end
end

defmodule TelemetryMetricsPrometheus do
  @moduledoc """
  Prometheus Reporter for [`Telemetry.Metrics`](https://github.com/beam-telemetry/telemetry_metrics) definitions.

  Provide a list of metric definitions to the `init/2` function. It's recommended to
  initialize the reporter during application startup.

      def start(_type, _args) do
        TelemetryMetricsPrometheus.init([
          counter("http.request.count"),
          sum("http.request.payload_size", unit: :byte),
          last_value("vm.memory.total", unit: :byte)
        ])

        # List all child processes to be supervised
        children = [
        ...
        ]

        opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
        Supervisor.start_link(children, opts)
      end

  By default, metrics are exposed on port `9568` at `/metrics`. The port number
  can be configured if necessary. You are not required to use the included server,
  though it is recommended. `https` is not supported yet, in which case the
  `TelemetryMetricsPrometheus.Core` library should be used instead. The
  `TelemetryMetricsPrometheus.Core.scrape/1` function will expose the metrics in
  the Prometheus text format.

  Please see the `TelemetryMetricsPrometheus.Core` docs for information on metric
  types and units.
  """

  alias TelemetryMetricsPrometheus.Router

  require Logger

  @type metrics :: [TelemetryMetricsPrometheus.Core.metric()]

  @type prometheus_options :: [
          server_option() | TelemetryMetricsPrometheus.Core.prometheus_option()
        ]
  @type server_options :: [server_option()]
  @type server_option :: {:port, pos_integer()}
  @typep server_protocol :: :http | :https

  @doc """
  Initializes a reporter instance with the provided `Telemetry.Metrics` definitions.

  Available options:
  * `:port` - port number for the reporter instance's server. Defaults to `9568`

  All other options are forwarded to `TelemetryMetricsPrometheus.Core.init/2`.
  """
  @spec init(metrics(), prometheus_options()) :: :ok
  def init(metrics, options \\ []) when is_list(metrics) and is_list(options) do
    opts = Keyword.merge(default_options(), options)
    name = Keyword.get(options, :name, :prometheus_metrics)

    with :ok <- TelemetryMetricsPrometheus.Core.init(metrics, options),
         {:ok, _server} <- init_server(name, opts[:protocol], opts[:port]) do
      :ok
    end
  end

  @doc false
  def stop(_name) do
    # Stop everything for now. This can be refined later.
    DynamicSupervisor.which_children(__MODULE__.DynamicSupervisor)
    |> Enum.map(fn {:undefined, pid, _, _} ->
      DynamicSupervisor.terminate_child(__MODULE__.DynamicSupervisor, pid)
    end)
  end

  @spec default_options() :: server_options()
  defp default_options() do
    [port: 9568, protocol: :http]
  end

  @spec init_server(atom(), server_protocol(), pos_integer()) ::
          DynamicSupervisor.on_start_child()
  defp init_server(name, scheme, port) do
    DynamicSupervisor.start_child(
      __MODULE__.DynamicSupervisor,
      {Plug.Cowboy, scheme: scheme, plug: {Router, [name: name]}, options: [port: port]}
    )
  end
end

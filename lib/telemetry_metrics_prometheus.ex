defmodule TelemetryMetricsPrometheus do
  @exporter_plug_schema [
    protocol: [
      type: :atom,
      default: :http,
      doc: "http or https protocol."
    ],

    port: [
      type: :non_neg_integer,
      default: 9568,
      doc: "port to expose the prometheus exporter on."
    ]
  ]

  @exporter_config_schema [
    enabled?: [
      type: :boolean,
      default: false,
      doc: "is exporter enabled."
    ],

    opts: [
      type: :keyword_list,
      default: [],
      keys: @exporter_plug_schema,
      doc: "options for the ExporterPlug with following keys:"
    ]
  ]

  @opts_schema [
    name: [
      type: :atom,
      default: :prometheus_telemetry_supervisor,
      doc: "supervisor name, no need to manually change this most of the time."
    ],

    exporter: [
      type: :keyword_list,
      default: [],
      keys: @exporter_config_schema,
      doc: "exporter config with following keys:"
    ],

    metrics: [
      type: {:list, :any},
      required: true,
      doc: "metrics list, flattened so you can have nested layers of metrics."
    ],

    pre_scrape_handler: [
      type: :mfa,
      default: {__MODULE__, :default_pre_scrape_handler, []},
      doc: "mfa to run before the exporter executes the metrics scraping to render."
    ]
  ]


  @moduledoc """
  Prometheus Reporter for [`Telemetry.Metrics`](https://github.com/beam-telemetry/telemetry_metrics) definitions.

  Provide a list of metric definitions to the `init/2` function. It's recommended to
  run TelemetryMetricsPrometheus under a supervision tree, usually under Application.

      def start(_type, _args) do
        # List all child processes to be supervised
        children = [
          {TelemetryMetricsPrometheus, metrics: metrics()}
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

  ## Enabling the exporter

      def start(_type, _args) do
        # List all child processes to be supervised
        children = [
          {TelemetryMetricsPrometheus,
            exporter: [enabled?: true],
            metrics: [MyModule.metrics(), MyOtherModule.metrics()]
          }
        ...
        ]

        opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
        Supervisor.start_link(children, opts)
      end

  ## Umbrella Application Support
  To utilize this in umbrella applications where some
  applications may be support applications and others
  may be entrypoints which are hosted on nodes you can either
  start this supervisor with or without the exporter.

  Under a typical setup each supporting library would have it's own
  `TelemetryMetricsPrometheus` with it's own metrics, while the
  entrypoint applications that are deployed to a node would utilize
  `TelemetryMetricsPrometheus` with `exporter: [enabled?: true]`.

  When utilized in multiple applications `TelemetryMetricsPrometheus`
  will only start once but will start adding child processes
  for every additional time it's started, it will also setup a link
  between the currently running supervisor and calling application.
  When scraping the `TelemetryMetricsPrometheus` with an enabled exporter
  will scrape the rest of the `TelemetryMetricsPrometheus`s running
  to fetch the metrics for each one and display it.

  This means under a typical setup you may see applications with

      children = [{TelemetryMetricsPrometheus, metrics: [...]}]

  while the server applications will contain

      children = [{TelemetryMetricsPrometheus,
        exporter: [enabled?: true],
        metrics: [...]
      }]

  ## Telemetry Events

  * `[:prometheus_metrics, :plug, :stop]` - invoked at the end of every scrape. The
  measurement returned is `:duration` and the metadata is the `conn` map for the call.

  A suggested Distribution definition might look like:

      Metrics.distribution("prometheus_metrics.scrape.duration.milliseconds",
        reporter_options: [buckets: [0.05, 0.1, 0.2, 0.5, 1]],
        description: "A histogram of the request duration for prometheus metrics scrape.",
        event_name: [:prometheus_metrics, :plug, :stop],
        measurement: :duration,
        tags: [:name],
        tag_values: fn %{conn: conn} ->
          %{name: conn.private[:prometheus_metrics_name]}
        end,
        unit: {:native, :millisecond}
      )

  ## Options
  #{NimbleOptions.docs(@opts_schema)}
  """

  require Logger

  alias TelemetryMetricsPrometheus.MetricsSupervisor

  @type option ::
          TelemetryMetricsPrometheus.Core.prometheus_option()
          | {:port, pos_integer()}
          | {:metrics, TelemetryMetricsPrometheus.Core.metrics()}
          | {:protocol, :http | :https}
          | {:plug_cowboy_opts, Keyword.t()}
          | {:pre_scrape_handler, mfa()}

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
  defdelegate child_spec(opts), to: MetricsSupervisor

  @doc """
  Starts a reporter and links it to the calling process.

  Available options:
  #{NimbleOptions.docs(@opts_schema)}
  """

  def validate_opts(opts), do: NimbleOptions.validate!(opts, @opts_schema)

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    options
      |> NimbleOptions.validate!(@opts_schema)
      |> MetricsSupervisor.start_link()
  end

  @spec default_pre_scrape_handler() :: :ok
  def default_pre_scrape_handler, do: :ok
end

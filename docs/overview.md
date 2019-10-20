# Overview

TelemetryMetricsPrometheus is a [Telemetry.Metrics Reporter](https://hexdocs.pm/telemetry_metrics/overview.html#reporters) for aggregating and exposing [Prometheus](https://prometheus.io) metrics based on `Telemetry.Metrics` definitions. 

The reporter runs as a standalone application and provides its own web server. This
makes it very simple to instrument your project, regardless of your project type! Let
us know how you're using it.

## Getting Started

Once you have the package added to your dependencies, you can start 
TelemetryMetricsPrometheus by initiating the application during
your application startup.

```elixir
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

```

By default, metrics are exposed on port `9568` at `/metrics`. The port number
can be configured if necessary. You are not required to use the included server,
though it is recommended. `https` is not supported yet, in which case exposing
a `/metrics` endpoint and calling the `scrape/1` function is your best option
until TLS is supported.

Note that aggregations for distributions (histogram) only occur at scrape time.
These aggregations only have to process events that have occurred since the last
scrape, so it's recommended at this time to keep an eye on scrape durations if
you're reporting a large number of disributions or you have a high tag cardinality.

## Core library

Please see https://github.com/beam-telemetry/telemetry_metrics_prometheus_core/blob/master/docs/overview.md for documentation of the core that powers this library.

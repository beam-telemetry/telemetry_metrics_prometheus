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
  TelemetryMetricsPrometheus.init([])
  
  # List all child processes to be supervised
  children = [
    ...
  ]

  opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

There are a few metrics built into `TelemetryMetricsPrometheus` to 
monitor resource usage by the reporter and measure scrape processing time.

To see it in action, fire up your application in your terminal `iex -S mix`.
Open another terminal and curl the endpoint a few times to see the output.

```
 $ curl http://localhost:9568/metrics
# HELP prometheus_metrics_table_size_total A gauge of the key count of a prometheus metrics aggregation table
# TYPE prometheus_metrics_table_size_total gauge
prometheus_metrics_table_size_total{name="prometheus_metrics_dist"} 1
prometheus_metrics_table_size_total{name="prometheus_metrics"} 4

# HELP prometheus_metrics_table_memory_bytes A gauge of the memory size of a prometheus metrics aggregation table
# TYPE prometheus_metrics_table_memory_bytes gauge
prometheus_metrics_table_memory_bytes{name="prometheus_metrics_dist"} 1356
prometheus_metrics_table_memory_bytes{name="prometheus_metrics"} 1426

# HELP prometheus_metrics_scrape_duration_seconds A histogram of the request duration for prometheus metrics scrape.
# TYPE prometheus_metrics_scrape_duration_seconds histogram
prometheus_metrics_scrape_duration_seconds_bucket{name="prometheus_metrics",le="0.05"} 1
prometheus_metrics_scrape_duration_seconds_bucket{name="prometheus_metrics",le="0.1"} 1
prometheus_metrics_scrape_duration_seconds_bucket{name="prometheus_metrics",le="0.2"} 1
prometheus_metrics_scrape_duration_seconds_bucket{name="prometheus_metrics",le="0.5"} 1
prometheus_metrics_scrape_duration_seconds_bucket{name="prometheus_metrics",le="1"} 1
prometheus_metrics_scrape_duration_seconds_bucket{name="prometheus_metrics",le="+Inf"} 1
prometheus_metrics_scrape_duration_seconds_sum{name="prometheus_metrics"} 0.00213792
prometheus_metrics_scrape_duration_seconds_count{name="prometheus_metrics"} 1
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

Please see https://github.com/bryannaegele/telemetry_metrics_prometheus_core/blob/master/docs/overview.md for documentation of the core that powers this library.

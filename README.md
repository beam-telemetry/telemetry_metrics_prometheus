# TelemetryMetricsPrometheus

[![CircleCI](https://circleci.com/gh/bryannaegele/telemetry_metrics_prometheus/tree/master.svg?style=svg)](https://circleci.com/gh/bryannaegele/telemetry_metrics_prometheus/tree/master) [![codecov](https://codecov.io/gh/bryannaegele/telemetry_metrics_prometheus/branch/master/graph/badge.svg?token=ZukGAUDLwH)](https://codecov.io/gh/bryannaegele/telemetry_metrics_prometheus)

TelemetryMetricsPrometheus is a [Telemetry.Metrics Reporter](https://hexdocs.pm/telemetry_metrics/overview.html#reporters) for aggregating and exposing [Prometheus](https://prometheus.io) metrics based on `Telemetry.Metrics` definitions. TelemetryMetricsPrometheus provides a server out of the box exposing a `/metrics` endpoint, making setup a breeze.

## Is this the right Prometheus package for me?

If you want to take advantage of consuming `:telemetry` events with the ease of 
defining and managing metrics `Telemetry.Metrics` brings for Prometheus, then yes! 
This package provides a simple and straightforward way to aggregate and report 
Prometheus metrics. Whether you're using [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/) servers, [Datadog](https://docs.datadoghq.com/integrations/prometheus/), 
or any other monitoring solution which supports scraping, you're in luck!

If you're not interested in taking advantage of `Telemetry.Metrics` but still 
want to implement Prometheus or use `:telemetry` in your project, have a look at 
something like the [OpenCensus](https://github.com/opencensus-beam) project and 
see if it better meets your needs.

## Installation

The package can be installed by adding `telemetry_metrics_prometheus` to your 
list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telemetry_metrics_prometheus, "~> 0.2"}
  ]
end
```

See the documentation on [Hexdocs](https://hexdocs.pm/telemetry_metrics_prometheus) for more information.


## Contributing

Contributors are highly welcome! 

Additional documentation and tests, TLS support, and benchmarking are all needed. 

Please open an issue for discussion before undertaking anything non-trivial before
jumping in and submitting a PR.


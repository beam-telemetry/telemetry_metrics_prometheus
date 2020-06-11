# Changelog

## v0.6.0

### Changes

  * [BREAKING] - Updates Core which supports Telemetry.Metrics v0.5 which includes
    a breaking change

## v0.5.0

### Changes

  * Minimum Elixir version now 1.7 for Plug support
  * Core update
  
### Fixes

  * Re-enabled multiple instance support broken after Core split

## v0.4.0

### Changes

  * Bumps TelemetryMetricsPrometheus.Core to v0.3

## v0.3.1

### Fixes

  * Passes the name to the router, fixing broken scrapes (thanks to @kbredemeier)
  
## v0.3.0

### Changes

  * The core functionality of TelemetryMetricsPrometheus has been split to its own
  package [TelemetryMetricsPrometheus.Core](https://github.com/beam-telemetry/telemetry_metrics_prometheus_core) for users with more advanced needs while keeping this package as an out-of-the-box solution. This was not a breaking change, however...
  * TelemetryMetricsPrometheus is no longer a standalone application and should be run
  under a supervision tree, typically under Application. See the [docs](https://hexdocs.pm/telemetry_metrics_prometheus/TelemetryMetricsPrometheus.html#start_link/1) for details.
  * Metrics are now passed as a required option in your child spec. These and any other
  options are passed down to Core to keep things simple.

## v0.2.0

### Enhancements

  * Add validations consistent with Prometheus client library guidelines. 
  Note: these can be turned off individually or turn off all validations. 
  See the [docs](https://hexdocs.pm/telemetry_metrics_prometheus/TelemetryMetricsPrometheus.html#init/2) for details.
  
### Changes

  * Update to Telemetry.Metrics v0.3. Note: Summary metrics will continue
  to be unsupported at this time.
  * Reporter monitoring metrics can now be optionally turned on and off.
  The default is off.

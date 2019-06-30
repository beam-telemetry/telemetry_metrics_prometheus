# Changelog

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

defmodule TelemetryMetricsPrometheusTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias Telemetry.Metrics

  test "has a child spec" do
    child_spec = TelemetryMetricsPrometheus.child_spec(metrics: [])

    assert child_spec == %{
             id: :prometheus_metrics,
             start:
               {TelemetryMetricsPrometheus.Supervisor, :start_link,
                [
                  [
                    port: 9568,
                    protocol: :http,
                    name: :prometheus_metrics,
                    metrics: []
                  ]
                ]}
           }

    assert %{id: :my_metrics} =
             TelemetryMetricsPrometheus.child_spec(name: :my_metrics, metrics: [])

    assert %{id: :global_metrics} =
             TelemetryMetricsPrometheus.child_spec(name: {:global, :global_metrics}, metrics: [])

    assert %{id: :via_metrics} =
             TelemetryMetricsPrometheus.child_spec(
               name: {:via, :example, :via_metrics},
               metrics: []
             )
  end

  test "initializes properly" do
    metrics = [
      Metrics.counter("http.request.total",
        event_name: [:http, :request, :stop],
        tags: [:method, :code],
        description: "The total number of HTTP requests."
      )
    ]

    opts = [metrics: metrics, name: :test_reporter, validations: [require_seconds: false]]

    _pid = start_supervised!({TelemetryMetricsPrometheus, opts})

    Process.sleep(10)

    assert :ets.info(:test_reporter) != :undefined
    assert :ets.info(:test_reporter_dist) != :undefined

    :telemetry.execute([:http, :request, :stop], %{duration: 300_000_000}, %{
      method: "get",
      code: 200
    })

    metrics_scrape = TelemetryMetricsPrometheus.Core.scrape(:test_reporter)

    assert metrics_scrape =~ "http_request_total"
  end

  test "initializes properly using start_link/1" do
    metrics = [
      Metrics.counter("http.request.total",
        event_name: [:http, :request, :stop],
        tags: [:method, :code],
        description: "The total number of HTTP requests."
      )
    ]

    opts = [metrics: metrics, name: :test_reporter, validations: [require_seconds: false]]

    _pid = start_supervised!({TelemetryMetricsPrometheus, opts})

    Process.sleep(10)

    assert :ets.info(:test_reporter) != :undefined
    assert :ets.info(:test_reporter_dist) != :undefined

    :telemetry.execute([:http, :request, :stop], %{duration: 300_000_000}, %{
      method: "get",
      code: 200
    })

    metrics_scrape = TelemetryMetricsPrometheus.Core.scrape(:test_reporter)

    assert metrics_scrape =~ "http_request_total"
  end

  test "logs an error for unsupported metric types" do
    metrics = [
      Metrics.summary("http.request.duration")
    ]

    assert capture_log(fn ->
             opts = [metrics: metrics, validations: false]
             _pid = start_supervised!({TelemetryMetricsPrometheus, opts})
             Process.sleep(10)
           end) =~ "Metric type summary is unsupported."
  end
end

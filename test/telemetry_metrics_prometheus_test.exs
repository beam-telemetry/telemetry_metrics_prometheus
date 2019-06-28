defmodule TelemetryMetricsPrometheusTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  import TelemetryMetricsPrometheus, only: [init: 2, scrape: 1, stop: 1]
  alias Telemetry.Metrics

  test "initializes properly" do
    metrics = [
      Metrics.counter("http.request.total",
        event_name: [:http, :request, :stop],
        tags: [:method, :code],
        description: "The total number of HTTP requests."
      )
    ]

    opts = [name: :test_reporter, validations: false]
    :ok = init(metrics, opts)

    assert :ets.info(:test_reporter) != :undefined
    assert :ets.info(:test_reporter_dist) != :undefined

    :telemetry.execute([:http, :request, :stop], %{duration: 300_000_000}, %{
      method: "get",
      code: 200
    })

    metrics_scrape = scrape(:test_reporter)

    assert metrics_scrape =~ "http_request_total"

    stop(:test_reporter)
  end

  test "logs an error for unsupported metric types" do
    metrics = [
      Metrics.summary("http.request.duration")
    ]

    assert capture_log(fn ->
             opts = [name: :test_reporter, validations: false]
             :ok = init(metrics, opts)
           end) =~ "Metric type summary is unsupported."

    stop(:test_reporter)
  end

  test "supports monitoring the health of the reporter itself" do
    :ok = init([], name: :test_reporter, monitor_reporter: true, validations: false)
    children = DynamicSupervisor.which_children(TelemetryMetricsPrometheus.DynamicSupervisor)

    assert Enum.any?(children, &match?({_, _, :worker, [:telemetry_poller]}, &1))
    stop(:test_reporter)
  end

  test "reporter health monitoring is off by default" do
    :ok = init([], name: :test_reporter, validations: false)
    children = DynamicSupervisor.which_children(TelemetryMetricsPrometheus.DynamicSupervisor)

    refute Enum.any?(children, &match?({_, _, :worker, [:telemetry_poller]}, &1))
    stop(:test_reporter)
  end
end

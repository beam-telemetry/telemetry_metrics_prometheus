defmodule TelemetryMetricsPrometheusTest do
  use ExUnit.Case
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

    opts = [name: :test_reporter]
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
end

defmodule TelemetryMetricsPrometheus.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Telemetry.Metrics
  alias TelemetryMetricsPrometheus.Router

  test "returns a 404 for a non-matching route" do
    # Create a test connection
    conn = conn(:get, "/missing")

    _pid =
      start_supervised!(
        {TelemetryMetricsPrometheus, [metrics: [], port: 9999, validations: false]}
      )

    Process.sleep(10)

    # Invoke the plug
    conn = Router.call(conn, Router.init(name: :prometheus_metrics))

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 404
  end

  test "returns a scrape" do
    # Create a test connection
    conn = conn(:get, "/metrics")

    _pid =
      start_supervised!(
        {TelemetryMetricsPrometheus,
         [
           metrics: [
             Metrics.counter("http.request.total",
               event_name: [:http, :request, :stop],
               tags: [:method, :code],
               description: "The total number of HTTP requests."
             )
           ],
           name: :test,
           port: 9999,
           validations: false,
           monitor_router: true
         ]}
      )

    Process.sleep(10)

    :telemetry.execute([:http, :request, :stop], %{duration: 300_000_000}, %{
      method: "get",
      code: 200
    })

    # Invoke the plug
    conn = Router.call(conn, Router.init(name: :test))

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body =~ "http_request_total"
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/plain"
  end

  test "calls the configured pre-scrape" do
    # Create a test connection
    conn = conn(:get, "/metrics")
    test_pid = self()

    _pid =
      start_supervised!(
        {TelemetryMetricsPrometheus,
         [
           metrics: [
             Metrics.counter("http.request.total",
               event_name: [:http, :request, :stop],
               tags: [:method, :code],
               description: "The total number of HTTP requests."
             )
           ],
           name: :test,
           port: 9999,
           validations: false,
           monitor_router: true,
           pre_scrape: fn -> send(test_pid, :invoked) end
         ]}
      )

    Process.sleep(10)

    :telemetry.execute([:http, :request, :stop], %{duration: 300_000_000}, %{
      method: "get",
      code: 200
    })

    # Invoke the plug
    conn =
      Router.call(conn, Router.init(name: :test, pre_scrape: fn ->  send(test_pid, :invoked) end))

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body =~ "http_request_total"
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/plain"

    assert_receive :invoked
  end
end

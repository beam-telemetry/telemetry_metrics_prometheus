defmodule TelemetryMetricsPrometheus.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias TelemetryMetricsPrometheus.Router

  @opts Router.init(name: :test)

  test "returns a 404 for a non-matching route" do
    # Create a test connection
    conn = conn(:get, "/missing")

    # Invoke the plug
    conn = Router.call(conn, @opts)

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 404
  end

  test "returns a scrape" do
    # Create a test connection
    conn = conn(:get, "/metrics")

    TelemetryMetricsPrometheus.init([], [name: :test, port: 9999])

    # Invoke the plug
    conn = Router.call(conn, Router.init(name: :test))

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/plain"

    TelemetryMetricsPrometheus.stop(:test)
  end
end

defmodule TelemetryMetricsPrometheus.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias TelemetryMetricsPrometheus.Router

  setup do
    on_exit(fn -> stop(:test) end)
  end

  test "returns a 404 for a non-matching route" do
    # Create a test connection
    conn = conn(:get, "/missing")

    TelemetryMetricsPrometheus.init([], name: :test, port: 9999, validations: false)

    # Invoke the plug
    conn = Router.call(conn, Router.init(name: :test))

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 404
  end

  test "returns a scrape" do
    # Create a test connection
    conn = conn(:get, "/metrics")

    TelemetryMetricsPrometheus.init([], name: :test, port: 9999, validations: false)

    # Invoke the plug
    conn = Router.call(conn, Router.init(name: :test))

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/plain"
  end

  defp stop(name) do
    TelemetryMetricsPrometheus.stop(name)
    TelemetryMetricsPrometheus.Core.stop(name)
  end
end

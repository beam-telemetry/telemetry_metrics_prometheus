defmodule TelemetryMetricsPrometheus.Router do
  @moduledoc false

  use Plug.Router

  plug :match
  plug Plug.Telemetry, event_prefix: [:prometheus_metrics, :plug]
  plug :dispatch, builder_opts()

  get "/metrics" do
    TelemetryMetricsPrometheus.Plug.call(conn, opts)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end

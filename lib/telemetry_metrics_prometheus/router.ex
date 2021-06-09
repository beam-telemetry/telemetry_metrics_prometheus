defmodule TelemetryMetricsPrometheus.Router do
  @moduledoc false

  use Plug.Router
  alias Plug.Conn

  plug(:match)
  plug(Plug.Telemetry, event_prefix: [:prometheus_metrics, :plug])
  plug(:dispatch, builder_opts())

  get "/metrics" do
    name = opts[:name]
    pre_scrape = opts[:pre_scrape]
    unless is_nil(pre_scrape), do: pre_scrape.()
    metrics = TelemetryMetricsPrometheus.Core.scrape(name)

    conn
    |> Conn.put_private(:prometheus_metrics_name, name)
    |> Conn.put_resp_content_type("text/plain")
    |> Conn.send_resp(200, metrics)
  end

  match _ do
    Conn.send_resp(conn, 404, "Not Found")
  end
end

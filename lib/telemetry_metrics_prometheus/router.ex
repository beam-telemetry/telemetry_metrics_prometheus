defmodule TelemetryMetricsPrometheus.Router do
  @moduledoc false

  use Plug.Router
  alias Plug.Conn

  plug(:match)
  plug(Plug.Telemetry, event_prefix: [:prometheus_metrics, :plug])
  plug(:dispatch, builder_opts())

  get "/metrics" do
    name = opts[:name]

    execute_pre_scrape_handler(opts[:pre_scrape_handler])
    metrics = TelemetryMetricsPrometheus.Core.scrape(name)

    conn
    |> Conn.put_private(:prometheus_metrics_name, name)
    |> Conn.put_resp_content_type("text/plain")
    |> Conn.send_resp(200, metrics)
  end

  match _ do
    Conn.send_resp(conn, 404, "Not Found")
  end

  defp execute_pre_scrape_handler({m, f, a}), do: apply(m, f, a)
end

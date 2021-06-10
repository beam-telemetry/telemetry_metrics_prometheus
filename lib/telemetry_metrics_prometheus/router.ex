defmodule TelemetryMetricsPrometheus.Router do
  @moduledoc false

  use Plug.Router
  alias Plug.Conn

  plug(:match)
  plug(Plug.Telemetry, event_prefix: [:prometheus_metrics, :plug])
  plug(:dispatch, builder_opts())

  get "/metrics" do
    name = opts[:name]

    {pre_scrape_module, pre_scrape_function, pre_scrape_args} =
      Keyword.get(opts, :pre_scrape, {__MODULE__, :default_pre_scrape, []})

    apply(pre_scrape_module, pre_scrape_function, pre_scrape_args)
    metrics = TelemetryMetricsPrometheus.Core.scrape(name)

    conn
    |> Conn.put_private(:prometheus_metrics_name, name)
    |> Conn.put_resp_content_type("text/plain")
    |> Conn.send_resp(200, metrics)
  end

  match _ do
    Conn.send_resp(conn, 404, "Not Found")
  end

  def default_pre_scrape(), do: :ok
end

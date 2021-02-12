defmodule TelemetryMetricsPrometheus.Plug do
  @moduledoc """
  Plug to export Prometheus metrics.
  """

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts) do
    opts |> Keyword.put_new(:name, :prometheus_metrics)
  end

  @impl Plug
  def call(conn, opts) do
    name = Keyword.fetch!(opts, :name)

    metrics = TelemetryMetricsPrometheus.Core.scrape(name)

    conn
    |> put_private(:prometheus_metrics_name, name)
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end
end

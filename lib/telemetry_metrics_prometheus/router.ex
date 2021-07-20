defmodule TelemetryMetricsPrometheus.Router do
  @moduledoc """
  Router for exporting prometheus metrics
  """

  use Plug.Router

  alias TelemetryMetricsPrometheus.MetricsSupervisor

  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]

  plug :match
  plug Plug.Telemetry, event_prefix: [:prometheus_metrics, :plug]
  plug :dispatch, builder_opts()

  get "/metrics" do
    execute_pre_scrape_handler(opts[:pre_scrape_handler])

    metrics = fetch_metrics()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  def execute_pre_scrape_handler({mod, func, args}), do: apply(mod, func, args)
  def execute_pre_scrape_handler(_), do: nil

  def fetch_metrics do
    MetricsSupervisor.list()
      |> Stream.map(fn supervisor ->
        supervisor
          |> Supervisor.which_children
          |> Enum.find_value(&prometheus_core?/1)
      end)
      |> Stream.map(&scrape/1)
      |> Enum.reduce("", &(&2 <> &1))
  end

  defp prometheus_core?({metrics_core_name, _, _, [TelemetryMetricsPrometheus.Core.Registry]}), do: metrics_core_name
  defp prometheus_core?(_), do: false

  defp scrape(nil), do: ""
  defp scrape(name), do: TelemetryMetricsPrometheus.Core.scrape(name)
end


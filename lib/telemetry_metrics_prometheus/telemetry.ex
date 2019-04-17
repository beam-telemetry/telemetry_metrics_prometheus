defmodule TelemetryMetricsPrometheus.Telemetry do
  @moduledoc false

  def dispatch_table_stats(table) do
    info = :ets.info(table)

    measurements = %{memory: info[:memory], size: info[:size]}
    metadata = Map.new(info) |> Map.drop([:memory, :size])

    :telemetry.execute([:telemetry_metrics_prometheus, :table, :status], measurements, metadata)
  end
end

defmodule TelemetryMetricsPrometheus.Distribution do
  @moduledoc false

  alias Telemetry.Metrics
  alias TelemetryMetricsPrometheus
  alias TelemetryMetricsPrometheus.EventHandler

  @type config :: %{
          measurement: Metrics.measurement(),
          metric_name: String.t(),
          name: Metrics.normalized_metric_name(),
          table: atom(),
          tags: Metrics.tags(),
          tag_values_fun: Metrics.tag_values(),
          type: :histogram,
          unit: Metrics.unit()
        }

  @spec register(metric :: Metrics.Distribution.t(), table_id :: atom(), owner :: pid()) ::
          {:ok, :telemetry.handler_id()} | {:error, :already_exists}

  def register(metric, table_id, owner) do
    handler_id = EventHandler.handler_id(metric.name, owner)

    with :ok <-
           :telemetry.attach(
             handler_id,
             metric.event_name,
             &handle_event/4,
             %{
               measurement: metric.measurement,
               metric_name: "",
               name: metric.name,
               table: table_id,
               tags: metric.tags,
               tag_values_fun: metric.tag_values,
               type: :histogram,
               unit: metric.unit
             }
           ) do
      {:ok, handler_id}
    else
      {:error, :already_exists} = error ->
        error
    end
  end

  @spec handle_event(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          config()
        ) :: :ok
  def handle_event(_event, measurements, metadata, config) do
    with {:ok, measurement} <- EventHandler.get_measurement(measurements, config.measurement),
         mapped_values <- config.tag_values_fun.(metadata),
         :ok <- EventHandler.validate_tags_in_tag_values(config.tags, mapped_values),
         labels <- Map.take(mapped_values, config.tags) do
      true = :ets.insert(config.table, {config.name, {labels, measurement}})

      :ok
    else
      error -> EventHandler.handle_event_error(error, config)
    end
  end
end

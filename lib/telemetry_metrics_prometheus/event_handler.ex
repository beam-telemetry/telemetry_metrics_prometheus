defmodule TelemetryMetricsPrometheus.EventHandler do
  @moduledoc false

  alias Telemetry.Metrics
  alias TelemetryMetricsPrometheus.{Counter, Distribution, LastValue, Sum}
  @typep measurement_not_found_error :: {:measurement_not_found, atom()}
  @typep measurement_parse_error :: {:measurement_parse_error, term}
  @typep tags_missing_error :: {:tags_missing, [atom()]}
  @typep event_config ::
           Counter.config() | Distribution.config() | LastValue.config() | Sum.config()

  @typep event_error ::
           measurement_not_found_error | measurement_parse_error | tags_missing_error()

  require Logger

  @spec handler_id(name :: Metrics.normalized_metric_name(), reporter :: pid) ::
          :telemetry.handler_id()
  def handler_id(name, reporter) do
    {__MODULE__, reporter, name}
  end

  @spec validate_tags_in_tag_values(Telemetry.Metrics.tags(), map()) :: :ok | tags_missing_error()
  def validate_tags_in_tag_values(tags, tag_values) do
    case Enum.reject(tags, &match?(%{^&1 => _}, tag_values)) do
      [] -> :ok
      missing_tags -> {:tags_missing, missing_tags}
    end
  end

  @spec get_measurement(:telemetry.event_measurements(), atom()) ::
          {:ok, number()} | measurement_not_found_error() | measurement_parse_error()
  def get_measurement(measurements, measurement) when is_atom(measurement) do
    case Map.fetch(measurements, measurement) do
      :error -> {:measurement_not_found, measurement}
      {:ok, value} -> parse_measurement(value)
    end
  end

  def get_measurement(measurements, measurement), do: {:ok, measurement.(measurements)}

  # Not sure if we should be handling this. Should reporters be responsible for bad actors?
  @spec parse_measurement(term) :: {:ok, number()} | no_return()
  def parse_measurement(measurement) when is_number(measurement), do: {:ok, measurement}
  def parse_measurement(term), do: {:measurement_parse_error, term}

  @spec handle_event_error(event_error(), event_config) :: no_return()
  def handle_event_error({:measurement_not_found, measurement}, config) do
    raise ArgumentError,
          "Measurement not found, expected: #{measurement}. Detaching handler. metric_name:=#{
            inspect(config.name)
          }"
  end

  def handle_event_error({:measurement_parse_error, term}, config) do
    raise ArgumentError,
          "Expected measurement to be a number, got: #{inspect(term)}. Detaching handler. metric_name:=#{
            inspect(config.name)
          }"
  end

  def handle_event_error({:tags_missing, tags}, config) do
    raise ArgumentError,
          "Tags missing from tag_values. Detaching handler. metric_name:=#{inspect(config.name)} tags:=#{
            inspect(Enum.join(tags))
          }"
  end
end

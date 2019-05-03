defmodule TelemetryMetricsPrometheus.Exporter do
  @moduledoc false
  alias Telemetry.Metrics.{Counter, Distribution, LastValue, Sum}

  def export(time_series, definitions) do
    definitions
    |> Stream.map(fn %{name: name} = metric ->
      case time_series[name] do
        nil -> nil
        ts -> format(metric, ts)
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  def format(%Counter{} = metric, time_series) do
    format_standard({metric, time_series}, "counter")
  end

  def format(%LastValue{} = metric, time_series) do
    format_standard({metric, time_series}, "gauge")
  end

  def format(%Sum{} = metric, time_series) do
    format_standard({metric, time_series}, "counter")
  end

  def format(%Distribution{} = metric, time_series) do
    Enum.map(time_series, fn ts ->
      format_disribution(metric, ts)
    end)
    |> Enum.join("\n")
  end

  def format_disribution(metric, {{_, labels}, {buckets, count, sum}}) do
    name = format_name(metric.name)
    help = "# HELP #{name} #{metric.description}"
    type = "# TYPE #{name} histogram"

    has_labels = map_size(labels) > 0

    samples =
      Enum.map_join(buckets, "\n", fn {upper_bound, count} ->
        if has_labels do
          ~s(#{name}_bucket{#{format_labels(labels)},le="#{upper_bound}"} #{count})
        else
          ~s(#{name}_bucket{le="#{upper_bound}"} #{count})
        end
      end)

    summary =
      if has_labels do
        "#{name}_sum{#{format_labels(labels)}} #{sum}\n#{name}_count{#{format_labels(labels)}} #{
          count
        }"
      else
        "#{name}_sum #{sum}\n#{name}_count #{count}"
      end

    Enum.join([help, type, samples, summary], "\n")
  end

  defp format_standard({metric, time_series}, type) do
    name = format_name(metric.name)
    help = "# HELP #{name} #{metric.description}"
    type = "# TYPE #{name} #{type}"

    samples =
      Enum.map_join(time_series, "\n", fn {{_, labels}, val} ->
        has_labels = map_size(labels) > 0

        if has_labels do
          "#{name}{#{format_labels(labels)}} #{val}"
        else
          "#{name} #{val}"
        end
      end)

    Enum.join([help, type, samples], "\n")
  end

  defp format_labels(labels) do
    labels
    |> Enum.map(fn {k, v} -> ~s(#{k}="#{v}") end)
    |> Enum.sort()
    |> Enum.join(",")
  end

  defp format_name(name) do
    name
    |> Enum.join("_")
    |> String.replace(~r/[^a-zA-Z_][^a-zA-Z0-9_]*/, "")
  end
end

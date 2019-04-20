defmodule TelemetryMetricsPrometheus.Exporter do
  @moduledoc false
  alias Telemetry.Metrics.{Counter, Distribution, LastValue, Sum}

  def export(time_series, definitions, common_labels) do
    definitions
    |> Stream.map(fn %{name: name} = metric ->
      case time_series[name] do
        nil -> nil
        ts -> format(metric, ts, common_labels)
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  def format(%Counter{} = metric, time_series, common_labels) do
    format_standard({metric, time_series}, common_labels, "counter")
  end

  def format(%LastValue{} = metric, time_series, common_labels) do
    format_standard({metric, time_series}, common_labels, "gauge")
  end

  def format(%Sum{} = metric, time_series, common_labels) do
    format_standard({metric, time_series}, common_labels, "counter")
  end

  def format(%Distribution{} = metric, time_series, common_labels) do
    Enum.map(time_series, fn ts ->
      format_disribution(metric, ts, common_labels)
    end)
    |> Enum.join("\n")
  end

  def format_disribution(metric, {{_, agg_labels}, {buckets, count, sum}}, common_labels) do
    name = format_name(metric.name)
    help = "# HELP #{name} #{metric.description}"
    type = "# TYPE #{name} histogram"

    labels = Enum.into(common_labels, agg_labels)
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

  defp format_standard({metric, time_series}, common_labels, type) do
    name = format_name(metric.name)
    help = "# HELP #{name} #{metric.description}"
    type = "# TYPE #{name} #{type}"

    samples =
      Enum.map_join(time_series, "\n", fn {{_, agg_labels}, agg_val} ->
        labels = Enum.into(common_labels, agg_labels)
        has_labels = map_size(labels) > 0

        if has_labels do
          "#{name}{#{format_labels(labels)}} #{agg_val}"
        else
          "#{name} #{agg_val}"
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

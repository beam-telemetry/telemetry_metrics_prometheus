defmodule TelemetryMetricsPrometheus.MetricsSupervisor do
  @moduledoc false

  use Supervisor

  @telemetry_supervisor_postfix "prometheus_telemetry_supervisor_#{Enum.random(1..100_000_000_000)}"

  def list do
    Enum.filter(Process.registered(), &String.ends_with?(to_string(&1), @telemetry_supervisor_postfix))
  end

  def start_link(opts \\ []) do
    opts = Keyword.update!(opts, :name, &:"#{&1}_#{Enum.random(1..100_000_000_000)}")

    params = %{
      name: opts[:name],
      enable_exporter?: opts[:exporter][:enabled?],
      exporter_opts: opts[:exporter][:opts],
      metrics: opts[:metrics]
    }

    opts = Keyword.update!(opts, :name, &(:"#{&1}_#{@telemetry_supervisor_postfix}"))

    with {:error, {:already_started, pid}} <- Supervisor.start_link(TelemetryMetricsPrometheus.MetricsSupervisor, params, opts) do
      opts[:name]
        |> create_metrics_child(params.metrics)
        |> Kernel.++(create_exporter_child(params))
        |> Enum.map(&Supervisor.start_child(opts[:name], &1))

      {:ok, pid}
    end
  end

  @impl true
  def init(%{
    name: name,
    metrics: metrics,
    enable_exporter?: enable_exporter?,
    exporter_opts: exporter_opts
  }) do
    children = create_metrics_child(name, metrics)

    children = if enable_exporter? do
      create_exporter_child(exporter_opts) ++ children
    else
      children
    end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp create_exporter_child(opts) do
    [TelemetryMetricsPrometheus.ExporterPlug.child_spec(opts)]
  end

  defp create_metrics_child(name, [_ | _] = metrics) do
    [{TelemetryMetricsPrometheus.Core, metrics: List.flatten(metrics), name: :"#{name}_metrics_watcher"}]
  end

  defp create_metrics_child(_, _) do
    []
  end
end

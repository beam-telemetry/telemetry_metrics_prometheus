defmodule TelemetryMetricsPrometheus.RegistryTest do
  use ExUnit.Case

  alias Telemetry.Metrics
  alias TelemetryMetricsPrometheus.Registry

  setup do
    definitions = [
      Metrics.counter("http.request.count"),
      Metrics.distribution("some.plug.call.duration", buckets: [0, 1, 2]),
      Metrics.last_value("vm.memory.total"),
      Metrics.sum("cache.invalidations.total")
    ]

    %{definitions: definitions}
  end

  test "registers each metric type", %{definitions: definitions} do
    {:ok, pid} = Registry.start_link(name: :test)

    Enum.each(definitions, fn definition ->
      result = Registry.register(definition, :test)
      assert(result == :ok)
    end)

    cleanup(pid)
  end

  test "returns an error for duplicate events", %{definitions: definitions} do
    {:ok, pid} = Registry.start_link(name: :test)

    Enum.each(definitions, fn definition ->
      result = Registry.register(definition, :test)
      assert(result == :ok)
    end)

    Enum.each(definitions, fn definition ->
      result = Registry.register(definition, :test)
      assert(result == {:error, :already_exists, definition.name})
    end)

    cleanup(pid)
  end

  test "retrieves the config" do
    {:ok, pid} = Registry.start_link(name: :test)
    config = Registry.config(:test)

    assert Map.has_key?(config, :aggregates_table_id)
    assert Map.has_key?(config, :dist_table_id)

    cleanup(pid)
  end

  test "retrieves the registered metrics", %{definitions: definitions} do
    {:ok, pid} = Registry.start_link(name: :test)

    Enum.each(definitions, fn definition ->
      Registry.register(definition, :test)
    end)

    metrics = Registry.metrics(:test)

    Enum.each(metrics, fn
      %Metrics.Counter{} -> assert true
      %Metrics.Distribution{} -> assert true
      %Metrics.LastValue{} -> assert true
      %Metrics.Sum{} -> assert true
      _ -> flunk("non-metric returned")
    end)

    cleanup(pid)
  end

  defp cleanup(pid) do
    GenServer.stop(pid)

    :telemetry.list_handlers([])
    |> Enum.each(&:telemetry.detach(&1.id))
  end
end

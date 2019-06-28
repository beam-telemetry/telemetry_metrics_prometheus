defmodule TelemetryMetricsPrometheus.RegistryTest do
  use ExUnit.Case

  alias Telemetry.Metrics
  alias TelemetryMetricsPrometheus.Registry

  import ExUnit.CaptureLog

  setup do
    definitions = [
      Metrics.counter("http.request.count"),
      Metrics.distribution("some.plug.call.duration", buckets: [0, 1, 2]),
      Metrics.last_value("vm.memory.total"),
      Metrics.sum("cache.invalidations.total"),
      Metrics.summary("http.request.duration")
    ]

    opts = [name: :test]

    %{definitions: definitions, opts: opts}
  end

  test "registers each supported metric type", %{definitions: definitions, opts: opts} do
    {:ok, _pid} = start_supervised({Registry, opts})

    definitions
    |> Enum.each(fn definition ->
      result = Registry.register(definition, :test)

      if match?(%Metrics.Summary{}, definition) do
        assert(result == {:error, :unsupported_metric_type, :summary})
      else
        assert(result == :ok)
      end
    end)

    cleanup()
  end

  test "returns an error for duplicate events", %{definitions: definitions, opts: opts} do
    {:ok, _pid} = start_supervised({Registry, opts})

    supported_defs = Enum.reject(definitions, &match?(%Metrics.Summary{}, &1))

    Enum.each(supported_defs, fn definition ->
      result = Registry.register(definition, :test)
      assert(result == :ok)
    end)

    Enum.each(supported_defs, fn definition ->
      result = Registry.register(definition, :test)
      assert(result == {:error, :already_exists, definition.name})
    end)

    cleanup()
  end

  test "validates for units" do
    metrics = [
      Metrics.distribution("some.plug.call.duration",
        buckets: [0, 1, 2],
        unit: {:microsecond, :millisecond}
      ),
      Metrics.distribution("some_other.plug.call.duration",
        buckets: [0, 1, 2],
        unit: {:microsecond, :second}
      ),
      Metrics.distribution("some_third.plug.call.duration", buckets: [0, 1, 2], unit: :millisecond),
      Metrics.counter("http.request.count", unit: :byte)
    ]

    assert capture_log(fn ->
             Registry.validate_units(metrics,
               consistent_units: true,
               require_seconds: false
             )
           end) =~ "Multiple time units found"

    assert capture_log(fn ->
             Registry.validate_units(metrics,
               consistent_units: false,
               require_seconds: true
             )
           end) =~ "Prometheus requires that time units MUST only be offered in seconds"
  end

  test "retrieves the config", %{opts: opts} do
    {:ok, _pid} = start_supervised({Registry, opts})
    config = Registry.config(:test)

    assert Map.has_key?(config, :aggregates_table_id)
    assert Map.has_key?(config, :dist_table_id)

    cleanup()
  end

  test "retrieves the registered metrics", %{definitions: definitions, opts: opts} do
    {:ok, _pid} = start_supervised({Registry, opts})

    supported_defs = Enum.reject(definitions, &match?(%Metrics.Summary{}, &1))

    Enum.each(supported_defs, fn definition ->
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

    cleanup()
  end

  defp cleanup() do
    :telemetry.list_handlers([])
    |> Enum.each(&:telemetry.detach(&1.id))
  end
end

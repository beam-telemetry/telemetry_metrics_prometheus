defmodule TelemetryMetricsPrometheus.AggregatorTest do
  use ExUnit.Case

  alias TelemetryMetricsPrometheus.Aggregator

  setup do
    tid = :ets.new(:test_table, [:named_table, :public, :set, {:write_concurrency, true}])

    dist_tid =
      :ets.new(:test_dist_table, [
        :named_table,
        :public,
        :duplicate_bag,
        {:write_concurrency, true}
      ])

    %{tid: tid, dist_tid: dist_tid}
  end

  describe "bucket_measurements/2" do
    test "measurements are properly bucketed" do
      [
        {[1, 2, 3, "+Inf"], [], {[{"1", 0}, {"2", 0}, {"3", 0}, {"+Inf", 0}], 0, 0},
         "with no measurements"},
        {[1, 2, 3, "+Inf"], [0.1], {[{"1", 1}, {"2", 1}, {"3", 1}, {"+Inf", 1}], 1, 0.1},
         "with one measurement"},
        {[1, 2, 3, "+Inf"], [2, 3.1], {[{"1", 0}, {"2", 1}, {"3", 1}, {"+Inf", 2}], 2, 5.1},
         "compares measurement to bucket limit correctly"},
        {[1, 2, 3, "+Inf"], [4, 5], {[{"1", 0}, {"2", 0}, {"3", 0}, {"+Inf", 2}], 2, 9},
         "with measurements over the bucket limits"}
      ]
      |> Enum.each(fn {buckets, measurements, expected_buckets, message} ->
        result = Aggregator.bucket_measurements(measurements, buckets)
        assert(result == expected_buckets, message)
      end)
    end
  end

  describe "aggregate/3" do
    test "stores an aggregation in the aggregates table and combines on subsequent aggregations",
         %{tid: tid, dist_tid: dist_tid} do
      buckets = [
        1,
        2,
        3
      ]

      metric =
        Telemetry.Metrics.distribution("some.plug.call.duration",
          buckets: buckets,
          description: "Plug call duration",
          event_name: [:some, :plug, :call, :stop],
          measurement: :duration,
          unit: {:native, :second},
          tags: [:method, :path_root],
          tag_values: fn %{conn: conn} ->
            %{
              method: conn.method,
              path_root: List.first(conn.path_info) || ""
            }
          end
        )

      metric = %{metric | buckets: metric.buckets ++ ["+Inf"]}

      {:ok, _handler_id} =
        TelemetryMetricsPrometheus.Distribution.register(metric, dist_tid, self())

      :telemetry.execute([:some, :plug, :call, :stop], %{duration: 3_000_000_000}, %{
        conn: %{method: "GET", path_info: ["users", "123"]}
      })

      :telemetry.execute([:some, :plug, :call, :stop], %{duration: 3_000_000_000}, %{
        conn: %{method: "GET", path_info: ["users", "123"]}
      })

      :ok = Aggregator.aggregate([metric], tid, dist_tid)

      [
        {{[:some, :plug, :call, :duration], %{method: "GET", path_root: "users"}},
         {bucketed, count, sum}}
      ] = :ets.tab2list(tid)

      assert bucketed == [{"1", 0}, {"2", 0}, {"3", 2}, {"+Inf", 2}]
      assert count == 2
      assert sum == 6.0

      :telemetry.execute([:some, :plug, :call, :stop], %{duration: 1_500_000_000}, %{
        conn: %{method: "GET", path_info: ["users", "123"]}
      })

      :telemetry.execute([:some, :plug, :call, :stop], %{duration: 0_800_000_000}, %{
        conn: %{method: "GET", path_info: ["users", "123"]}
      })

      :ok = Aggregator.aggregate([metric], tid, dist_tid)

      [
        {{[:some, :plug, :call, :duration], %{method: "GET", path_root: "users"}},
         {bucketed_2, count_2, sum_2}}
      ] = :ets.tab2list(tid)

      assert bucketed_2 == [{"1", 1}, {"2", 2}, {"3", 4}, {"+Inf", 4}]
      assert count_2 == 4
      assert sum_2 == 8.3

      cleanup(tid)
      cleanup(dist_tid)
    end
  end

  def cleanup(tid) do
    :ets.delete_all_objects(tid)

    :telemetry.list_handlers([])
    |> Enum.each(&:telemetry.detach(&1.id))
  end

  def fetch_metric(table_id, key) do
    case :ets.lookup(table_id, key) do
      [result] -> result
      _ -> :error
    end
  end
end

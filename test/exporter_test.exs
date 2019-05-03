defmodule TelemetryMetricsPrometheus.ExporterTest do
  use ExUnit.Case
  alias Telemetry.Metrics
  alias TelemetryMetricsPrometheus.Exporter

  describe "format/2" do
    test "counter with tags" do
      expected = """
      # HELP http_request_total The total number of HTTP requests.
      # TYPE http_request_total counter
      http_request_total{code="200",method="post"} 1027
      http_request_total{code="400",method="post"} 3\
      """

      metric =
        Metrics.counter("http.request.total",
          tags: ["method", "code"],
          description: "The total number of HTTP requests."
        )

      time_series = [
        {{[:http, :request, :total], %{"method" => "post", "code" => "200"}}, 1027},
        {{[:http, :request, :total], %{"method" => "post", "code" => "400"}}, 3}
      ]

      result = Exporter.format(metric, time_series)

      assert result == expected
    end

    test "counter without tags" do
      expected = """
      # HELP http_request_total The total number of HTTP requests.
      # TYPE http_request_total counter
      http_request_total 1027\
      """

      metric =
        Metrics.counter("http.request.total",
          description: "The total number of HTTP requests."
        )

      time_series = [
        {{[:http, :request, :total], %{}}, 1027}
      ]

      result = Exporter.format(metric, time_series)

      assert result == expected
    end

    test "last value with tags" do
      expected = """
      # HELP cache_keys_total The total number of cache keys.
      # TYPE cache_keys_total gauge
      cache_keys_total{name="users"} 1027
      cache_keys_total{name="short_urls"} 3\
      """

      metric =
        Metrics.last_value("cache.keys.total",
          tags: ["name"],
          description: "The total number of cache keys."
        )

      time_series = [
        {{[:cache, :keys, :total], %{"name" => "users"}}, 1027},
        {{[:cache, :keys, :total], %{"name" => "short_urls"}}, 3}
      ]

      result = Exporter.format(metric, time_series)

      assert result == expected
    end

    test "last value without tags" do
      expected = """
      # HELP cache_key_total The total number of cache keys.
      # TYPE cache_key_total gauge
      cache_key_total 1027\
      """

      metric =
        Metrics.last_value("cache.key.total",
          description: "The total number of cache keys."
        )

      time_series = [
        {{[:cache, :key, :total], %{}}, 1027}
      ]

      result = Exporter.format(metric, time_series)

      assert result == expected
    end

    test "sum with tags" do
      expected = """
      # HELP cache_key_invalidations_total The total number of cache key invalidations.
      # TYPE cache_key_invalidations_total counter
      cache_key_invalidations_total{name="users"} 1027
      cache_key_invalidations_total{name="short_urls"} 3\
      """

      metric =
        Metrics.sum("cache.key.invalidations.total",
          tags: ["name"],
          description: "The total number of cache key invalidations."
        )

      time_series = [
        {{[:cache, :key, :invalidations, :total], %{"name" => "users"}}, 1027},
        {{[:cache, :key, :invalidations, :total], %{"name" => "short_urls"}}, 3}
      ]

      result = Exporter.format(metric, time_series)

      assert result == expected
    end

    test "sum without tags" do
      expected = """
      # HELP cache_key_invalidations_total The total number of cache key invalidations.
      # TYPE cache_key_invalidations_total counter
      cache_key_invalidations_total 1027\
      """

      metric =
        Metrics.sum("cache.key.invalidations.total",
          description: "The total number of cache key invalidations."
        )

      time_series = [
        {{[:cache, :key, :invalidations, :total], %{}}, 1027}
      ]

      result = Exporter.format(metric, time_series)

      assert result == expected
    end

    test "distribution with tags" do
      expected = """
      # HELP http_request_duration_seconds A histogram of the request duration.
      # TYPE http_request_duration_seconds histogram
      http_request_duration_seconds_bucket{method="GET",le="0.05"} 24054
      http_request_duration_seconds_bucket{method="GET",le="0.1"} 33444
      http_request_duration_seconds_bucket{method="GET",le="0.2"} 100392
      http_request_duration_seconds_bucket{method="GET",le="0.5"} 129389
      http_request_duration_seconds_bucket{method="GET",le="1"} 133988
      http_request_duration_seconds_bucket{method="GET",le="+Inf"} 144320
      http_request_duration_seconds_sum{method="GET"} 53423
      http_request_duration_seconds_count{method="GET"} 144320\
      """

      metric =
        Metrics.distribution("http.request.duration.seconds",
          buckets: [0.05, 0.1, 0.2, 0.5, 1],
          tags: ["method"],
          description: "A histogram of the request duration.",
          unit: {:native, :second}
        )

      buckets = [
        {"0.05", 24054},
        {"0.1", 33444},
        {"0.2", 100_392},
        {"0.5", 129_389},
        {"1", 133_988},
        {"+Inf", 144_320}
      ]

      result =
        Exporter.format(
          metric,
          [{{metric.name, %{"method" => "GET"}}, {buckets, 144_320, 53423}}]
        )

      assert result == expected
    end

    test "distribution without tags" do
      expected = """
      # HELP http_request_duration_seconds A histogram of the request duration.
      # TYPE http_request_duration_seconds histogram
      http_request_duration_seconds_bucket{le="0.05"} 24054
      http_request_duration_seconds_bucket{le="0.1"} 33444
      http_request_duration_seconds_bucket{le="0.2"} 100392
      http_request_duration_seconds_bucket{le="0.5"} 129389
      http_request_duration_seconds_bucket{le="1"} 133988
      http_request_duration_seconds_bucket{le="+Inf"} 144320
      http_request_duration_seconds_sum 53423
      http_request_duration_seconds_count 144320\
      """

      metric =
        Metrics.distribution("http.request.duration.seconds",
          buckets: [0.05, 0.1, 0.2, 0.5, 1],
          description: "A histogram of the request duration.",
          unit: {:native, :second}
        )

      buckets = [
        {"0.05", 24054},
        {"0.1", 33444},
        {"0.2", 100_392},
        {"0.5", 129_389},
        {"1", 133_988},
        {"+Inf", 144_320}
      ]

      result = Exporter.format(metric, [{{metric.name, %{}}, {buckets, 144_320, 53423}}])

      assert result == expected
    end
  end
end

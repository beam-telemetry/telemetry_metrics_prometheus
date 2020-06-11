defmodule TelemetryMetricsPrometheus.MixProject do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :telemetry_metrics_prometheus,
      version: @version,
      elixir: "~> 1.7",
      preferred_cli_env: preferred_cli_env(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev, :docs]},
      {:excoveralls, "~> 0.12", only: :test, runtime: false},
      {:plug_cowboy, "~> 2.1"},
      {:telemetry_metrics_prometheus_core, "~> 0.4"}
    ]
  end

  defp docs do
    [
      main: "TelemetryMetricsPrometheus",
      source_url: "https://github.com/beam-telemetry/telemetry_metrics_prometheus",
      source_ref: "v#{@version}",
      extras: [
        "docs/overview.md",
        "docs/rationale.md"
      ]
    ]
  end

  defp preferred_cli_env do
    [
      docs: :docs,
      dialyzer: :test,
      "coveralls.json": :test
    ]
  end

  defp description do
    """
    Provides a Prometheus format reporter and server for Telemetry.Metrics definitions.
    """
  end

  defp package do
    [
      maintainers: ["Bryan Naegele"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/beam-telemetry/telemetry_metrics_prometheus"}
    ]
  end
end

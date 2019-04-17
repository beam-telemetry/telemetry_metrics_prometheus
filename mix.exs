defmodule TelemetryMetricsPrometheus.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :telemetry_metrics_prometheus,
      version: @version,
      elixir: "~> 1.6",
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
      extra_applications: [:logger],
      mod: {TelemetryMetricsPrometheus.Application, []}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.20.1", only: [:dev, :docs]},
      {:excoveralls, "~> 0.10.6", only: :test, runtime: false},
      {:plug_cowboy, "~> 2.0"},
      {:telemetry, "~> 0.4.0"},
      {:telemetry_metrics, "~> 0.2.1"},
      {:telemetry_poller, "~> 0.3.0"}
    ]
  end

  defp docs do
    [
      main: "overview",
      canonical: "http://hexdocs.pm/telemetry_metrics_prometheus",
      source_url: "https://github.com/bryannaegele/telemetry_metrics_prometheus",
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
      links: %{"GitHub" => "https://github.com/bryannaegele/telemetry_metrics_prometheus"}
    ]
  end
end

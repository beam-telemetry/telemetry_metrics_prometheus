defmodule TelemetryMetricsPrometheus.Supervisor do
  use Supervisor

  alias TelemetryMetricsPrometheus.Router

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    children = [
      {TelemetryMetricsPrometheus.Core, args},
      {Plug.Cowboy,
       scheme: Keyword.get(args, :protocol),
       plug: Router,
       options: [port: Keyword.get(args, :port)]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

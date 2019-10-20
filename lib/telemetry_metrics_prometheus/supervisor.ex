defmodule TelemetryMetricsPrometheus.Supervisor do
  @moduledoc false
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
       plug: {Router, [name: Keyword.get(args, :name)]},
       options: Keyword.get(args, :options)}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule TelemetryMetricsPrometheus.Supervisor do
  @moduledoc false
  use Supervisor

  alias TelemetryMetricsPrometheus.Router

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: :"#{init_args[:name]}_sup")
  end

  @impl true
  def init(args) do
    children = [
      {TelemetryMetricsPrometheus.Core, args},
      Plug.Cowboy.child_spec(
        scheme: Keyword.get(args, :protocol),
        plug:
          {Router,
           [
             name: Keyword.get(args, :name),
             pre_scrape: Keyword.get(args, :pre_scrape)
           ]},
        options: Keyword.get(args, :options)
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

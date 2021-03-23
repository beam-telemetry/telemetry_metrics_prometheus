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
        plug: {Router, [name: Keyword.get(args, :name)]},
        options:
          case Keyword.fetch(:name) do
            {:ok, name} ->
              args
              |> Keyword.get(:options)
              |> Keyword.put_new(:ref, name)
            :error ->
              Keyword.get(args, :options)
          end
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

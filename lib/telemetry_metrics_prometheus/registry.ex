defmodule TelemetryMetricsPrometheus.Registry do
  @moduledoc false
  use GenServer

  @type name :: atom()
  @type metric_exists_error() :: {:error, :already_exists, TelemetryMetricsPrometheus.metric()}
  @type unsupported_metric_type_error() :: {:error, :unsupported_metric_type, :summary}
  @type validation_opts() :: [consistent_units: bool(), require_seconds: bool()]

  require Logger

  alias Telemetry.Metrics
  alias TelemetryMetricsPrometheus.{Counter, Distribution, LastValue, Sum}

  # metric_name should be the validated and normalized prometheus
  # name - https://prometheus.io/docs/instrumenting/writing_exporters/#naming

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def init(opts) do
    name = opts[:name]
    aggregates_table_id = create_table(name, :set)
    dist_table_id = create_table(String.to_atom("#{name}_dist"), :duplicate_bag)

    {:ok,
     %{
       config: %{aggregates_table_id: aggregates_table_id, dist_table_id: dist_table_id},
       metrics: []
     }}
  end

  @spec register(TelemetryMetricsPrometheus.metric(), atom()) ::
          :ok | metric_exists_error() | unsupported_metric_type_error()
  def register(metric, name \\ __MODULE__) do
    # validate metrics units ?

    GenServer.call(name, {:register, metric})
  end

  @spec validate_units(TelemetryMetricsPrometheus.metrics(), validation_opts()) ::
          TelemetryMetricsPrometheus.metrics()
  def validate_units(metrics, opts) do
    time_units =
      metrics
      |> Enum.filter(&match?(%Metrics.Distribution{}, &1))
      |> Enum.reduce(MapSet.new([]), fn
        %{unit: {_from, to}}, acc -> MapSet.put(acc, to)
        %{unit: unit}, acc when is_atom(unit) -> MapSet.put(acc, unit)
      end)
      |> MapSet.to_list()

    validate_consistent_units(time_units, opts[:consistent_units])
    validate_units_seconds(time_units, opts[:require_seconds])

    metrics
  end

  @spec validate_consistent_units([Metrics.time_unit()], bool()) :: :ok
  defp validate_consistent_units(_, false), do: :ok

  defp validate_consistent_units(units, true) when length(units) > 1 do
    Logger.warn(
      "Multiple time units found in your Telemetry.Metrics definitions.\n\nPrometheus recommends using consistent time units to make view creation simpler.\n\nYou can disable this validation check by adding `consistent_units: false` in the validations options on reporter init."
    )

    :ok
  end

  defp validate_consistent_units(_units, _), do: :ok

  @spec validate_units_seconds([Metrics.time_unit()], bool()) :: :ok
  defp validate_units_seconds(_, false), do: :ok
  defp validate_units_seconds([:second], _), do: :ok
  defp validate_units_seconds([], _), do: :ok

  defp validate_units_seconds(_, _) do
    Logger.warn(
      "Prometheus requires that time units MUST only be offered in seconds according to their guidelines, though this is not always practical.\n\nhttps://prometheus.io/docs/instrumenting/writing_clientlibs/#histogram.\n\nYou can disable this validation check by adding `require_seconds: false` in the validations options on reporter init."
    )

    :ok
  end

  @spec config(name()) :: %{aggregates_table_id: atom(), dist_table_id: atom()}
  def config(name) do
    GenServer.call(name, :get_config)
  end

  @spec metrics(name()) :: [{TelemetryMetricsPrometheus.metric(), :telemetry.handler_id()}]
  def metrics(name) do
    GenServer.call(name, :get_metrics)
  end

  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end

  def handle_call(:get_metrics, _from, state) do
    metrics = Enum.map(state.metrics, &elem(&1, 0))
    {:reply, metrics, state}
  end

  @impl true
  @spec handle_call({:register, TelemetryMetricsPrometheus.metric()}, GenServer.from(), map()) ::
          {:reply, :ok, map()}
          | {:reply, metric_exists_error() | unsupported_metric_type_error(), map()}

  def handle_call({:register, %Metrics.Counter{} = metric}, _from, state) do
    with {:ok, handler_id} <- Counter.register(metric, state.config.aggregates_table_id, self()) do
      {:reply, :ok, %{state | metrics: [{metric, handler_id} | state.metrics]}}
    else
      {:error, :already_exists} -> {:reply, {:error, :already_exists, metric.name}, state}
    end
  end

  def handle_call({:register, %Metrics.LastValue{} = metric}, _from, state) do
    with {:ok, handler_id} <- LastValue.register(metric, state.config.aggregates_table_id, self()) do
      {:reply, :ok, %{state | metrics: [{metric, handler_id} | state.metrics]}}
    else
      {:error, :already_exists} -> {:reply, {:error, :already_exists, metric.name}, state}
    end
  end

  def handle_call({:register, %Metrics.Sum{} = metric}, _from, state) do
    with {:ok, handler_id} <- Sum.register(metric, state.config.aggregates_table_id, self()) do
      {:reply, :ok, %{state | metrics: [{metric, handler_id} | state.metrics]}}
    else
      {:error, :already_exists} -> {:reply, {:error, :already_exists, metric.name}, state}
    end
  end

  def handle_call({:register, %Metrics.Distribution{} = metric}, _from, state) do
    with {:ok, handler_id} <- Distribution.register(metric, state.config.dist_table_id, self()) do
      {:reply, :ok,
       %{
         state
         | metrics: [
             {%{metric | buckets: metric.buckets ++ ["+Inf"]}, handler_id} | state.metrics
           ]
       }}
    else
      {:error, :already_exists} -> {:reply, {:error, :already_exists, metric.name}, state}
    end
  end

  def handle_call({:register, %Metrics.Summary{} = _metric}, _from, state) do
    {:reply, {:error, :unsupported_metric_type, :summary}, state}
  end

  @spec create_table(name :: atom, type :: atom) :: :ets.tid() | atom
  defp create_table(name, type) do
    :ets.new(name, [:named_table, :public, type, {:write_concurrency, true}])
  end

  @spec monitor_tables([atom()], atom()) :: DynamicSupervisor.on_start_child()
  def monitor_tables(tables, name) do
    measurement_specs =
      Enum.map(tables, &{TelemetryMetricsPrometheus.Telemetry, :dispatch_table_stats, [&1]})

    DynamicSupervisor.start_child(
      TelemetryMetricsPrometheus.DynamicSupervisor,
      {:telemetry_poller,
       [measurements: measurement_specs, name: String.to_atom("#{name}_poller")]}
    )
  end
end

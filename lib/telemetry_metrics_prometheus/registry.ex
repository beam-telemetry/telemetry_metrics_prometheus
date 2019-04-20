defmodule TelemetryMetricsPrometheus.Registry do
  @moduledoc false
  use GenServer

  @type name :: atom()

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
       common_tag_values: opts[:common_tag_values],
       config: %{aggregates_table_id: aggregates_table_id, dist_table_id: dist_table_id},
       metrics: []
     }}
  end

  @spec register(TelemetryMetricsPrometheus.metric(), atom()) :: :ok | {:error, :already_exists}
  def register(metric, name \\ __MODULE__) do
    # validate metrics units ?

    GenServer.call(name, {:register, metric})
  end

  @spec common_tag_values(name()) :: TelemetryMetricsPrometheus.common_tag_values()
  def common_tag_values(name) do
    GenServer.call(name, :get_common_tag_values)
  end

  @spec config(name()) :: %{aggregates_table_id: atom(), dist_table_id: atom()}
  def config(name) do
    GenServer.call(name, :get_config)
  end

  @spec metrics(name()) :: [{TelemetryMetricsPrometheus.metric(), :telemetry.handler_id()}]
  def metrics(name) do
    GenServer.call(name, :get_metrics)
  end

  def handle_call(:get_common_tag_values, _from, state) do
    {:reply, state.common_tag_values, state}
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
          | {:reply, {:error, :already_exists, TelemetryMetricsPrometheus.metric()}, map()}

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

  @spec create_table(name :: atom, type :: atom) :: :ets.tid() | atom
  defp create_table(name, type) do
    :ets.new(name, [:named_table, :public, type, {:write_concurrency, true}])
  end

  @spec monitor_tables([atom()]) :: DynamicSupervisor.on_start_child()
  def monitor_tables(tables) do
    measurement_specs =
      Enum.map(tables, &{TelemetryMetricsPrometheus.Telemetry, :dispatch_table_stats, [&1]})

    DynamicSupervisor.start_child(
      TelemetryMetricsPrometheus.DynamicSupervisor,
      {Telemetry.Poller, [measurements: measurement_specs]}
    )
  end
end

defmodule MCTS.SearchServer do
  @moduledoc """
  Runs an `MCTS.Search` search as long-running process.

  To use the dynamic supervisor, first you'll need add something like this to
  your application's child specifications:

    children = [
      ...
      {Registry, keys: :unique, name: MCTS.SearchServer.SearchRegistry},
      {DynamicSupervisor, name: MCTS.SearchServer.SearchSupervisor, strategy: :one_for_one}
    ]
  """

  use GenServer, restart: :transient

  alias MCTS.Search

  @default_registry MCTS.SearchServer.SearchRegistry
  @default_supervisor MCTS.SearchServer.SearchSupervisor

  @default_game MCTS.Examples.CountingGame
  @default_timeout :infinity
  @default_control :automatic

  def start(search_id, opts \\ []) do
    {registry, opts} = Keyword.pop(opts, :registry, @default_registry)
    {supervisor, opts} = Keyword.pop(opts, :supervisor, @default_supervisor)

    opts = Keyword.merge(opts, [
      search_id: search_id,
      name: {:via, Registry, {registry, search_id}}
    ])

    DynamicSupervisor.start_child(supervisor, {__MODULE__, opts})
  end

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def lookup(search_id, registry \\ @default_registry) do
    case Registry.lookup(registry, search_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def search(pid, iterations \\ 1) do
    GenServer.cast(pid, {:search, iterations})
  end

  def update(pid, new_game) do
    GenServer.cast(pid, {:update, new_game})
  end

  def solve(pid) do
    GenServer.call(pid, :solve)
  end

  def get_search(pid) do
    GenServer.call(pid, :get_search)
  end

  def stop(pid) do
    send(pid, :stop)
    :ok
  end

  @impl true
  def init(opts) do
    search_id = Keyword.fetch!(opts, :search_id)
    search_opts = Keyword.get(opts, :search, [])

    {:ok, game} = case Keyword.get(opts, :game, @default_game) do
      game_module when is_atom(game_module) -> game_module.new
      game_state -> {:ok, game_state}
    end

    control = Keyword.get(opts, :control, @default_control)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    search = Search.new(game, search_opts)

    state = %{
      search_id: search_id,
      search: search,
      control: control,
      iterations: 0
    }

    stop_after(timeout)

    if control == :automatic do
      step()
    end

    {:ok, state}
  end

  @impl true
  def handle_info(:step, state) do
    new_search = Search.search(state.search)

    new_state = state
    |> Map.update(:iterations, 1, &(&1 + 1))
    |> Map.put(:search, new_search)

    if state.control == :automatic do
      step()
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:search, iterations}, state) do
    new_search = state.search
    |> Stream.iterate(&Search.search/1)
    |> Enum.at(iterations)

    new_state = state
    |> Map.update(:iterations, iterations, &(&1 + iterations))
    |> Map.put(:search, new_search)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update, new_game}, state) do
    new_search = Search.update(state.search, new_game)
    new_state = Map.put(state, :search, new_search)

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:solve, _from, state) do
    solutions = Search.solutions(state.search)
    [%{move: move} | _rest] = solutions
    {:reply, move, state}
  end

  @impl true
  def handle_call(:get_search, _from, state) do
    {:reply, state.search, state}
  end

  defp stop_after(:infinity), do: :ok

  defp stop_after(timeout) do
    ref = Process.send_after(self(), :stop, timeout)
    {:ok, ref}
  end

  def step do
    send(self(), :step)
  end
end

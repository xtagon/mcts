defmodule MCTS.PerpetualSearch do
  use Perpetual, restart: :transient

  alias MCTS.Search

  @default_registry MCTS.PerpetualSearch.SearchRegistry
  @default_supervisor MCTS.PerpetualSearch.SearchSupervisor

  @default_game MCTS.Examples.LeftRightGame

  def start(search_id, opts \\ []) do
    {registry, opts} = Keyword.pop(opts, :registry, @default_registry)
    {supervisor, opts} = Keyword.pop(opts, :supervisor, @default_supervisor)

    opts = Keyword.merge(opts, [
      search_id: search_id,
      name: {:via, Registry, {registry, search_id}}
    ])

    DynamicSupervisor.start_child(supervisor, {__MODULE__, opts})
  end

  def start_link(opts \\ []) do
    {game, opts} = Keyword.pop(opts, :game, @default_game)
    {search_opts, opts} = Keyword.pop(opts, :search, [])

    args = [
      init_fun: {Search, :new, [game, search_opts]},
      next_fun: {Search, :search, []}
    ]

    opts = Keyword.put_new(opts, :name, __MODULE__)

    Perpetual.start_link(args, opts)
  end

  def lookup(search_id, registry \\ @default_registry) do
    case Registry.lookup(registry, search_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def update(perpetual, new_game_state, timeout \\ 5000) do
    Perpetual.update(perpetual, Search, :update, [new_game_state], timeout)
  end

  def cast(perpetual, new_game_state) do
    Perpetual.cast(perpetual, Search, :update, [new_game_state])
  end

  def get(perpetual, module, fun, args, timeout \\ 5000) do
    Perpetual.get(perpetual, module, fun, args, timeout)
  end

  def stop(perpetual, reason \\ :normal, timeout \\ :infinity) do
    Perpetual.stop(perpetual, reason, timeout)
  end
end

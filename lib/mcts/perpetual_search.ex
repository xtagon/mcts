defmodule MCTS.PerpetualSearch do
  use Perpetual, restart: :transient

  alias MCTS.Search

  @default_game MCTS.Examples.LeftRightGame

  def start_link(opts \\ []) do
    {game, opts} = Keyword.pop(opts, :game, @default_game)
    {search_opts, opts} = Keyword.pop(opts, :search, [])

    args = [
      init_fun: {Search, :new, [game, search_opts]},
      next_fun: {Search, :search, []}
    ]

    Perpetual.start_link(args, opts)
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

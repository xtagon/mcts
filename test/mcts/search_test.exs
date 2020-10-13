defmodule SearchTest do
  use ExUnit.Case
  doctest MCTS.Search

  alias MCTS.Examples.LeftRightGame, as: Game
  alias MCTS.Search

  test "updating with new game state that isn't yet in the graph should reset to a new graph" do
    {:ok, turn0} = Game.new
    search0 = Search.new(turn0)

    {:ok, turn1} = Game.play_move(turn0, :left)
    search1 = Search.update(search0, turn1)

    expected_root_vertex_id = Game.hash(turn1)

    assert search1.root_vertex_id == expected_root_vertex_id
    assert Graph.vertices(search1.graph) == [expected_root_vertex_id]
  end

  test "updating with a new game state that is in the graph should keep the reachable subgraph and trim the unreachable vertices" do
    {:ok, turn0} = Game.new
    search0 = Search.new(turn0)

    turns = 50

    search50 = search0
    |> Stream.iterate(&Search.search/1)
    |> Enum.at(turns)

    {:ok, turn1} = Game.play_move(turn0, :left)
    search1 = Search.update(search50, turn1)

    expected_root_vertex_id = Game.hash(turn1)

    assert search1.root_vertex_id == expected_root_vertex_id
    assert Graph.is_subgraph?(search1.graph, search50.graph)
    assert length(Graph.vertices(search1.graph)) < length(Graph.vertices(search50.graph))
  end
end

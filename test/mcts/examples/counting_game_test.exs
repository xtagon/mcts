defmodule CountingGameTest do
  use ExUnit.Case
  doctest MCTS.Examples.CountingGame

  alias MCTS.Examples.CountingGame, as: Game

  test "new game starts with score of 0" do
    assert {:ok, %Game{score: 0}} = Game.new
  end

  test "available moves for a new game are :increment and :decrement" do
    assert {:ok, game} = Game.new
    assert Game.available_moves(game) == MapSet.new([:increment, :decrement])
  end

  test "playing the move :increment adds 1 to the score" do
    assert {:ok, %Game{score: 1}} = Game.new |> Game.play_move(:increment)
  end

  test "playing the move :decrement subtracts 1 from the score" do
    assert {:ok, %Game{score: -1}} = Game.new |> Game.play_move(:decrement)
  end

  test "playing the move :increment for 100 turns results in a win" do
    turns = 100

    {:ok, game} = Game.new
    |> Stream.iterate(&(Game.play_move(&1, :increment)))
    |> Enum.at(turns)

    assert {:decided, :win} = Game.outcome(game)
    assert 1 == Game.score(game)
  end

  test "playing the move :decrement for 100 turns results in a loss" do
    turns = 100

    {:ok, game} = Game.new
    |> Stream.iterate(&(Game.play_move(&1, :decrement)))
    |> Enum.at(turns)

    assert {:decided, :lose} = Game.outcome(game)
    assert -1 == Game.score(game)
  end
end

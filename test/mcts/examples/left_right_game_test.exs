defmodule LeftRightGameTest do
  use ExUnit.Case
  doctest MCTS.Examples.LeftRightGame

  alias MCTS.Examples.LeftRightGame, as: Game

  test "new game starts with 0 score and 0 steps" do
    assert {:ok, %Game{score: 0, steps: 0}} = Game.new
  end

  test "available moves for a new game are :left and :right" do
    assert {:ok, game} = Game.new
    assert Game.available_moves(game) == MapSet.new([:left, :right])
  end

  test "playing the move :left adds 1 to the score adds 1 to steps" do
    turn1 = Game.new |> Game.play_move(:left)

    assert {:ok, %Game{score: 1, steps: 1}} = turn1
  end

  test "playing the move :right leaves the score unchanged and adds 1 to steps" do
    turn1 = Game.new |> Game.play_move(:right)

    assert {:ok, %Game{score: 0, steps: 1}} = turn1
  end

  test "playing the move :left for 300 turns results in a perfect score of 300" do
    turns = 300

    {:ok, game} = Game.new
    |> Stream.iterate(&(Game.play_move(&1, :left)))
    |> Enum.at(turns)

    assert {:decided, score} = Game.outcome(game)
    assert 300 == score
    assert 300 == Game.score(game)
  end

  test "playing the move :right for 300 turns results in a score of 0" do
    turns = 300

    {:ok, game} = Game.new
    |> Stream.iterate(&(Game.play_move(&1, :right)))
    |> Enum.at(turns)

    assert {:decided, score} = Game.outcome(game)
    assert 0 == score
    assert 0 == Game.score(game)
  end
end

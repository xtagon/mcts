defmodule MCTS.Examples.LeftRightGame do
  defstruct [
    :score,
    :steps
  ]

  alias __MODULE__, as: Game

  @max_steps 300

  @legal_moves MapSet.new([:left, :right])

  def new do
    game = %Game{score: 0, steps: 0}
    {:ok, game}
  end

  def hash(%Game{score: score, steps: steps}) do
    :erlang.phash2({score, steps})
  end

  def available_moves(%Game{} = game) do
    if decided?(game) do
      MapSet.new
    else
      @legal_moves
    end
  end

  def available_move?(%Game{} = game, move) do
    MapSet.member?(available_moves(game), move)
  end

  def any_available_moves?(%Game{} = game) do
    Enum.any?(available_moves(game))
  end

  def play_move({:ok, game}, move) do
    play_move(game, move)
  end

  def play_move(%Game{score: score, steps: steps} = game, move) do
    if available_move?(game, move) do
      new_score = case move do
        :left -> score + 1
        _ -> score
      end

      new_game = %Game{
        score: new_score,
        steps: steps + 1
      }

      {:ok, new_game}
    else
      if any_available_moves?(game) do
        {:error, :invalid_move}
      else
        {:error, :no_available_moves}
      end
    end
  end

  def outcome(%Game{score: score, steps: steps})
  when steps >= @max_steps do
    {:decided, score}
  end

  def outcome(_game), do: :undecided

  def decided?(%Game{} = game) do
    outcome(game) != :undecided
  end

  def undecided?(%Game{} = game) do
    outcome(game) == :undecided
  end

  def score(%Game{} = game) do
    case outcome(game) do
      {:decided, score} -> score
      _ -> 0
    end
  end
end

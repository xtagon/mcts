defmodule MCTS.Examples.CountingGame do
  defstruct [:score]

  alias __MODULE__, as: Game

  @legal_moves MapSet.new([:increment, :decrement])

  def new do
    {:ok, %Game{score: 0}}
  end

  def hash(%Game{score: score}) do
    score
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

  def play_move(%Game{} = game, move) do
    if available_move?(game, move) do
      difference = case move do
        :increment -> +1
        :decrement -> -1
      end

      new_score = game.score + difference
      new_game = %Game{score: new_score}

      {:ok, new_game}
    else
      if any_available_moves?(game) do
        {:error, :invalid_move}
      else
        {:error, :no_available_moves}
      end
    end
  end

  def play_move(%Game{score: score}, :decrement) do
    %Game{score: score - 1}
  end

  def outcome(%Game{score: score}) when score >= 100, do: {:decided, :win}
  def outcome(%Game{score: score}) when score <= -100, do: {:decided, :lose}
  def outcome(_state), do: :undecided

  def decided?(%Game{} = game) do
    outcome(game) != :undecided
  end

  def undecided?(%Game{} = game) do
    outcome(game) == :undecided
  end

  def score(%Game{} = game) do
    case outcome(game) do
      {:decided, :win} -> +1
      {:decided, :lose} -> -1
      _ -> 0
    end
  end
end

defmodule LeftRightGameSearchTest do
  use ExUnit.Case

  alias MCTS.Examples.LeftRightGame, as: Game
  alias MCTS.PerpetualSearch
  alias MCTS.Search

  require Logger

  @iterations 150
  @deadline 4000

  test "searching for #{@iterations} iterations solves the LeftRight game by maximizing the average score" do
    {:ok, game} = Game.new

    solution = game
    |> solve_for_n_iterations(@iterations)
    |> Enum.max_by(&(&1.average_score))

    assert :left == solution.move
  end

  test "searching for #{@iterations} iterations solves the LeftRight game by maximizing the visits" do
    {:ok, game} = Game.new

    solution = game
    |> solve_for_n_iterations(@iterations)
    |> Enum.max_by(&(&1.visits))

    assert :left == solution.move
  end

  test "searching for #{@deadline} milliseconds solves the LeftRight game by maximizing the average score" do
    {:ok, game} = Game.new

    solution = game
    |> solve_for_n_milleseconds(@deadline)
    |> Enum.max_by(&(&1.average_score))

    assert :left == solution.move
  end

  test "searching for #{@deadline} milliseconds solves the LeftRight game by maximizing the visits" do
    {:ok, game} = Game.new

    solution = game
    |> solve_for_n_milleseconds(@deadline)
    |> Enum.max_by(&(&1.visits))

    assert :left == solution.move
  end

  def get_solutions(%Search{} = search) do
    {Search.solutions(search), search.iterations}
  end

  defp solve_for_n_iterations(game, iterations) do
    {time_in_microseconds, solutions} = :timer.tc(fn ->
      game
      |> Search.new
      |> Stream.iterate(&Search.search/1)
      |> Enum.at(iterations)
      |> Search.solutions
    end)

    time_in_seconds = time_in_microseconds / 1000 / 1000

    Logger.debug("Finished #{iterations} iterations in #{time_in_seconds} seconds")

    solutions
  end

  defp solve_for_n_milleseconds(game, deadline) do
    {:ok, search_pid} = PerpetualSearch.start_link(game: game)
    Process.sleep(deadline)
    {solutions, iterations} = PerpetualSearch.get(search_pid, __MODULE__, :get_solutions, [])

    Logger.debug("Stopping search after #{iterations} iterations")

    :ok = PerpetualSearch.stop(search_pid)

    solutions
  end
end

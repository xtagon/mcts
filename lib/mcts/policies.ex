defmodule MCTS.Policies do
  def first_policy(choices) do
    Enum.at(choices, 0)
  end

  def random_policy(choices) do
    Enum.random(choices)
  end

  def min_visits_selection_policy(choices) do
    Enum.min_by(choices, fn {_vertex_id, _score, visits} ->
      visits
    end)
  end
end

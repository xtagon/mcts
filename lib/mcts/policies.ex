defmodule MCTS.Policies do
  def first_policy(choices) do
    Enum.at(choices, 0)
  end

  def random_policy(choices) do
    Enum.random(choices)
  end

  def min_visits_selection_policy(choices, _parent_visits) do
    Enum.min_by(choices, fn {_vertex_id, _score, visits} ->
      visits
    end)
  end

  def uct_selection_policy(exploration_constant \\ 2.0) do
    fn choices, parent_visits ->
      Enum.find(choices, fn {_vertex_id, _score, visits} ->
        visits == 0
      end) || Enum.max_by(choices, fn {_vertex_id, score, visits} ->
        exploitation_term = score / visits
        uct(exploitation_term, exploration_constant, parent_visits, visits)
      end)
    end
  end

  defp uct(q, c, n, n_prime) do
    q + c * :math.sqrt(:math.log(n) / n_prime)
  end
end

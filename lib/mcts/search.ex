defmodule MCTS.Search do
  defstruct [
    :iterations,
    :game,
    :graph,
    :root_vertex_id,
    :selected_vertex_id,
    :score_to_backpropogate,
    :scores,
    :visits,
    :transpositions,
    :selection_policy,
    :expansion_policy,
    :move_policy,
    :score_policy
  ]

  alias __MODULE__
  alias MCTS.Policies

  def new(%game{} = game_state, opts \\ []) do
    selection_policy = Keyword.get(opts, :selection_policy, &Policies.min_visits_selection_policy/1)
    expansion_policy = Keyword.get(opts, :expansion_policy, &Policies.first_policy/1)
    move_policy = Keyword.get(opts, :move_policy, &Policies.random_policy/1)
    score_policy = Keyword.get(opts, :score_policy, &game.score/1)

    root_vertex_id = game.hash(game_state)
    graph = Graph.new(type: :directed) |> Graph.add_vertex(root_vertex_id)
    scores = %{root_vertex_id => 0}
    visits = %{root_vertex_id => 0}
    transpositions = %{root_vertex_id => game_state}

    %Search{
      iterations: 0,
      game: game,
      graph: graph,
      root_vertex_id: root_vertex_id,
      selected_vertex_id: root_vertex_id,
      score_to_backpropogate: 0,
      scores: scores,
      visits: visits,
      transpositions: transpositions,
      selection_policy: selection_policy,
      expansion_policy: expansion_policy,
      move_policy: move_policy,
      score_policy: score_policy
    }
  end

  def search(%Search{} = search) do
    search
    |> select
    |> expand
    |> simulate
    |> backpropagate
    |> increment_iterations
  end

  def select(%Search{} = search) do
    select(search, search.root_vertex_id)
  end

  def select(%Search{} = search, current_vertex_id) do
    if leaf?(search, current_vertex_id) do
      %Search{search | selected_vertex_id: current_vertex_id}
    else
      out_neighbors = Graph.out_neighbors(search.graph, current_vertex_id)

      choices = Enum.map(out_neighbors, fn vertex_id ->
        score = score(search, vertex_id)
        visits = visits(search, vertex_id)

        {vertex_id, score, visits}
      end)

      selected_vertex_id = case search.selection_policy.(choices) do
        {vertex_id, _score, _visits} -> vertex_id
        vertex_id -> vertex_id
      end

      select(search, selected_vertex_id)
    end
  end

  def expand(%Search{} = search) do
    selected_vertex_id = search.selected_vertex_id

    should_expand = selected_vertex_id == search.root_vertex_id || visited?(search, selected_vertex_id)

    if should_expand  do
      game_state = game_state(search, selected_vertex_id)
      available_moves = search.game.available_moves(game_state)

      expanded_search = Enum.reduce(available_moves, search, fn move, expanding_search ->
        {:ok, new_game_state} = expanding_search.game.play_move(game_state, move)
        new_vertex_id = expanding_search.game.hash(new_game_state)
        new_graph = Graph.add_edge(expanding_search.graph, selected_vertex_id, new_vertex_id, label: move)
        new_transpositions = Map.put(expanding_search.transpositions, new_vertex_id, new_game_state)

        %Search{search | graph: new_graph, transpositions: new_transpositions}
      end)

      new_vertex_ids = Graph.out_neighbors(expanded_search.graph, selected_vertex_id)

      if Enum.empty?(new_vertex_ids) do
        expanded_search
      else
        new_selected_vertex_id = expanded_search.expansion_policy.(new_vertex_ids)

        %Search{expanded_search | selected_vertex_id: new_selected_vertex_id}
      end
    else
      %Search{search | selected_vertex_id: selected_vertex_id}
    end
  end

  def simulate(%Search{} = search) do
    selected_game_state = game_state(search, search.selected_vertex_id)

    stream = Stream.iterate({:ok, selected_game_state}, fn {:ok, game_state} ->
      available_moves = search.game.available_moves(game_state)

      if Enum.empty?(available_moves) do
        {:error, :no_available_moves}
      else
        selected_move = search.move_policy.(available_moves)
        search.game.play_move(game_state, selected_move)
      end
    end)

    stream_while_moves_available = Stream.take_while(stream, fn
      {:error, :no_available_moves} -> false
      _ -> true
    end)

    {:ok, terminal_game_state} = Enum.at(stream_while_moves_available, -1)

    score = search.score_policy.(terminal_game_state)

    %Search{search | score_to_backpropogate: score}
  end

  def backpropagate(%Search{} = search) do
    paths = Graph.Pathfinding.all(search.graph, search.root_vertex_id, search.selected_vertex_id)

    backpropagated_search = case paths do
      [] -> search
      _ ->
        score = search.score_to_backpropogate

        Enum.reduce(paths, search, fn path, path_update_search ->
          Enum.reduce(path, path_update_search, fn vertex_id, vertex_update_search ->
            new_scores = Map.update(vertex_update_search.scores, vertex_id, score, &(&1 + score))
            new_visits = Map.update(vertex_update_search.visits, vertex_id, 1, &(&1 + 1))

            %Search{vertex_update_search |
              scores: new_scores,
              visits: new_visits
            }
          end)
        end)
    end

    %Search{backpropagated_search |
      selected_vertex_id: search.root_vertex_id,
      score_to_backpropogate: 0
    }
  end

  def update(%Search{} = search, new_root_game_state) do
    new_root_vertex_id = search.game.hash(new_root_game_state)

    new_transpositions = Map.put_new(search.transpositions, new_root_vertex_id, new_root_game_state)

    new_graph = if Graph.has_vertex?(search.graph, new_root_vertex_id) do
      reachable = Graph.reachable(search.graph, [new_root_vertex_id])
      Graph.subgraph(search.graph, reachable)
    else
      Graph.new |> Graph.add_vertex(new_root_vertex_id)
    end

    %Search{search |
      graph: new_graph,
      root_vertex_id: new_root_vertex_id,
      transpositions: new_transpositions
    }
  end

  def solutions(%Search{} = search) do
    Graph.out_edges(search.graph, search.root_vertex_id)
    |> Enum.map(&(edge_to_solution(search, &1)))
    |> Enum.sort_by(fn %{average_score: average_score} -> -1 * average_score end)
  end

  defp edge_to_solution(%Search{} = search, %Graph.Edge{label: move, v2: vertex_id}) do
    score = score(search, vertex_id)
    visits = visits(search, vertex_id)

    average_score = if visits > 0 do
      score / visits
    else
      score
    end

    %{
      move: move,
      average_score: average_score,
      visits: visits
    }
  end

  def root_visits(%Search{} = search) do
    visits(search, search.root_vertex_id)
  end

  def visits(%Search{} = search, vertex_id) do
    Map.get(search.visits, vertex_id, 0)
  end

  def score(%Search{} = search, vertex_id) do
    Map.get(search.scores, vertex_id, 0)
  end

  def game_state(%Search{} = search, vertex_id) do
    search.transpositions[vertex_id]
  end

  def leaf?(%Search{} = search, vertex_id) do
    Graph.out_degree(search.graph, vertex_id) == 0
  end

  def terminal?(%Search{} = search, vertex_id) do
    Enum.empty?(search.game.available_moves(game_state(search, vertex_id)))
  end

  def visited?(%Search{} = search, vertex_id) do
    visits(search, vertex_id) > 0
  end

  defp increment_iterations(%Search{} = search) do
    %Search{search | iterations: search.iterations + 1}
  end
end

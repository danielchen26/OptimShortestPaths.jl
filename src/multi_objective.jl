"""
Multi-Objective Shortest Path (MOSP) extensions for OptimShortestPaths framework.
Handles multiple objectives and Pareto-optimal solutions.
"""

module MultiObjective

using ..OptimShortestPaths

export MultiObjectiveEdge, ParetoSolution, MultiObjectiveGraph,
       compute_pareto_front, weighted_sum_approach, epsilon_constraint_approach,
       lexicographic_approach, get_knee_point

"""
Edge with multiple objective weights (e.g., distance, cost, risk, time)
"""
struct MultiObjectiveEdge
    source::Int
    target::Int
    weights::Vector{Float64}  # Multiple objectives
    edge_id::Int
end

"""
A Pareto-optimal solution with multiple objective values
"""
struct ParetoSolution
    objectives::Vector{Float64}  # Objective values for this solution
    path::Vector{Int}            # The actual path
    parent::Vector{Int}          # Parent array for path reconstruction
end

"""
Multi-objective graph structure
"""
struct MultiObjectiveGraph
    n_vertices::Int
    edges::Vector{MultiObjectiveEdge}
    n_objectives::Int
    adjacency_list::Vector{Vector{Int}}
    objective_names::Vector{String}  # Names like ["distance", "cost", "risk"]
    objective_sense::Vector{Symbol}  # :min or :max per objective

    function MultiObjectiveGraph(n_vertices::Int, edges::Vector{MultiObjectiveEdge},
                                 n_objectives::Int, adjacency_list::Vector{Vector{Int}},
                                 objective_names::Vector{String}, objective_sense::Vector{Symbol})
        n_vertices > 0 || throw(ArgumentError("Graph must contain at least one vertex"))
        length(adjacency_list) == n_vertices || throw(ArgumentError("Adjacency list length must equal number of vertices"))
        length(objective_names) == n_objectives || throw(ArgumentError("Objective names length must equal number of objectives"))
        length(objective_sense) == n_objectives || throw(ArgumentError("Objective sense length must equal number of objectives"))

        valid_senses = (:min, :max)
        for sense in objective_sense
            sense in valid_senses || throw(ArgumentError("Objective sense must be :min or :max"))
        end

        for edge in edges
            length(edge.weights) == n_objectives || throw(ArgumentError("Edge weight dimension mismatch with number of objectives"))
        end

        return new(n_vertices, edges, n_objectives, adjacency_list, objective_names, objective_sense)
    end
end

function MultiObjectiveGraph(n_vertices::Int, edges::Vector{MultiObjectiveEdge},
                              n_objectives::Int, adjacency_list::Vector{Vector{Int}},
                              objective_names::Vector{String};
                              objective_sense=fill(:min, n_objectives))
    return MultiObjectiveGraph(n_vertices, edges, n_objectives, adjacency_list,
                               objective_names, Symbol.(objective_sense))
end

"""
Convenience constructor that builds adjacency list automatically from edges.

# Example
```julia
mo_edges = [
    MultiObjectiveEdge(1, 2, [50.0, 10.0], 1),
    MultiObjectiveEdge(2, 3, [30.0, 8.0], 2)
]

# No need to build adjacency list manually!
mo_graph = MultiObjectiveGraph(3, mo_edges, 2, ["Cost", "Time"])
```
"""
function MultiObjectiveGraph(n_vertices::Int, edges::Vector{MultiObjectiveEdge},
                              n_objectives::Int, objective_names::Vector{String};
                              objective_sense=fill(:min, n_objectives))
    # Build adjacency list automatically
    adjacency_list = [Int[] for _ in 1:n_vertices]
    for (idx, edge) in enumerate(edges)
        push!(adjacency_list[edge.source], idx)
    end

    return MultiObjectiveGraph(n_vertices, edges, n_objectives, adjacency_list,
                               objective_names, Symbol.(objective_sense))
end

"""
Check if solution a dominates solution b (all objectives <= and at least one <)
"""
function dominates(a::Vector{Float64}, b::Vector{Float64}, sense::Vector{Symbol}; atol=1e-10)
    (length(a) == length(b) && length(a) == length(sense)) ||
        throw(ArgumentError("Dominance comparison dimension mismatch"))

    improved = false
    for i in 1:length(a)
        if sense[i] === :min
            if a[i] > b[i] + atol
                return false
            elseif a[i] < b[i] - atol
                improved = true
            end
        else
            if a[i] < b[i] - atol
                return false
            elseif a[i] > b[i] + atol
                improved = true
            end
        end
    end
    return improved
end

"""
Compute the full Pareto front for multi-objective shortest paths.
Returns all non-dominated paths from source to target.
"""
function compute_pareto_front(graph::MultiObjectiveGraph, source::Int, target::Int; 
                             max_solutions::Int=100)
    pareto_front = ParetoSolution[]
    
    # Each vertex maintains a set of non-dominated labels
    # Label format: (objectives, parent_vertex, parent_label_index)
    labels = [Vector{Tuple{Vector{Float64}, Int, Int}}() for _ in 1:graph.n_vertices]
    
    # Initialize source
    push!(labels[source], (zeros(graph.n_objectives), 0, 0))
    
    # Queue: (vertex, label_index)
    # Use a set to track processed items
    queue = [(source, 1)]
    processed = Set{Tuple{Int, Int}}()
    
    while !isempty(queue) && length(pareto_front) < max_solutions
        item = popfirst!(queue)
        
        # Skip if already processed
        if item in processed
            continue
        end
        push!(processed, item)
        
        u, label_idx = item
        
        if label_idx > length(labels[u])
            continue
        end
        
        current_cost, parent_v, parent_idx = labels[u][label_idx]
        
        # If this is the target, add to Pareto front
        if u == target
            # Reconstruct path
            path = [u]
            parent_array = zeros(Int, graph.n_vertices)
            curr_v = u
            curr_idx = label_idx
            
            while curr_v != source
                if curr_idx > length(labels[curr_v])
                    break
                end
                _, p_v, p_idx = labels[curr_v][curr_idx]
                parent_array[curr_v] = p_v
                curr_v = p_v
                curr_idx = p_idx
                pushfirst!(path, curr_v)
            end
            
            push!(pareto_front, ParetoSolution(current_cost, path, parent_array))
        end

        # Explore neighbors
        for edge_idx in graph.adjacency_list[u]
            edge = graph.edges[edge_idx]
            v = edge.target
            
            # New objective values
            new_cost = current_cost .+ edge.weights

            # Check if dominated by existing labels at v
            dominated = false
            for (existing_cost, _, _) in labels[v]
                if dominates(existing_cost, new_cost, graph.objective_sense)
                    dominated = true
                    break
                end
            end

            if !dominated
                # Remove labels dominated by new_cost
                old_size = length(labels[v])
                filter!(label -> !dominates(new_cost, label[1], graph.objective_sense), labels[v])
                
                # Add new label
                push!(labels[v], (new_cost, u, label_idx))
                new_item = (v, length(labels[v]))
                
                # Only add to queue if not already processed
                if new_item ∉ processed
                    push!(queue, new_item)
                end
            end
        end
    end
    
    return pareto_front
end

"""
Weighted sum approach: Combine objectives with weights.
Simple but may miss some Pareto-optimal solutions.
"""
function weighted_sum_approach(graph::MultiObjectiveGraph, source::Int, target::Int,
                              weights::Vector{Float64})
    # Validate weights
    length(weights) == graph.n_objectives || error("Weight vector size mismatch")
    abs(sum(weights) - 1.0) < 1e-6 || error("Weights must sum to 1 within tolerance 1e-6")
    1 <= target <= graph.n_vertices || throw(BoundsError("Target vertex $target out of range"))

    # DMY-based aggregation currently expects cost-type objectives
    all(graph.objective_sense .== :min) || throw(ArgumentError(
        "weighted_sum_approach currently supports only objectives expressed as costs (sense=:min). " *
        "Transform maximize metrics into costs before calling."))

    # Create single-objective graph with weighted edges
    edges = OptimShortestPaths.Edge[]
    edge_weights = Float64[]
    edge_index_lookup = Int[]

    for (idx, medge) in enumerate(graph.edges)
        push!(edges, OptimShortestPaths.Edge(medge.source, medge.target, length(edges) + 1))
        weighted_value = sum(medge.weights .* weights)
        push!(edge_weights, weighted_value)
        push!(edge_index_lookup, idx)
    end

    single_obj_graph = OptimShortestPaths.DMYGraph(graph.n_vertices, edges, edge_weights)

    # Run DMY algorithm
    dist, parent = OptimShortestPaths.dmy_sssp_with_parents!(single_obj_graph, source)

    if dist[target] == OptimShortestPaths.INF
        return ParetoSolution(fill(Inf, graph.n_objectives), Int[], parent)
    end

    path = reconstruct_path(parent, source, target)
    if isempty(path)
        return ParetoSolution(fill(Inf, graph.n_objectives), Int[], parent)
    end

    parent_edge_lookup = zeros(Int, graph.n_vertices)
    tolerance = 1e-10

    for idx in 2:length(path)
        v = path[idx]
        p = parent[v]

        chosen_idx = 0
        for edge_idx in single_obj_graph.adjacency_list[p]
            edge = single_obj_graph.edges[edge_idx]
            if edge.target == v
                weight = single_obj_graph.weights[edge_idx]
                if abs(dist[p] + weight - dist[v]) <= tolerance
                    chosen_idx = edge_idx
                    break
                end
            end
        end

        if chosen_idx == 0
            for edge_idx in single_obj_graph.adjacency_list[p]
                edge = single_obj_graph.edges[edge_idx]
                if edge.target == v
                    chosen_idx = edge_idx
                    break
                end
            end
        end

        chosen_idx != 0 || throw(ArgumentError("Unable to resolve edge for path segment $p -> $v in weighted sum aggregation"))
        parent_edge_lookup[v] = edge_index_lookup[chosen_idx]
    end

    objectives = compute_path_objectives(graph, parent, source, target; edge_indices=parent_edge_lookup)
    return ParetoSolution(objectives, path, parent)
end

"""
Epsilon-constraint approach: Optimize one objective while constraining others.
Good for finding specific trade-off solutions.
"""
function epsilon_constraint_approach(graph::MultiObjectiveGraph, source::Int, target::Int,
                                    primary_objective::Int, constraints::Vector{Float64})
    1 <= target <= graph.n_vertices || throw(BoundsError("Target vertex $target out of range"))
    length(constraints) == graph.n_objectives || error("Constraints vector must match number of objectives")
    1 <= primary_objective <= graph.n_objectives || throw(BoundsError("Primary objective index out of range"))

    # This would require a constrained shortest path algorithm
    # For now, we filter solutions from Pareto front
    pareto_front = compute_pareto_front(graph, source, target)

    # Filter solutions that satisfy constraints
    valid_solutions = ParetoSolution[]
    tol = 1e-10
    for sol in pareto_front
        satisfies_constraints = true
        for (i, constraint) in enumerate(constraints)
            i == primary_objective && continue
            sense = graph.objective_sense[i]
            if sense === :min
                if sol.objectives[i] > constraint + tol
                    satisfies_constraints = false
                    break
                end
            else
                if sol.objectives[i] < constraint - tol
                    satisfies_constraints = false
                    break
                end
            end
        end
        if satisfies_constraints
            push!(valid_solutions, sol)
        end
    end
    
    # Return best solution for primary objective
    if !isempty(valid_solutions)
        scores = [sol.objectives[primary_objective] for sol in valid_solutions]
        best_idx = graph.objective_sense[primary_objective] === :min ? argmin(scores) : argmax(scores)
        return valid_solutions[best_idx]
    end
    
    return ParetoSolution(fill(Inf, graph.n_objectives), Int[], zeros(Int, graph.n_vertices))
end

"""
Lexicographic approach: Optimize objectives in priority order.
Good when objectives have clear priority ranking.
"""
function lexicographic_approach(graph::MultiObjectiveGraph, source::Int, target::Int,
                               priority_order::Vector{Int})
    1 <= target <= graph.n_vertices || throw(BoundsError("Target vertex $target out of range"))
    all(graph.objective_sense .== :min) || throw(ArgumentError(
        "lexicographic_approach currently supports only objectives expressed as costs (sense=:min). " *
        "Transform maximize metrics into costs before calling."))
    isempty(priority_order) && return ParetoSolution(fill(Inf, graph.n_objectives), Int[], zeros(Int, graph.n_vertices))

    # Maintain the subset of edge indices that remain feasible after each priority.
    active_edge_indices = collect(1:length(graph.edges))
    best_parent = fill(0, graph.n_vertices)
    dist_to_target = OptimShortestPaths.INF

    for (level, obj_idx) in enumerate(priority_order)
        isempty(active_edge_indices) && return ParetoSolution(fill(Inf, graph.n_objectives), Int[], zeros(Int, graph.n_vertices))

        edges = OptimShortestPaths.Edge[]
        weights = Float64[]
        edge_index_lookup = Int[]  # Map new edge position -> original edge index

        for idx in active_edge_indices
            medge = graph.edges[idx]
            push!(edges, OptimShortestPaths.Edge(medge.source, medge.target, length(edges) + 1))
            push!(weights, medge.weights[obj_idx])
            push!(edge_index_lookup, idx)
        end

        single_obj_graph = OptimShortestPaths.DMYGraph(graph.n_vertices, edges, weights)
        dist, parent = OptimShortestPaths.dmy_sssp_with_parents!(single_obj_graph, source)

        if dist[target] == OptimShortestPaths.INF
            return ParetoSolution(fill(Inf, graph.n_objectives), Int[], parent)
        end

        # Preserve edges that keep the optimal value for this objective.
        new_active = Int[]
        tolerance = 1e-10
        for (local_idx, original_idx) in enumerate(edge_index_lookup)
            medge = graph.edges[original_idx]
            if dist[medge.source] < OptimShortestPaths.INF &&
               abs(dist[medge.source] + weights[local_idx] - dist[medge.target]) <= tolerance
                push!(new_active, original_idx)
            end
        end

        if isempty(new_active)
            return ParetoSolution(fill(Inf, graph.n_objectives), Int[], parent)
        end

        active_edge_indices = new_active
        best_parent = parent
        dist_to_target = dist[target]

        # If the target is uniquely determined at this level and no further priorities remain,
        # we can exit early.
        if level == length(priority_order)
            break
        end
    end

    if dist_to_target == OptimShortestPaths.INF
        return ParetoSolution(fill(Inf, graph.n_objectives), Int[], best_parent)
    end

    path = reconstruct_path(best_parent, source, target)
    if isempty(path)
        return ParetoSolution(fill(Inf, graph.n_objectives), Int[], best_parent)
    end

    # Accumulate objective values along the selected path using the consistent edge set.
    objectives = zeros(graph.n_objectives)
    allowed_edges = Set(active_edge_indices)
    for i in 1:(length(path) - 1)
        u, v = path[i], path[i + 1]
        edge_found = false
        for idx in graph.adjacency_list[u]
            if graph.edges[idx].target == v && idx in allowed_edges
                objectives .+= graph.edges[idx].weights
                edge_found = true
                break
            end
        end
        edge_found || return ParetoSolution(fill(Inf, graph.n_objectives), Int[], best_parent)
    end

    return ParetoSolution(objectives, path, best_parent)
end

"""
Find the "knee point" in the Pareto front - the solution with best trade-off.
Uses the maximum distance from the utopia-nadir line.
"""
function get_knee_point(pareto_front::Vector{ParetoSolution})
    isempty(pareto_front) && return nothing
    length(pareto_front) == 1 && return pareto_front[1]
    
    # Find utopia and nadir points
    n_obj = length(pareto_front[1].objectives)
    utopia = fill(Inf, n_obj)
    nadir = fill(-Inf, n_obj)
    
    for sol in pareto_front
        for i in 1:n_obj
            utopia[i] = min(utopia[i], sol.objectives[i])
            nadir[i] = max(nadir[i], sol.objectives[i])
        end
    end
    
    # Normalize objectives
    normalized_solutions = []
    for sol in pareto_front
        normalized = Float64[]
        for i in 1:n_obj
            if nadir[i] - utopia[i] > 1e-10
                push!(normalized, (sol.objectives[i] - utopia[i]) / (nadir[i] - utopia[i]))
            else
                push!(normalized, 0.0)
            end
        end
        push!(normalized_solutions, normalized)
    end
    
    # Find point with maximum distance from utopia-nadir line
    max_distance = -Inf
    knee_idx = 1
    
    for (i, norm_sol) in enumerate(normalized_solutions)
        # Distance from point to line (simplified for 2D, generalizable)
        distance = sqrt(sum(norm_sol.^2))
        if distance > max_distance
            max_distance = distance
            knee_idx = i
        end
    end
    
    return pareto_front[knee_idx]
end

"""
Compute objective values for a path given parent array.
Optionally accepts a vector of edge indices (per vertex) that identifies
which multi-objective edge was used to reach each vertex.
"""
function compute_path_objectives(graph::MultiObjectiveGraph, parent::Vector{Int},
                                source::Int, target::Int; edge_indices::Union{Nothing,Vector{Int}}=nothing)
    objectives = zeros(graph.n_objectives)
    
    if parent[target] == 0 && target != source
        return fill(Inf, graph.n_objectives)
    end
    
    current = target
    while current != source && parent[current] != 0
        prev = parent[current]
        mapped_idx = (edge_indices === nothing) ? 0 : edge_indices[current]

        if mapped_idx != 0
            edge = graph.edges[mapped_idx]
            edge.source == prev && edge.target == current || throw(ArgumentError("Edge mapping mismatch for vertex $current"))
            objectives .+= edge.weights
            current = prev
            continue
        end

        edge_found = false
        for edge_idx in graph.adjacency_list[prev]
            edge = graph.edges[edge_idx]
            if edge.target == current
                objectives .+= edge.weights
                edge_found = true
                break
            end
        end
        edge_found || return fill(Inf, graph.n_objectives)
        current = prev
    end
    
    return objectives
end

# Convenience helper to build a small demo network used in examples/tests.
function create_drug_network_example()
    # 5 vertices: Source -> Drug1/Drug2 -> Target1/Target2
    # Objectives: [efficacy, toxicity, cost]
    edges = [
        MultiObjectiveEdge(1, 2, [0.8, 0.2, 100.0], 1),  # Drug1: high efficacy, low toxicity, medium cost
        MultiObjectiveEdge(1, 3, [0.5, 0.1, 200.0], 2),  # Drug2: medium efficacy, very low toxicity, high cost
        MultiObjectiveEdge(2, 4, [0.9, 0.3, 50.0], 3),   # Drug1->Target1
        MultiObjectiveEdge(2, 5, [0.7, 0.4, 75.0], 4),   # Drug1->Target2
        MultiObjectiveEdge(3, 4, [0.6, 0.1, 80.0], 5),   # Drug2->Target1
        MultiObjectiveEdge(3, 5, [0.8, 0.15, 60.0], 6),  # Drug2->Target2
    ]
    
    adjacency = [Int[] for _ in 1:5]
    for (i, edge) in enumerate(edges)
        push!(adjacency[edge.source], i)
    end
    
    return MultiObjectiveGraph(5, edges, 3, adjacency,
                              ["efficacy", "toxicity", "cost"],
                              objective_sense=[:max, :min, :min])
end

end # module

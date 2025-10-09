"""
Bounded Multi-Source Shortest Path (BMSSP) implementation for the DMY algorithm.
This module implements the bounded Bellman-Ford relaxation used in the DMY algorithm.
"""

"""
    bmssp!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
           frontier::AbstractSet{Int}, bound::Float64, k::Int) -> OrderedSet{Int}

Perform bounded multi-source shortest path relaxation for k rounds.
Updates the distance and parent arrays in-place and returns the final frontier.

# Arguments
- `graph`: The graph to process
- `dist`: Distance array (modified in-place)
- `parent`: Parent array for path reconstruction (modified in-place)
- `frontier`: Set of active vertices for relaxation
- `bound`: Upper bound for distance updates
- `k`: Maximum number of relaxation rounds

# Returns
- Final frontier set after k rounds or early termination
"""
function bmssp!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                frontier::AbstractSet{Int}, bound::Float64, k::Int)
    
    # Validate inputs
    length(dist) == graph.n_vertices || throw(ArgumentError("Distance array size mismatch"))
    length(parent) == graph.n_vertices || throw(ArgumentError("Parent array size mismatch"))
    k > 0 || throw(ArgumentError("Number of rounds k must be positive"))
    (bound >= 0 || bound == INF) || throw(ArgumentError("Bound must be non-negative or INF"))
    
    current_frontier = OrderedSet(sort(collect(frontier)))
    
    for round in 1:k
        next_frontier = OrderedSet{Int}()
        updated_any = false
        
        # Process all vertices in current frontier
        for u in current_frontier
            # Skip if vertex distance exceeds bound or is unreachable
            if dist[u] == INF || dist[u] > bound
                continue
            end

            # Relax all outgoing edges from vertex u
            for edge_idx in graph.adjacency_list[u]
                edge = graph.edges[edge_idx]
                v = edge.target
                weight = graph.weights[edge_idx]
                
                # Calculate new distance
                new_dist = dist[u] + weight
                
                # Update if new distance is better and within bound
                if new_dist < dist[v] && new_dist <= bound
                    dist[v] = new_dist
                    parent[v] = u
                    push!(next_frontier, v)
                    updated_any = true
                end
            end
        end
        
        # Early termination if no updates occurred
        if !updated_any
            break
        end
        
        current_frontier = next_frontier
    end
    
    return current_frontier
end

"""
    bmssp_single_round!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                        frontier::AbstractSet{Int}, bound::Float64) -> Tuple{OrderedSet{Int}, Bool}

Perform a single round of BMSSP relaxation.
Returns the new frontier and whether any updates occurred.
"""
function bmssp_single_round!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                            frontier::AbstractSet{Int}, bound::Float64)
    
    next_frontier = OrderedSet{Int}()
    updated_any = false
    
    for u in sort(collect(frontier))
        # Skip if vertex distance exceeds bound or is unreachable
        if dist[u] == INF || dist[u] > bound
            continue
        end

        # Relax all outgoing edges from vertex u
        for edge_idx in graph.adjacency_list[u]
            edge = graph.edges[edge_idx]
            v = edge.target
            weight = graph.weights[edge_idx]
            
            # Calculate new distance
            new_dist = dist[u] + weight
            
            # Update if new distance is better and within bound
            if new_dist < dist[v] && new_dist <= bound
                dist[v] = new_dist
                parent[v] = u
                push!(next_frontier, v)
                updated_any = true
            end
        end
    end
    
    return next_frontier, updated_any
end

"""
    count_relaxations(graph::DMYGraph, frontier::AbstractSet{Int}, bound::Float64, 
                     dist::Vector{Float64}) -> Int

Count the number of edge relaxations that would be performed in the next round.
Useful for algorithm analysis and debugging.
"""
function count_relaxations(graph::DMYGraph, frontier::AbstractSet{Int}, bound::Float64, 
                          dist::Vector{Float64})
    count = 0
    for u in sort(collect(frontier))
        if dist[u] == INF || dist[u] > bound
            continue
        end
        count += length(graph.adjacency_list[u])
    end
    return count
end

"""
    validate_bmssp_input(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                        frontier::AbstractSet{Int}, bound::Float64, k::Int) -> Bool

Validate inputs for BMSSP function. Throws ArgumentError if invalid.
"""
function validate_bmssp_input(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                             frontier::AbstractSet{Int}, bound::Float64, k::Int)
    
    # Check array sizes
    length(dist) == graph.n_vertices || throw(ArgumentError("Distance array size mismatch"))
    length(parent) == graph.n_vertices || throw(ArgumentError("Parent array size mismatch"))
    
    # Check parameters
    k > 0 || throw(ArgumentError("Number of rounds k must be positive"))
    (bound >= 0 || bound == INF) || throw(ArgumentError("Bound must be non-negative or INF"))
    
    # Check frontier vertices are valid
    for v in frontier
        1 <= v <= graph.n_vertices || throw(ArgumentError("Invalid vertex $v in frontier"))
    end
    
    # Check distance array has valid values
    for (i, d) in enumerate(dist)
        (d >= 0 || d == INF) || throw(ArgumentError("Invalid distance $d at vertex $i"))
    end
    
    return true
end

"""
    bmssp_with_statistics!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                          frontier::AbstractSet{Int}, bound::Float64, k::Int) -> Dict{String, Any}

Perform BMSSP with detailed statistics collection.
Returns statistics about the relaxation process.
"""
function bmssp_with_statistics!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                                frontier::AbstractSet{Int}, bound::Float64, k::Int)
    
    validate_bmssp_input(graph, dist, parent, frontier, bound, k)
    
    stats = Dict{String, Any}()
    stats["initial_frontier_size"] = length(frontier)
    stats["rounds_performed"] = 0
    stats["total_relaxations"] = 0
    stats["vertices_updated"] = 0
    stats["early_termination"] = false
    
    current_frontier = OrderedSet(sort(collect(frontier)))
    
    for round in 1:k
        stats["rounds_performed"] = round
        
        # Count relaxations for this round
        round_relaxations = count_relaxations(graph, current_frontier, bound, dist)
        stats["total_relaxations"] += round_relaxations
        
        # Perform single round
        next_frontier, updated_any = bmssp_single_round!(graph, dist, parent, current_frontier, bound)
        
        if !updated_any
            stats["early_termination"] = true
            break
        end
        
        stats["vertices_updated"] += length(next_frontier)
        current_frontier = next_frontier
    end
    
    stats["final_frontier_size"] = length(current_frontier)
    return stats
end

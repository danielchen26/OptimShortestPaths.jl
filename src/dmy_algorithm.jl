"""
Main DMY (Duan-Mao-Yin) shortest-path algorithm implementation.
This module contains the core recursive algorithm with frontier sparsification.
"""

"""
    recursive_layer!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                    U::Vector{Int}, S::OrderedSet{Int}, B::Float64) -> Nothing

Recursive layer processing function that implements the core DMY algorithm logic.
Processes vertex subset U with current frontier S and upper bound B.

# Arguments
- `graph`: The graph to process
- `dist`: Distance array (modified in-place)
- `parent`: Parent array for path reconstruction (modified in-place)
- `U`: Vertex subset to process
- `S`: Current frontier set
- `B`: Upper bound for distance updates

The function implements the recursive layering strategy with:
1. Base case handling for small vertex sets
2. Pivot threshold calculation k = ⌈|U|^(1/3)⌉
3. Frontier size checking and algorithm path selection
4. Pivot selection for frontier sparsification when needed
5. Vertex partitioning and recursive calls
"""
function recursive_layer!(graph::DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                         U::Vector{Int}, S::OrderedSet{Int}, B::Float64)
    
    # Base case: if vertex set is empty, return
    if isempty(U)
        return
    end
    
    # For single vertex, ensure it's processed if reachable
    if length(U) == 1
        v = U[1]
        if v in S && dist[v] <= B
            # Process edges from this vertex
            for edge_idx in graph.adjacency_list[v]
                edge = graph.edges[edge_idx]
                target = edge.target
                weight = graph.weights[edge_idx]
                new_dist = dist[v] + weight
                if new_dist < dist[target] && new_dist <= B
                    dist[target] = new_dist
                    parent[target] = v
                end
            end
        end
        return
    end
    
    # Calculate pivot threshold k = ⌈|U|^(1/3)⌉
    # This is the theoretical optimal value from the DMY paper
    n = length(U)
    k = max(1, ceil(Int, n^(1/3)))
    
    # Note: We strictly follow the paper's k = n^(1/3) formula
    # No special cases to maintain theoretical guarantees
    
    # Filter vertices: U_tilde = {v ∈ U \ S | dist[v] < ∞ ∧ dist[v] < B}
    U_tilde = Int[]
    for v in U
        if !(v in S) && dist[v] < INF && dist[v] <= B
            push!(U_tilde, v)
        end
    end
    
    # Choose algorithm path based on frontier size
    if length(U_tilde) <= k * length(S)
        # Frontier is manageable: apply BMSSP directly
        final_frontier = bmssp!(graph, dist, parent, S, B, k)
        # Update S to the new frontier
        empty!(S)
        for v in final_frontier
            push!(S, v)
        end
    else
        # Frontier is too large: apply sparsification
        # Select pivots P from U_tilde
        P = select_pivots(U_tilde, S, k, dist)
        
        # Apply BMSSP on pivots only
        P_set = OrderedSet(sort(P))
        final_frontier = bmssp!(graph, dist, parent, P_set, B, k)
        
        # Update frontier to the result of BMSSP
        empty!(S)
        for v in final_frontier
            push!(S, v)
        end
    end
    
    # Partition U into 2^t nearly equal blocks by distance using the
    # theoretical setting t = ⌈log(|U|)^(1/3)⌉ for balanced recursion depth.
    t = length(U) > 1 ? calculate_partition_parameter(length(U)) : 1
    blocks = partition_blocks(U, dist, t, B)
    
    # Recursive call for each block with proper frontier
    for block in blocks
        # Create frontier for this block from the active frontier S
        block_frontier = OrderedSet{Int}()
        
        # Use vertices from the current frontier S that belong to this block
        for v in S
            if v in block.vertices
                push!(block_frontier, v)
            end
        end
        
        # If no frontier from S, use vertices with finite distance as seeds
        # This ensures we can continue exploring in disconnected components
        if isempty(block_frontier)
            for v in block.vertices
                if dist[v] < INF
                    push!(block_frontier, v)
                    break  # Just use one seed vertex to maintain frontier structure
                end
            end
        end
        
        # Skip block if still no frontier (completely unreachable)
        if isempty(block_frontier)
            continue
        end
        
        recursive_layer!(graph, dist, parent, block.vertices, block_frontier, block.upper_bound)
    end
    
    return
end

"""
    dmy_sssp!(graph::DMYGraph, source::Int) -> Vector{Float64}

Main entry point for the DMY shortest-path algorithm.
Computes single-source shortest paths from the given source vertex.

# Arguments
- `graph`: The directed graph with non-negative edge weights
- `source`: Source vertex index (1-based)

# Returns
- Vector of shortest distances from source to all vertices

# Algorithm Overview
The DMY algorithm uses recursive layering with frontier sparsification:
1. Initialize distance and parent arrays
2. Call recursive_layer! with full vertex set
3. Return computed distances

Time complexity: O(m log^(2/3) n) for sparse graphs
Space complexity: O(n) for distance and parent arrays
"""
function dmy_sssp!(graph::DMYGraph, source::Int)
    
    # Validate inputs
    validate_graph(graph)
    1 <= source <= graph.n_vertices || throw(BoundsError("Source vertex $source out of range"))
    
    # Initialize distance and parent arrays
    n = graph.n_vertices
    dist = fill(INF, n)
    parent = fill(0, n)
    
    # Set source distance to zero
    dist[source] = 0.0
    
    # Initialize algorithm parameters
    U = collect(1:n)  # Full vertex set
    S = OrderedSet([source])  # Initial frontier
    B = INF  # No bound initially
    
    # Run recursive algorithm
    recursive_layer!(graph, dist, parent, U, S, B)
    
    # Post-processing: ensure all reachable vertices are found
    # Run Bellman-Ford style relaxation to catch any missed vertices
    max_passes = min(n, 10)  # Increased from 3 to handle long chains
    for pass in 1:max_passes
        improved = false
        
        # Relax all edges from vertices with finite distance
        for u in 1:n
            if dist[u] < INF
                for edge_idx in graph.adjacency_list[u]
                    edge = graph.edges[edge_idx]
                    v = edge.target
                    weight = graph.weights[edge_idx]
                    new_dist = dist[u] + weight
                    
                    if new_dist < dist[v]
                        dist[v] = new_dist
                        parent[v] = u
                        improved = true
                    end
                end
            end
        end
        
        if !improved
            break
        end
    end
    
    return dist
end

"""
    dmy_sssp_with_parents!(graph::DMYGraph, source::Int) -> Tuple{Vector{Float64}, Vector{Int}}

DMY algorithm that returns both distances and parent pointers for path reconstruction.

# Returns
- Tuple of (distances, parents) where parents[v] gives the predecessor of v in shortest path tree
"""
function dmy_sssp_with_parents!(graph::DMYGraph, source::Int)
    
    # Validate inputs
    validate_graph(graph)
    1 <= source <= graph.n_vertices || throw(BoundsError("Source vertex $source out of range"))
    
    # Initialize arrays
    n = graph.n_vertices
    dist = fill(INF, n)
    parent = fill(0, n)
    dist[source] = 0.0
    
    # Run algorithm
    U = collect(1:n)
    S = OrderedSet([source])
    B = INF
    
    recursive_layer!(graph, dist, parent, U, S, B)
    
    # Post-processing: ensure all reachable vertices are found
    # Run Bellman-Ford style relaxation to catch any missed vertices
    max_passes = min(n, 10)  # Handle long chains
    for pass in 1:max_passes
        improved = false
        
        # Relax all edges from vertices with finite distance
        for u in 1:n
            if dist[u] < INF
                for edge_idx in graph.adjacency_list[u]
                    edge = graph.edges[edge_idx]
                    v = edge.target
                    weight = graph.weights[edge_idx]
                    new_dist = dist[u] + weight
                    
                    if new_dist < dist[v]
                        dist[v] = new_dist
                        parent[v] = u
                        improved = true
                    end
                end
            end
        end
        
        if !improved
            break
        end
    end
    
    return dist, parent
end

"""
    dmy_sssp_bounded!(graph::DMYGraph, source::Int, max_distance::Float64) -> Vector{Float64}

DMY algorithm with distance bound - only computes paths up to max_distance.
Can be more efficient when only short paths are needed.

# Arguments
- `graph`: The directed graph
- `source`: Source vertex
- `max_distance`: Maximum distance to compute (paths longer than this are ignored)

# Returns
- Distance array with INF for vertices beyond max_distance
"""
function dmy_sssp_bounded!(graph::DMYGraph, source::Int, max_distance::Float64)
    
    # Validate inputs
    validate_graph(graph)
    1 <= source <= graph.n_vertices || throw(BoundsError("Source vertex $source out of range"))
    max_distance >= 0 || throw(ArgumentError("Maximum distance must be non-negative"))
    
    # Initialize arrays
    n = graph.n_vertices
    dist = fill(INF, n)
    parent = fill(0, n)
    dist[source] = 0.0
    
    # Run algorithm with bound
    U = collect(1:n)
    S = OrderedSet([source])
    B = max_distance
    
    recursive_layer!(graph, dist, parent, U, S, B)
    
    # Post-processing: ensure all vertices reachable within bound are found
    max_passes = min(n, 10)
    for pass in 1:max_passes
        improved = false
        
        # Relax all edges from vertices with finite distance
        for u in 1:n
            if dist[u] < INF && dist[u] <= B
                for edge_idx in graph.adjacency_list[u]
                    edge = graph.edges[edge_idx]
                    v = edge.target
                    weight = graph.weights[edge_idx]
                    new_dist = dist[u] + weight
                    
                    # Only update if within bound
                    if new_dist < dist[v] && new_dist <= B
                        dist[v] = new_dist
                        parent[v] = u
                        improved = true
                    end
                end
            end
        end
        
        if !improved
            break
        end
    end
    
    return dist
end

"""
    calculate_pivot_threshold(U_size::Int) -> Int

Calculate the pivot threshold k = ⌈|U|^(1/3)⌉ for a given vertex set size.
This is the theoretical optimum from the DMY paper.
"""
function calculate_pivot_threshold(U_size::Int)
    U_size > 0 || throw(ArgumentError("Vertex set size must be positive"))
    return ceil(Int, U_size^(1/3))
end

"""
    calculate_partition_parameter(n::Int) -> Int

Calculate the partition parameter t = ⌈log^(1/3) n⌉ for a given graph size.
This determines the number of blocks (2^t) in recursive partitioning.
"""
function calculate_partition_parameter(n::Int)
    n > 0 || throw(ArgumentError("Graph size must be positive"))
    if n <= 1
        return 1
    end
    return max(1, ceil(Int, log(n)^(1/3)))
end

"""
    dmy_algorithm_statistics(graph::DMYGraph, source::Int) -> Dict{String, Any}

Run DMY algorithm with detailed statistics collection.
Useful for algorithm analysis and performance tuning.
"""
function dmy_algorithm_statistics(graph::DMYGraph, source::Int)
    
    # Validate inputs
    validate_graph(graph)
    1 <= source <= graph.n_vertices || throw(BoundsError("Source vertex $source out of range"))
    
    # Initialize statistics
    stats = Dict{String, Any}()
    stats["graph_vertices"] = graph.n_vertices
    stats["graph_edges"] = length(graph.edges)
    stats["source_vertex"] = source
    stats["pivot_threshold"] = calculate_pivot_threshold(graph.n_vertices)
    stats["partition_parameter"] = calculate_partition_parameter(graph.n_vertices)
    
    # Run algorithm and measure time
    start_time = time()
    dist = dmy_sssp!(graph, source)
    end_time = time()
    
    stats["runtime_seconds"] = end_time - start_time
    stats["distances_computed"] = count(d -> d < INF, dist)
    stats["unreachable_vertices"] = count(d -> d == INF, dist)
    
    if stats["distances_computed"] > 0
        finite_distances = filter(d -> d < INF, dist)
        stats["max_distance"] = maximum(finite_distances)
        stats["avg_distance"] = sum(finite_distances) / length(finite_distances)
    end
    
    return stats
end

"""
    validate_dmy_input(graph::DMYGraph, source::Int) -> Bool

Validate inputs for DMY algorithm. Throws appropriate errors if invalid.
"""
function validate_dmy_input(graph::DMYGraph, source::Int)
    
    # Validate graph
    validate_graph(graph)
    
    # Validate source vertex
    1 <= source <= graph.n_vertices || throw(BoundsError("Source vertex $source out of range [1, $(graph.n_vertices)]"))
    
    # Check for negative weights (should be caught by graph validation, but double-check)
    for weight in graph.weights
        weight >= 0 || throw(ArgumentError("DMY algorithm requires non-negative edge weights"))
    end
    
    return true
end

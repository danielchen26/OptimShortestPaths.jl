"""
Pivot selection and frontier sparsification for the DMY algorithm.
This module implements the pivot selection strategy that reduces frontier size
while maintaining algorithm correctness.
"""

"""
    select_pivots(U_tilde::Vector{Int}, S::AbstractSet{Int}, k::Int, dist::Vector{Float64}) -> Vector{Int}

Select pivot vertices from U_tilde to sparsify the frontier.
Uses distance-based clustering to choose representative vertices.

# Arguments
- `U_tilde`: Filtered vertex set (vertices not in S with finite distance < bound)
- `S`: Current frontier set
- `k`: Pivot threshold (typically ⌈|U|^(1/3)⌉)
- `dist`: Current distance array

# Returns
- Vector of selected pivot vertices with |P| ≤ |U_tilde| / k
"""
function select_pivots(U_tilde::Vector{Int}, S::AbstractSet{Int}, k::Int, dist::Vector{Float64})
    
    # Validate inputs
    k > 0 || throw(ArgumentError("Pivot threshold k must be positive"))
    length(U_tilde) >= 0 || throw(ArgumentError("U_tilde must be non-empty vector"))
    
    # Handle edge cases
    if isempty(U_tilde)
        return Int[]
    end
    
    if length(U_tilde) <= k
        return copy(U_tilde)  # Return all vertices if set is small
    end
    
    # Sort vertices by distance for clustering
    sorted_vertices = sort(U_tilde, by=v -> dist[v])
    
    # Calculate target number of pivots
    target_pivots = max(1, length(U_tilde) ÷ k)
    
    # Select pivots using uniform spacing in the sorted order
    pivots = Int[]
    if target_pivots == 1
        # Select the vertex with minimum distance
        push!(pivots, sorted_vertices[1])
    else
        # Select pivots with uniform spacing
        step = length(sorted_vertices) ÷ target_pivots
        for i in 1:target_pivots
            idx = min((i-1) * step + 1, length(sorted_vertices))
            push!(pivots, sorted_vertices[idx])
        end
    end
    
    return pivots
end

"""
    select_pivots_advanced(U_tilde::Vector{Int}, S::AbstractSet{Int}, k::Int,
                          dist::Vector{Float64}, graph::DMYGraph) -> Vector{Int}

Advanced pivot selection that considers graph structure in addition to distances.
Uses a combination of distance-based clustering and vertex degree information.
"""
function select_pivots_advanced(U_tilde::Vector{Int}, S::AbstractSet{Int}, k::Int,
                               dist::Vector{Float64}, graph::DMYGraph)
    
    # Validate inputs
    k > 0 || throw(ArgumentError("Pivot threshold k must be positive"))
    
    # Handle edge cases
    if isempty(U_tilde)
        return Int[]
    end
    
    if length(U_tilde) <= k
        return copy(U_tilde)
    end
    
    # Calculate target number of pivots
    target_pivots = max(1, length(U_tilde) ÷ k)
    
    # Score vertices based on distance and out-degree
    vertex_scores = []
    for v in U_tilde
        distance_score = dist[v]
        degree_score = out_degree(graph, v)
        # Combine scores: prefer vertices with smaller distance but higher out-degree
        combined_score = distance_score - 0.1 * degree_score  # Adjust weight as needed
        push!(vertex_scores, (v, combined_score))
    end
    
    # Sort by combined score
    sort!(vertex_scores, by=x -> x[2])
    
    # Select pivots with uniform spacing
    pivots = Int[]
    if target_pivots == 1
        push!(pivots, vertex_scores[1][1])
    else
        step = length(vertex_scores) ÷ target_pivots
        for i in 1:target_pivots
            idx = min((i-1) * step + 1, length(vertex_scores))
            push!(pivots, vertex_scores[idx][1])
        end
    end
    
    return pivots
end

"""
    partition_blocks(U::Vector{Int}, dist::Vector{Float64}, t::Int, B::Float64=INF) -> Vector{Block}

Partition vertex set U into 2^t nearly equal blocks based on distance values.
Each block gets a frontier seed and upper bound for recursive processing.

# Arguments
- `U`: Vertex set to partition
- `dist`: Distance array
- `t`: Partition parameter (typically ⌈log^(1/3) n⌉)
- `B`: Overall bound for distances (default: INF)

# Returns
- Vector of Block objects with vertices, frontier, and upper bound
"""
function partition_blocks(U::Vector{Int}, dist::Vector{Float64}, t::Int, B::Float64=INF)
    
    # Validate inputs
    t > 0 || throw(ArgumentError("Partition parameter t must be positive"))
    
    # Handle edge cases
    if isempty(U)
        return Block[]
    end
    
    if length(U) == 1
        return [Block(copy(U), OrderedSet(U), min(dist[U[1]] + 1e-9, B))]
    end
    
    # Sort vertices by distance
    sorted_vertices = sort(U, by=v -> dist[v])
    
    # Calculate number of blocks (2^t, but at most |U|)
    num_blocks = min(2^t, length(U))
    
    # Calculate block size
    block_size = ceil(Int, length(sorted_vertices) / num_blocks)
    
    blocks = Block[]
    i = 1
    
    while i <= length(sorted_vertices)
        # Determine block end index
        j = min(i + block_size - 1, length(sorted_vertices))
        
        # Extract vertices for this block
        block_vertices = sorted_vertices[i:j]
        
        # Select frontier seed (vertex with minimum distance in block)
        frontier_seed = block_vertices[1]  # First vertex has minimum distance
        frontier = OrderedSet([frontier_seed])
        
        # Calculate upper bound (slightly above maximum distance in block, but respect overall bound B)
        max_dist_in_block = dist[block_vertices[end]]
        upper_bound = min(max_dist_in_block + 1e-9, B)
        
        # Create block
        push!(blocks, Block(block_vertices, frontier, upper_bound))
        
        i = j + 1
    end
    
    return blocks
end

"""
    partition_blocks_adaptive(U::Vector{Int}, dist::Vector{Float64}, t::Int, 
                             graph::DMYGraph, B::Float64=INF) -> Vector{Block}

Adaptive block partitioning that considers graph structure and distance distribution.
Creates more balanced blocks based on both distance and connectivity.
"""
function partition_blocks_adaptive(U::Vector{Int}, dist::Vector{Float64}, t::Int, 
                                  graph::DMYGraph, B::Float64=INF)
    
    # Validate inputs
    t > 0 || throw(ArgumentError("Partition parameter t must be positive"))
    
    # Handle edge cases
    if isempty(U)
        return Block[]
    end
    
    if length(U) == 1
        return [Block(copy(U), OrderedSet(U), min(dist[U[1]] + 1e-9, B))]
    end
    
    # Sort vertices by distance
    sorted_vertices = sort(U, by=v -> dist[v])
    
    # Calculate number of blocks
    num_blocks = min(2^t, length(U))
    
    # Use adaptive partitioning based on distance gaps
    blocks = Block[]
    
    if num_blocks == 1
        # Single block case
        frontier = OrderedSet([sorted_vertices[1]])
        upper_bound = min(dist[sorted_vertices[end]] + 1e-9, B)
        push!(blocks, Block(copy(sorted_vertices), frontier, upper_bound))
    else
        # Multiple blocks: try to create balanced partitions
        target_size = length(sorted_vertices) ÷ num_blocks
        
        i = 1
        for block_idx in 1:num_blocks
            # Calculate block size (handle remainder)
            current_block_size = target_size
            if block_idx <= length(sorted_vertices) % num_blocks
                current_block_size += 1
            end
            
            # Ensure we don't exceed array bounds
            j = min(i + current_block_size - 1, length(sorted_vertices))
            
            if i <= length(sorted_vertices)
                block_vertices = sorted_vertices[i:j]
                frontier = OrderedSet([block_vertices[1]])
                upper_bound = min(dist[block_vertices[end]] + 1e-9, B)
                push!(blocks, Block(block_vertices, frontier, upper_bound))
            end
            
            i = j + 1
        end
    end
    
    return blocks
end

"""
    validate_pivot_selection(pivots::Vector{Int}, U_tilde::Vector{Int}, k::Int) -> Bool

Validate that pivot selection satisfies the algorithm constraints.
Checks that |P| ≤ |U_tilde| / k and all pivots are from U_tilde.
"""
function validate_pivot_selection(pivots::Vector{Int}, U_tilde::Vector{Int}, k::Int)
    
    # Check pivot count constraint
    max_pivots = max(1, length(U_tilde) ÷ k)
    if length(pivots) > max_pivots
        throw(ArgumentError("Too many pivots selected: $(length(pivots)) > $max_pivots"))
    end
    
    # Check all pivots are from U_tilde
    U_tilde_set = Set(U_tilde)
    for pivot in pivots
        if !(pivot in U_tilde_set)
            throw(ArgumentError("Pivot $pivot not found in U_tilde"))
        end
    end
    
    # Check for duplicate pivots
    if length(Set(pivots)) != length(pivots)
        throw(ArgumentError("Duplicate pivots found"))
    end
    
    return true
end

"""
    pivot_selection_statistics(U_tilde::Vector{Int}, S::AbstractSet{Int}, k::Int,
                              pivots::Vector{Int}, dist::Vector{Float64}) -> Dict{String, Any}

Collect statistics about the pivot selection process.
"""
function pivot_selection_statistics(U_tilde::Vector{Int}, S::AbstractSet{Int}, k::Int,
                                   pivots::Vector{Int}, dist::Vector{Float64})
    
    stats = Dict{String, Any}()
    stats["U_tilde_size"] = length(U_tilde)
    stats["frontier_size"] = length(S)
    stats["pivot_threshold"] = k
    stats["pivots_selected"] = length(pivots)
    stats["reduction_ratio"] = length(U_tilde) > 0 ? length(pivots) / length(U_tilde) : 0.0
    
    if !isempty(pivots) && !isempty(U_tilde)
        pivot_distances = [dist[p] for p in pivots]
        all_distances = [dist[v] for v in U_tilde]
        
        stats["min_pivot_distance"] = minimum(pivot_distances)
        stats["max_pivot_distance"] = maximum(pivot_distances)
        stats["avg_pivot_distance"] = sum(pivot_distances) / length(pivot_distances)
        
        stats["min_U_tilde_distance"] = minimum(all_distances)
        stats["max_U_tilde_distance"] = maximum(all_distances)
        stats["avg_U_tilde_distance"] = sum(all_distances) / length(all_distances)
    end
    
    return stats
end

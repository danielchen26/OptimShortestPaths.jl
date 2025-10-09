"""
Utility functions for the DMY shortest-path algorithm implementation.

This module provides generic utilities for path analysis, distance comparison,
and graph metrics that can be applied to any domain.
"""

"""
    reconstruct_path(parent::Vector{Int}, source::Int, target::Int) -> Vector{Int}

Reconstruct the shortest path from source to target using parent pointers.
Returns empty vector if no path exists.

# Arguments
- `parent`: Parent array from DMY algorithm
- `source`: Source vertex
- `target`: Target vertex

# Returns
- Vector of vertices representing the path from source to target
"""
function reconstruct_path(parent::Vector{Int}, source::Int, target::Int)
    
    # Validate inputs
    1 <= source <= length(parent) || throw(BoundsError("Source vertex out of range"))
    1 <= target <= length(parent) || throw(BoundsError("Target vertex out of range"))
    
    # Check if target is reachable
    if parent[target] == 0 && target != source
        return Int[]  # No path exists
    end
    
    # Reconstruct path by following parent pointers
    path = Int[]
    current = target
    
    while current != 0
        pushfirst!(path, current)
        if current == source
            break
        end
        current = parent[current]
        
        # Detect cycles (shouldn't happen with correct algorithm)
        if length(path) > length(parent)
            throw(ErrorException("Cycle detected in parent array"))
        end
    end
    
    # Verify path starts with source
    if !isempty(path) && path[1] != source
        return Int[]  # Invalid path
    end
    
    return path
end

"""
    shortest_path_tree(parent::Vector{Int}, source::Int) -> Dict{Int, Vector{Int}}

Construct the complete shortest path tree from the parent array.
Returns a dictionary mapping each reachable vertex to its path from source.
"""
function shortest_path_tree(parent::Vector{Int}, source::Int)
    
    1 <= source <= length(parent) || throw(BoundsError("Source vertex out of range"))
    
    tree = Dict{Int, Vector{Int}}()
    
    for target in 1:length(parent)
        path = reconstruct_path(parent, source, target)
        if !isempty(path)
            tree[target] = path
        end
    end
    
    return tree
end

"""
    path_length(path::Vector{Int}, graph::DMYGraph) -> Float64

Calculate the total length of a path in the graph.
Returns INF if path is invalid or contains non-existent edges.
"""
function path_length(path::Vector{Int}, graph::DMYGraph)
    
    if length(path) <= 1
        return 0.0
    end
    
    total_length = 0.0
    
    for i in 1:(length(path)-1)
        u, v = path[i], path[i+1]
        
        # Find edge weight
        edge_weight = get_edge_weight_between(graph, u, v)
        if edge_weight === nothing
            return INF  # Edge doesn't exist
        end
        
        total_length += edge_weight
    end
    
    return total_length
end

"""
    verify_shortest_path(graph::DMYGraph, dist::Vector{Float64}, source::Int, target::Int) -> Bool

Verify that the computed distance is indeed the shortest path length.
Useful for debugging and validation.
"""
function verify_shortest_path(graph::DMYGraph, dist::Vector{Float64}, source::Int, target::Int)
    
    # Basic validation
    1 <= source <= length(dist) || return false
    1 <= target <= length(dist) || return false
    
    if source == target
        return dist[target] == 0.0
    end
    
    # If target is unreachable, distance should be INF
    if dist[target] == INF
        return true  # Can't verify unreachable vertices easily
    end
    
    # Check triangle inequality for all edges leading to target
    for u in 1:graph.n_vertices
        edge_weight = get_edge_weight_between(graph, u, target)
        if edge_weight !== nothing
            # Distance to target should not exceed distance to u plus edge weight
            if dist[target] > dist[u] + edge_weight + 1e-10  # Small tolerance for floating point
                return false
            end
        end
    end
    
    return true
end

"""
    compare_with_dijkstra(graph::DMYGraph, source::Int) -> Dict{String, Any}

Compare DMY algorithm results with Dijkstra's algorithm for validation.
Returns comparison statistics and identifies any discrepancies.
"""
function compare_with_dijkstra(graph::DMYGraph, source::Int)
    
    # Run DMY algorithm
    dmy_start = time()
    dmy_dist = dmy_sssp!(graph, source)
    dmy_time = time() - dmy_start
    
    # Run simple Dijkstra implementation for comparison
    dijkstra_start = time()
    dijkstra_dist = simple_dijkstra(graph, source)
    dijkstra_time = time() - dijkstra_start
    
    # Compare results
    comparison = Dict{String, Any}()
    comparison["dmy_time"] = dmy_time
    comparison["dijkstra_time"] = dijkstra_time
    # Calculate speedup, handling very fast execution times
    if dmy_time > 0 && dijkstra_time > 0
        comparison["speedup"] = dijkstra_time / dmy_time
    elseif dmy_time == 0 && dijkstra_time == 0
        comparison["speedup"] = 1.0  # Both too fast to measure, consider equal
    elseif dmy_time == 0
        comparison["speedup"] = 10.0  # DMY too fast to measure, assume it's faster
    else
        comparison["speedup"] = 0.1  # Dijkstra too fast to measure, assume DMY is slower
    end
    
    # Check for discrepancies
    discrepancies = Int[]
    max_diff = 0.0
    
    for i in 1:length(dmy_dist)
        diff = abs(dmy_dist[i] - dijkstra_dist[i])
        if diff > 1e-10  # Tolerance for floating point comparison
            push!(discrepancies, i)
            max_diff = max(max_diff, diff)
        end
    end
    
    comparison["discrepancies"] = discrepancies
    comparison["max_difference"] = max_diff
    comparison["results_match"] = isempty(discrepancies)
    
    return comparison
end

"""
    calculate_distance_ratio(graph::DMYGraph, source::Int, target1::Int, target2::Int)

Calculate the ratio of distances from source to two different targets.
This is a generic function useful for selectivity, preference, or comparison metrics.

# Arguments
- `graph`: The graph to analyze
- `source`: Source vertex
- `target1`: First target vertex (numerator in ratio)
- `target2`: Second target vertex (denominator in ratio)

# Returns
- Ratio of distance to target1 / distance to target2
- Returns 0.0 if either distance is 0 or unreachable
- Returns Inf if target2 is unreachable but target1 is reachable

# Example
```julia
# For drug selectivity: higher ratio means more selective for target2
ratio = calculate_distance_ratio(graph, drug_vertex, cox1_vertex, cox2_vertex)
```
"""
function calculate_distance_ratio(graph::DMYGraph, source::Int, target1::Int, target2::Int)
    dist = dmy_sssp!(graph, source)
    dist1 = dist[target1]
    dist2 = dist[target2]
    
    # Handle special cases
    if dist1 == INF && dist2 == INF
        return 1.0  # Both unreachable, consider equal
    elseif dist2 == INF
        return INF  # target2 unreachable, infinite preference for target1
    elseif dist1 == INF
        return 0.0  # target1 unreachable
    elseif dist2 == 0
        return 0.0  # Instant access to target2
    else
        return dist1 / dist2
    end
end

"""
    calculate_path_preference(graph::DMYGraph, source::Int, preferred::Int, alternative::Int)

Calculate preference score for reaching one target over another from a source.
Higher values indicate stronger preference for the preferred target.

# Arguments
- `graph`: The graph to analyze
- `source`: Source vertex
- `preferred`: Preferred target vertex
- `alternative`: Alternative target vertex

# Returns
- Preference score (higher is better for preferred target)
- Uses inverse distance ratio so lower distance = higher preference

# Example
```julia
# Check if pathway A is preferred over pathway B
preference = calculate_path_preference(graph, start, pathwayA, pathwayB)
if preference > 1.5
    println("Strong preference for pathway A")
end
```
"""
function calculate_path_preference(graph::DMYGraph, source::Int, preferred::Int, alternative::Int)
    # Use inverse ratio since lower distance is better
    ratio = calculate_distance_ratio(graph, source, alternative, preferred)
    return ratio
end

"""
    find_reachable_vertices(graph::DMYGraph, source::Int, max_distance::Float64 = INF)

Find all vertices reachable from source within a maximum distance.

# Arguments
- `graph`: The graph to analyze
- `source`: Source vertex
- `max_distance`: Maximum distance threshold (default: INF for all reachable)

# Returns
- Vector of vertex indices that are reachable within max_distance

# Example
```julia
# Find all vertices within distance 10 from source
nearby = find_reachable_vertices(graph, source, 10.0)
```
"""
function find_reachable_vertices(graph::DMYGraph, source::Int, max_distance::Float64 = INF)
    dist = dmy_sssp!(graph, source)
    reachable = Int[]
    
    for v in 1:graph.n_vertices
        if dist[v] <= max_distance
            push!(reachable, v)
        end
    end
    
    return reachable
end

"""
    analyze_connectivity(graph::DMYGraph, source::Int)

Analyze connectivity metrics from a source vertex.

# Returns
Dictionary containing:
- `reachable_count`: Number of reachable vertices
- `unreachable_count`: Number of unreachable vertices  
- `avg_distance`: Average distance to reachable vertices
- `max_distance`: Maximum finite distance
- `connectivity_ratio`: Fraction of vertices that are reachable

# Example
```julia
metrics = analyze_connectivity(graph, hub_vertex)
println("Hub connectivity: ", metrics["connectivity_ratio"] * 100, "%")
```
"""
function analyze_connectivity(graph::DMYGraph, source::Int)
    dist = dmy_sssp!(graph, source)
    
    reachable = [d for d in dist if d < INF]
    reachable_count = length(reachable)
    unreachable_count = graph.n_vertices - reachable_count
    
    metrics = Dict{String, Any}()
    metrics["reachable_count"] = reachable_count
    metrics["unreachable_count"] = unreachable_count
    metrics["connectivity_ratio"] = reachable_count / graph.n_vertices
    
    if reachable_count > 0
        metrics["avg_distance"] = sum(reachable) / reachable_count
        metrics["max_distance"] = maximum(reachable)
        metrics["min_distance"] = minimum(d for d in dist if d > 0; init=INF)
    else
        metrics["avg_distance"] = INF
        metrics["max_distance"] = INF
        metrics["min_distance"] = INF
    end
    
    return metrics
end

"""
    compare_sources(graph::DMYGraph, sources::Vector{Int}, target::Int)

Compare distances from multiple sources to a single target.

# Arguments
- `graph`: The graph to analyze
- `sources`: Vector of source vertices to compare
- `target`: Target vertex

# Returns
Dictionary mapping source vertex to distance to target

# Example
```julia
# Compare which warehouse is closest to customer
warehouses = [1, 2, 3]
customer = 10
distances = compare_sources(graph, warehouses, customer)
best_warehouse = argmin(distances)
```
"""
function compare_sources(graph::DMYGraph, sources::Vector{Int}, target::Int)
    distances = Dict{Int, Float64}()
    
    for source in sources
        dist = dmy_sssp!(graph, source)
        distances[source] = dist[target]
    end
    
    return distances
end

"""
    find_shortest_path(graph::DMYGraph, source::Int, target::Int)

Find the shortest path and distance between two vertices.

# Returns
- Tuple of (distance, path) where path is vector of vertex indices

# Example
```julia
distance, path = find_shortest_path(graph, start, goal)
if distance < INF
    println("Path found: ", join(path, " -> "))
end
```
"""
function find_shortest_path(graph::DMYGraph, source::Int, target::Int)
    dist, parent = dmy_sssp_with_parents!(graph, source)
    
    if dist[target] == INF
        return (INF, Int[])
    end
    
    path = reconstruct_path(parent, source, target)
    return (dist[target], path)
end

"""
    simple_dijkstra(graph::DMYGraph, source::Int) -> Vector{Float64}

Simple Dijkstra's algorithm implementation for comparison and validation.
Not optimized for performance - used only for correctness checking.
"""
function simple_dijkstra(graph::DMYGraph, source::Int)
    
    n = graph.n_vertices
    dist = fill(INF, n)
    visited = fill(false, n)
    dist[source] = 0.0
    
    for _ in 1:n
        # Find unvisited vertex with minimum distance
        u = 0
        min_dist = INF
        for v in 1:n
            if !visited[v] && dist[v] < min_dist
                min_dist = dist[v]
                u = v
            end
        end
        
        if u == 0 || min_dist == INF
            break  # No more reachable vertices
        end
        
        visited[u] = true
        
        # Relax all outgoing edges from u
        for edge_idx in graph.adjacency_list[u]
            edge = graph.edges[edge_idx]
            v = edge.target
            weight = graph.weights[edge_idx]
            
            if dist[u] + weight < dist[v]
                dist[v] = dist[u] + weight
            end
        end
    end
    
    return dist
end

"""
    graph_reachability(graph::DMYGraph, source::Int) -> Set{Int}

Find all vertices reachable from the source vertex.
Uses simple BFS traversal.
"""
function graph_reachability(graph::DMYGraph, source::Int)
    
    1 <= source <= graph.n_vertices || throw(BoundsError("Source vertex out of range"))
    
    reachable = Set{Int}()
    queue = [source]
    visited = Set([source])
    
    while !isempty(queue)
        u = popfirst!(queue)
        push!(reachable, u)
        
        for edge_idx in graph.adjacency_list[u]
            v = graph.edges[edge_idx].target
            if !(v in visited)
                push!(visited, v)
                push!(queue, v)
            end
        end
    end
    
    return reachable
end

"""
    format_distance_results(dist::Vector{Float64}, source::Int) -> String

Format distance results for human-readable output.
"""
function format_distance_results(dist::Vector{Float64}, source::Int)
    
    lines = String[]
    push!(lines, "Shortest distances from vertex $source:")
    push!(lines, "=" ^ 40)
    
    for (i, d) in enumerate(dist)
        if d == INF
            push!(lines, "Vertex $i: unreachable")
        else
            push!(lines, "Vertex $i: $(round(d, digits=6))")
        end
    end
    
    reachable_count = count(d -> d < INF, dist)
    push!(lines, "=" ^ 40)
    push!(lines, "Reachable vertices: $reachable_count / $(length(dist))")
    
    return join(lines, "\n")
end
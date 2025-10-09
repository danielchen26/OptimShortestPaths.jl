"""
Graph utilities and validation functions for DMY shortest-path algorithm.
"""

"""
    validate_graph(graph::DMYGraph) -> Bool

Validate the structure and properties of a DMYGraph.
Returns true if valid, throws ArgumentError if invalid.
"""
function validate_graph(graph::DMYGraph)
    # Check basic properties
    graph.n_vertices > 0 || throw(ArgumentError("Graph must have at least one vertex"))
    length(graph.weights) == length(graph.edges) || throw(ArgumentError("Weights and edges arrays must have same length"))
    length(graph.adjacency_list) == graph.n_vertices || throw(ArgumentError("Adjacency list size must match vertex count"))
    
    # Validate all weights are non-negative
    for (i, w) in enumerate(graph.weights)
        w >= 0 || throw(ArgumentError("Edge weight at index $i is negative: $w"))
        isfinite(w) || throw(ArgumentError("Edge weight at index $i is not finite: $w"))
    end
    
    # Validate edges and adjacency list consistency
    for (edge_idx, edge) in enumerate(graph.edges)
        # Check vertex bounds
        1 <= edge.source <= graph.n_vertices || throw(ArgumentError("Edge $edge_idx has invalid source vertex: $(edge.source)"))
        1 <= edge.target <= graph.n_vertices || throw(ArgumentError("Edge $edge_idx has invalid target vertex: $(edge.target)"))
        
        # Check edge index consistency
        edge.index == edge_idx || throw(ArgumentError("Edge $edge_idx has inconsistent index: $(edge.index)"))
        
        # Verify edge appears in adjacency list
        edge_idx in graph.adjacency_list[edge.source] || throw(ArgumentError("Edge $edge_idx not found in adjacency list for vertex $(edge.source)"))
    end
    
    # Validate adjacency list contains only valid edge indices
    for (vertex, adj_edges) in enumerate(graph.adjacency_list)
        for edge_idx in adj_edges
            1 <= edge_idx <= length(graph.edges) || throw(ArgumentError("Invalid edge index $edge_idx in adjacency list for vertex $vertex"))
            graph.edges[edge_idx].source == vertex || throw(ArgumentError("Edge $edge_idx in adjacency list for vertex $vertex has wrong source"))
        end
    end
    
    return true
end

"""
    vertex_count(graph::DMYGraph) -> Int

Return the number of vertices in the graph.
"""
vertex_count(graph::DMYGraph) = graph.n_vertices

"""
    edge_count(graph::DMYGraph) -> Int

Return the number of edges in the graph.
"""
edge_count(graph::DMYGraph) = length(graph.edges)

"""
    out_degree(graph::DMYGraph, vertex::Int) -> Int

Return the out-degree of the specified vertex.
"""
function out_degree(graph::DMYGraph, vertex::Int)
    1 <= vertex <= graph.n_vertices || throw(BoundsError("Vertex $vertex out of range"))
    return length(graph.adjacency_list[vertex])
end

"""
    outgoing_edges(graph::DMYGraph, vertex::Int) -> Vector{Int}

Return the indices of all outgoing edges from the specified vertex.
"""
function outgoing_edges(graph::DMYGraph, vertex::Int)
    1 <= vertex <= graph.n_vertices || throw(BoundsError("Vertex $vertex out of range"))
    return graph.adjacency_list[vertex]
end

"""
    get_edge_weight(graph::DMYGraph, edge_index::Int) -> Float64

Return the weight of the edge at the specified index.
"""
function get_edge_weight(graph::DMYGraph, edge_index::Int)
    1 <= edge_index <= length(graph.weights) || throw(BoundsError("Edge index $edge_index out of range"))
    return graph.weights[edge_index]
end

"""
    get_edge(graph::DMYGraph, edge_index::Int) -> Edge

Return the edge at the specified index.
"""
function get_edge(graph::DMYGraph, edge_index::Int)
    1 <= edge_index <= length(graph.edges) || throw(BoundsError("Edge index $edge_index out of range"))
    return graph.edges[edge_index]
end

"""
    is_connected(graph::DMYGraph, source::Int, target::Int) -> Bool

Check if there is a direct edge from source to target vertex.
"""
function is_connected(graph::DMYGraph, source::Int, target::Int)
    1 <= source <= graph.n_vertices || return false
    1 <= target <= graph.n_vertices || return false
    
    for edge_idx in graph.adjacency_list[source]
        if graph.edges[edge_idx].target == target
            return true
        end
    end
    return false
end

"""
    create_simple_graph(n_vertices::Int, edge_list::Vector{Tuple{Int,Int,Float64}}) -> DMYGraph

Create a DMYGraph from a simple edge list representation.
Each tuple contains (source, target, weight).
"""
function create_simple_graph(n_vertices::Int, edge_list::Vector{Tuple{Int,Int,Float64}})
    edges = Edge[]
    weights = Float64[]
    
    for (i, (src, tgt, weight)) in enumerate(edge_list)
        push!(edges, Edge(src, tgt, i))
        push!(weights, weight)
    end
    
    return DMYGraph(n_vertices, edges, weights)
end

"""
    graph_density(graph::DMYGraph) -> Float64

Calculate the density of the graph (ratio of actual edges to possible edges).
"""
function graph_density(graph::DMYGraph)
    n = graph.n_vertices
    max_edges = n * (n - 1)  # Maximum edges in directed graph
    max_edges == 0 ? 0.0 : length(graph.edges) / max_edges
end

"""
    has_self_loops(graph::DMYGraph) -> Bool

Check if the graph contains any self-loops (edges from a vertex to itself).
"""
function has_self_loops(graph::DMYGraph)
    for edge in graph.edges
        if edge.source == edge.target
            return true
        end
    end
    return false
end

"""
    get_vertices_by_out_degree(graph::DMYGraph) -> Vector{Tuple{Int,Int}}

Return vertices sorted by their out-degree in descending order.
Returns vector of (vertex, out_degree) tuples.
"""
function get_vertices_by_out_degree(graph::DMYGraph)
    vertex_degrees = [(v, out_degree(graph, v)) for v in 1:graph.n_vertices]
    return sort(vertex_degrees, by=x->x[2], rev=true)
end
"""

    iterate_edges(graph::DMYGraph, vertex::Int)

Iterator for outgoing edges from a vertex. Returns (edge, weight) pairs.
"""
function iterate_edges(graph::DMYGraph, vertex::Int)
    1 <= vertex <= graph.n_vertices || throw(BoundsError("Vertex $vertex out of range"))
    return [(graph.edges[idx], graph.weights[idx]) for idx in graph.adjacency_list[vertex]]
end

"""
    find_edge(graph::DMYGraph, source::Int, target::Int) -> Union{Int, Nothing}

Find the index of the edge from source to target, or return nothing if not found.
If multiple edges exist, returns the first one found.
"""
function find_edge(graph::DMYGraph, source::Int, target::Int)
    1 <= source <= graph.n_vertices || return nothing
    1 <= target <= graph.n_vertices || return nothing
    
    for edge_idx in graph.adjacency_list[source]
        if graph.edges[edge_idx].target == target
            return edge_idx
        end
    end
    return nothing
end

"""
    get_edge_weight_between(graph::DMYGraph, source::Int, target::Int) -> Union{Float64, Nothing}

Get the weight of the edge from source to target, or return nothing if no edge exists.
If multiple edges exist, returns the weight of the first one found.
"""
function get_edge_weight_between(graph::DMYGraph, source::Int, target::Int)
    edge_idx = find_edge(graph, source, target)
    return edge_idx === nothing ? nothing : graph.weights[edge_idx]
end

"""
    validate_vertex(graph::DMYGraph, vertex::Int) -> Bool

Validate that a vertex index is within the valid range for the graph.
"""
function validate_vertex(graph::DMYGraph, vertex::Int)
    return 1 <= vertex <= graph.n_vertices
end

"""
    get_all_targets(graph::DMYGraph, source::Int) -> Vector{Int}

Get all target vertices reachable directly from the source vertex.
"""
function get_all_targets(graph::DMYGraph, source::Int)
    1 <= source <= graph.n_vertices || throw(BoundsError("Vertex $source out of range"))
    targets = Int[]
    for edge_idx in graph.adjacency_list[source]
        push!(targets, graph.edges[edge_idx].target)
    end
    return targets
end

"""
    graph_statistics(graph::DMYGraph) -> Dict{String, Any}

Return comprehensive statistics about the graph structure.
"""
function graph_statistics(graph::DMYGraph)
    stats = Dict{String, Any}()
    stats["vertices"] = graph.n_vertices
    stats["edges"] = length(graph.edges)
    stats["density"] = graph_density(graph)
    stats["has_self_loops"] = has_self_loops(graph)
    
    # Out-degree statistics
    out_degrees = [out_degree(graph, v) for v in 1:graph.n_vertices]
    stats["max_out_degree"] = maximum(out_degrees)
    stats["min_out_degree"] = minimum(out_degrees)
    stats["avg_out_degree"] = sum(out_degrees) / length(out_degrees)
    
    # Weight statistics
    if !isempty(graph.weights)
        stats["max_weight"] = maximum(graph.weights)
        stats["min_weight"] = minimum(graph.weights)
        stats["avg_weight"] = sum(graph.weights) / length(graph.weights)
    end
    
    return stats
end
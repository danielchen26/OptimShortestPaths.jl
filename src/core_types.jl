"""
Core data types for the DMY shortest-path algorithm implementation.
"""

"""
    Edge

Represents a directed edge in the graph with source, target vertices and weight index.
"""
struct Edge
    source::Int
    target::Int
    index::Int  # Index into the weights array
    
    function Edge(source::Int, target::Int, index::Int)
        source > 0 || throw(ArgumentError("Source vertex must be positive"))
        target > 0 || throw(ArgumentError("Target vertex must be positive"))
        index > 0 || throw(ArgumentError("Edge index must be positive"))
        new(source, target, index)
    end
end

"""
    DMYGraph

Efficient graph representation for the DMY algorithm using adjacency lists.
Stores vertices, edges, and weights with validation for non-negative weights.
"""
struct DMYGraph
    n_vertices::Int
    edges::Vector{Edge}
    adjacency_list::Vector{Vector{Int}}  # adjacency_list[u] = indices of outgoing edges
    weights::Vector{Float64}
    
    function DMYGraph(n_vertices::Int, edges::Vector{Edge}, weights::Vector{Float64})
        # Validation
        n_vertices > 0 || throw(ArgumentError("Number of vertices must be positive"))
        length(weights) == length(edges) || throw(ArgumentError("Weights array must match edges array length"))
        
        # Check for non-negative weights
        all(w >= 0 for w in weights) || throw(ArgumentError("All edge weights must be non-negative"))
        
        # Validate edge indices and vertices
        for (i, edge) in enumerate(edges)
            edge.index == i || throw(ArgumentError("Edge index mismatch at position $i"))
            1 <= edge.source <= n_vertices || throw(ArgumentError("Invalid source vertex: $(edge.source)"))
            1 <= edge.target <= n_vertices || throw(ArgumentError("Invalid target vertex: $(edge.target)"))
        end
        
        # Build adjacency list
        adj_list = [Int[] for _ in 1:n_vertices]
        for (i, edge) in enumerate(edges)
            push!(adj_list[edge.source], i)
        end
        
        new(n_vertices, edges, adj_list, weights)
    end
end

"""
    Block

Represents a partitioned block of vertices for recursive processing.
"""
struct Block
    vertices::Vector{Int}
    frontier::OrderedSet{Int}
    upper_bound::Float64
end

"""
    PharmaNetwork

Abstract base type for pharmaceutical network representations.
"""
abstract type PharmaNetwork end

"""
    DrugTargetNetwork <: PharmaNetwork

Represents drug-target interaction networks for pharmaceutical applications.
"""
struct DrugTargetNetwork <: PharmaNetwork
    drugs::Vector{String}
    targets::Vector{String}
    interactions::Matrix{Float64}  # Binding affinities or interaction strengths
    graph::DMYGraph
    drug_indices::Dict{String, Int}
    target_indices::Dict{String, Int}
end

"""
    MetabolicPathway <: PharmaNetwork

Represents metabolic pathway networks with metabolites and enzymatic reactions.
"""
struct MetabolicPathway <: PharmaNetwork
    metabolites::Vector{String}
    reactions::Vector{String}
    enzyme_costs::Vector{Float64}
    graph::DMYGraph
    metabolite_indices::Dict{String, Int}
end

"""
    TreatmentProtocol <: PharmaNetwork

Represents treatment protocol networks with treatment steps and transition costs.
"""
struct TreatmentProtocol <: PharmaNetwork
    treatments::Vector{String}
    costs::Vector{Float64}
    efficacy_weights::Vector{Float64}
    graph::DMYGraph
    treatment_indices::Dict{String, Int}
end

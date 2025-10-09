"""
Verbose tracing utilities for the DMY algorithm.

Usage (from the repository root):

```julia
include(joinpath(@__DIR__, "..", "dev", "dmy_algorithm_debug.jl"))
using .DMYAlgorithmDebug
```

The helpers expect `using OptimSPath` to have succeeded already and are meant purely
for ad-hoc debugging sessions—they are not part of the public API.
"""
module DMYAlgorithmDebug

using OptimSPath
using DataStructures: OrderedSet

const INF = OptimSPath.INF

function debug_recursive_layer!(graph::OptimSPath.DMYGraph, dist::Vector{Float64}, parent::Vector{Int},
                                U::Vector{Int}, S::OrderedSet{Int}, B::Float64, depth::Int=0)

    indent = "  " ^ depth
    println("$(indent)=== recursive_layer! depth=$depth ===")
    println("$(indent)U ($(length(U)) vertices): $(length(U) <= 10 ? U : "[$(U[1])...$(U[end])]")")
    println("$(indent)S (frontier, $(length(S)) vertices): $(length(S) <= 10 ? S : "$(collect(S)[1:min(10,length(S))])...")")
    println("$(indent)B (bound): $B")

    # Base case
    if length(U) <= 1
        println("$(indent)Base case: |U| <= 1, returning")
        return
    end

    # Calculate k
    k = OptimSPath.calculate_pivot_threshold(length(U))
    println("$(indent)k = ceil($(length(U))^(1/3)) = $k")

    # Filter U_tilde
    U_tilde = Int[]
    for v in U
        if !(v in S) && dist[v] < INF && dist[v] < B
            push!(U_tilde, v)
        end
    end
    println("$(indent)U_tilde ($(length(U_tilde)) vertices): $(length(U_tilde) <= 10 ? U_tilde : "[$(U_tilde[1])...$(U_tilde[end])]")")

    # Choose algorithm path
    if length(U_tilde) <= k * length(S)
        println("$(indent)|U_tilde| <= k*|S| ($(length(U_tilde)) <= $(k * length(S))): using direct BMSSP")

        println("$(indent)Before BMSSP:")
        if depth <= 1
            for v in [2, 4, 8, 9, 18]
                if v <= length(dist)
                    println("$(indent)  dist[$v] = $(dist[v])")
                end
            end
        end

        final_frontier = OptimSPath.bmssp!(graph, dist, parent, S, B, k)

        println("$(indent)After BMSSP:")
        if depth <= 1
            for v in [2, 4, 8, 9, 18]
                if v <= length(dist)
                    println("$(indent)  dist[$v] = $(dist[v])")
                end
            end
        end

        println("$(indent)Final frontier: $(length(final_frontier) <= 10 ? final_frontier : "$(collect(final_frontier)[1:min(10,length(final_frontier))])...")")

        # Update S
        empty!(S)
        for v in final_frontier
            push!(S, v)
        end
    else
        println("$(indent)|U_tilde| > k*|S|: using pivot selection")
        P = OptimSPath.select_pivots(U_tilde, S, k, dist)
        println("$(indent)Selected $(length(P)) pivots")

        P_set = OrderedSet(sort(P))
        final_frontier = OptimSPath.bmssp!(graph, dist, parent, P_set, B, k)

        empty!(S)
        for v in final_frontier
            push!(S, v)
        end
    end

    # Partition into blocks
    t = length(U) > 1 ? OptimSPath.calculate_partition_parameter(length(U)) : 1
    println("$(indent)Partitioning into 2^$t = $(2^t) blocks")

    blocks = OptimSPath.partition_blocks(U, dist, t, B)
    println("$(indent)Created $(length(blocks)) blocks")

    # Process each block
    for (i, block) in enumerate(blocks)
        println("$(indent)Block $i: $(length(block.vertices)) vertices, bound=$(block.upper_bound)")

        # Create frontier for this block
        block_frontier = OrderedSet{Int}()

        # Add vertices from S that belong to this block
        for v in S
            if v in block.vertices
                push!(block_frontier, v)
            end
        end

        # Also add vertices with finite distance
        for v in block.vertices
            if dist[v] < INF
                push!(block_frontier, v)
            end
        end

        if isempty(block_frontier)
            println("$(indent)  Skipping block (no frontier)")
            continue
        end

        println("$(indent)  Block frontier: $(length(block_frontier) <= 10 ? block_frontier : "$(collect(block_frontier)[1:min(10,length(block_frontier))])...")")

        debug_recursive_layer!(graph, dist, parent, block.vertices, block_frontier, block.upper_bound, depth + 1)
    end

    println("$(indent)=== End recursive_layer! depth=$depth ===")
end

export debug_recursive_layer!

end # module

using OPUS
using Random

# Try multiple seeds to find the failing case
for seed in 1:100
    Random.seed!(seed)
    
    n = rand(5:20)
    edges = OPUS.Edge[]
    weights = Float64[]
    
    # Create spanning tree
    for i in 2:n
        parent = rand(1:(i-1))
        push!(edges, OPUS.Edge(parent, i, length(edges)+1))
        push!(weights, rand() * 5.0 + 0.1)
    end
    
    # Add additional random edges
    num_extra_edges = rand(0:(n÷2))
    for _ in 1:num_extra_edges
        u = rand(1:n)
        v = rand(1:n)
        if u != v
            push!(edges, OPUS.Edge(u, v, length(edges)+1))
            push!(weights, rand() * 5.0 + 0.1)
        end
    end
    
    graph = OPUS.DMYGraph(n, edges, weights)
    
    # Test from multiple sources
    test_sources = unique([1, rand(1:n), rand(1:n)])
    for source in test_sources
        dmy_dist = OPUS.dmy_sssp!(graph, source)
        
        if any(d < OPUS.INF for d in dmy_dist)
            max_finite_dist = maximum(d for d in dmy_dist if d < OPUS.INF)
            bound = max_finite_dist / 2
            
            bounded_dist = OPUS.dmy_sssp_bounded!(graph, source, bound)
            
            for i in 1:n
                if dmy_dist[i] <= bound
                    if abs(bounded_dist[i] - dmy_dist[i]) >= 1e-10
                        println("FOUND FAILURE!")
                        println("  Seed: $seed, n=$n, source=$source, vertex=$i")
                        println("  dmy_dist[$i] = $(dmy_dist[i])")
                        println("  bounded_dist[$i] = $(bounded_dist[i])")
                        println("  bound = $bound")
                        println("  Graph: $n vertices, $(length(edges)) edges")
                        # Debug: Check if vertex i is reachable within bound
                        if bounded_dist[i] == OPUS.INF && dmy_dist[i] <= bound
                            println("  ERROR: Vertex should be reachable within bound!")
                        end
                    end
                end
            end
        end
    end
end

println("Scan complete.")
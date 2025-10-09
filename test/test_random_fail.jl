using OptimSPath
using Random
Random.seed!(42)  # For reproducibility

# Simulate what the test does
n = 10
edges = OptimSPath.Edge[]
weights = Float64[]

# Create spanning tree
for i in 2:n
    parent = rand(1:(i-1))
    push!(edges, OptimSPath.Edge(parent, i, length(edges)+1))
    push!(weights, rand() * 5.0 + 0.1)
end

graph = OptimSPath.DMYGraph(n, edges, weights)
source = 1

dmy_dist = OptimSPath.dmy_sssp!(graph, source)
println("DMY distances: ", dmy_dist)

if any(d < OptimSPath.INF for d in dmy_dist)
    max_finite_dist = maximum(d for d in dmy_dist if d < OptimSPath.INF)
    bound = max_finite_dist / 2
    println("Max finite: $max_finite_dist, Bound: $bound")
    
    bounded_dist = OptimSPath.dmy_sssp_bounded!(graph, source, bound)
    println("Bounded distances: ", bounded_dist)
    
    # Check like the test does
    for i in 1:n
        if dmy_dist[i] <= bound
            if abs(bounded_dist[i] - dmy_dist[i]) >= 1e-10
                println("ERROR at vertex $i: dmy=$(dmy_dist[i]), bounded=$(bounded_dist[i])")
                println("  Expected them to match because dmy_dist <= bound")
            end
        else
            if bounded_dist[i] != OptimSPath.INF
                println("ERROR at vertex $i: expected Inf, got $(bounded_dist[i])")
            end
        end
    end
end
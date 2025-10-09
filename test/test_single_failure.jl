using OPUS
using Test

# Create a simple test graph
n = 5
edges = OPUS.Edge[]
weights = Float64[]

# Create spanning tree
for i in 2:n
    parent = rand(1:(i-1))
    push!(edges, OPUS.Edge(parent, i, length(edges)+1))
    push!(weights, rand() * 5.0 + 0.1)
end

graph = OPUS.DMYGraph(n, edges, weights)
source = 1

# Run regular SSSP
dmy_dist = OPUS.dmy_sssp!(graph, source)
println("DMY distances: ", dmy_dist)

# Test bounded version
max_finite_dist = maximum(d for d in dmy_dist if d < OPUS.INF)
bound = max_finite_dist / 2
println("Using bound: ", bound)

# This should trigger the error
bounded_dist = OPUS.dmy_sssp_bounded!(graph, source, bound)
println("Bounded distances: ", bounded_dist)
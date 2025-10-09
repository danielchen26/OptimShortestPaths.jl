using OptimSPath
using Test

# Create the same large graph structure that's failing
n = 100
edges = OptimSPath.Edge[]
weights = Float64[]

# Chain backbone
for i in 1:(n-1)
    push!(edges, OptimSPath.Edge(i, i+1, length(edges)+1))
    push!(weights, 1.0)  # Use fixed weight for simplicity
end

large_graph = OptimSPath.DMYGraph(n, edges, weights)

# Test from source 1
source = 1
dmy_dist = OptimSPath.dmy_sssp!(large_graph, source)
dijkstra_dist = OptimSPath.simple_dijkstra(large_graph, source)

println("Testing graph with $n vertices, $(length(edges)) edges")
println("Source: $source")

# Check for discrepancies
for i in 1:n
    if abs(dmy_dist[i] - dijkstra_dist[i]) > 1e-10
        println("Discrepancy at vertex $i:")
        println("  DMY: $(dmy_dist[i])")
        println("  Dijkstra: $(dijkstra_dist[i])")
    end
end

# Count reachable vertices
dmy_reachable = sum(d < OptimSPath.INF for d in dmy_dist)
dijkstra_reachable = sum(d < OptimSPath.INF for d in dijkstra_dist)

println("\nReachable vertices:")
println("  DMY: $dmy_reachable")
println("  Dijkstra: $dijkstra_reachable")

if dmy_reachable != dijkstra_reachable
    println("\nERROR: DMY is missing $(dijkstra_reachable - dmy_reachable) reachable vertices!")
end
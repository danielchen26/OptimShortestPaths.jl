using OPUS

# Test case where bound might be 0
graph = OPUS.DMYGraph(3, [OPUS.Edge(1, 2, 1)], [5.0])

source = 1
dmy_dist = OPUS.dmy_sssp!(graph, source)
println("DMY distances: ", dmy_dist)

# If only source is reachable at finite distance
if any(d < OPUS.INF for d in dmy_dist)
    max_finite_dist = maximum(d for d in dmy_dist if d < OPUS.INF)
    bound = max_finite_dist / 2
    println("Max finite dist: ", max_finite_dist)
    println("Bound: ", bound)
    
    bounded_dist = OPUS.dmy_sssp_bounded!(graph, source, bound)
    println("Bounded distances: ", bounded_dist)
    
    for i in 1:3
        if dmy_dist[i] <= bound
            println("Vertex $i: dmy=$(dmy_dist[i]), bounded=$(bounded_dist[i]), expected match")
            if abs(bounded_dist[i] - dmy_dist[i]) >= 1e-10
                println("  ERROR: Mismatch!")
            end
        else
            println("Vertex $i: dmy=$(dmy_dist[i]), bounded=$(bounded_dist[i]), expected Inf")
        end
    end
end
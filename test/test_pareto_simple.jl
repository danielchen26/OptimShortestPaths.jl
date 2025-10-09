#!/usr/bin/env julia

"""
Simple test to verify Pareto front computation works correctly
"""

using OPUS

using OPUS.MultiObjective

println("Testing Simple Pareto Front Computation")
println("=" ^ 40)

# Create a simple diamond graph with 2 objectives
# 1 -> 2 -> 4
#   -> 3 -> 
edges = [
    MultiObjective.MultiObjectiveEdge(1, 2, [1.0, 3.0], 1),  # Path A: low obj1, high obj2
    MultiObjective.MultiObjectiveEdge(1, 3, [3.0, 1.0], 2),  # Path B: high obj1, low obj2
    MultiObjective.MultiObjectiveEdge(2, 4, [1.0, 1.0], 3),  # Continue A
    MultiObjective.MultiObjectiveEdge(3, 4, [1.0, 1.0], 4),  # Continue B
]

adjacency = [Int[] for _ in 1:4]
for (i, edge) in enumerate(edges)
    push!(adjacency[edge.source], i)
end

graph = MultiObjective.MultiObjectiveGraph(4, edges, 2, adjacency,
    ["Objective1", "Objective2"], objective_sense=fill(:min, 2))

println("Computing Pareto front from vertex 1 to 4...")
pareto_front = MultiObjective.compute_pareto_front(graph, 1, 4, max_solutions=10)

println("Found $(length(pareto_front)) Pareto-optimal solutions:")
for (i, sol) in enumerate(pareto_front)
    println("  Solution $i: Path $(sol.path)")
    println("    Objectives: $(sol.objectives)")
end

# Expected: 2 solutions
# Path 1->2->4: objectives [2.0, 4.0]
# Path 1->3->4: objectives [4.0, 2.0]
# Both are non-dominated

if length(pareto_front) == 2
    println("✅ Test passed: Found correct number of Pareto solutions")
else
    println("❌ Test failed: Expected 2 solutions, found $(length(pareto_front))")
end

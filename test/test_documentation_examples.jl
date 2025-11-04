#!/usr/bin/env julia
"""
Test script to verify all documentation examples are executable.
This validates the corrected multi-objective syntax in the documentation.
"""

# Add the src directory to the load path (same as runtests.jl)
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

# Load the module
include("../src/OptimShortestPaths.jl")
using .OptimShortestPaths
using .OptimShortestPaths.MultiObjective

println("="^70)
println("Testing Documentation Examples - Multi-Objective Syntax")
println("="^70)

test_results = Dict{String, Bool}()

# Test 1: Basic Usage (from docs/src/manual/multiobjective.md lines 13-45)
println("\n[Test 1] Basic Usage Example")
println("-"^70)
try
    edges = [
        MultiObjectiveEdge(1, 2, [1.0, 5.0], 1),  # [cost, time] for edge 1->2
        MultiObjectiveEdge(2, 3, [2.0, 1.0], 2)   # [cost, time] for edge 2->3
    ]

    # Build adjacency list
    adjacency = [Int[] for _ in 1:3]
    for (idx, edge) in enumerate(edges)
        push!(adjacency[edge.source], idx)
    end

    graph = MultiObjectiveGraph(
        3,                      # n_vertices
        edges,                  # edges with weights
        2,                      # n_objectives
        adjacency,              # adjacency list
        ["Cost", "Time"]        # objective names
    )

    # Compute Pareto front
    pareto_solutions = compute_pareto_front(graph, 1, 3; max_solutions=1000)

    # Each solution has:
    println("✓ Graph created successfully")
    println("✓ Found $(length(pareto_solutions)) Pareto solutions")
    for sol in pareto_solutions
        println("  - Objectives: $(sol.objectives), Path: $(sol.path)")
    end

    test_results["Basic Usage"] = true
    println("✓ PASSED")
catch e
    println("✗ FAILED: $e")
    test_results["Basic Usage"] = false
end

# Test 2: Mixed Objectives (from docs/src/manual/multiobjective.md lines 116-136)
println("\n[Test 2] Mixed Objective Senses (min/max)")
println("-"^70)
try
    edges = [MultiObjectiveEdge(1, 2, [5.0, 8.0], 1)]  # [cost_to_minimize, profit_to_maximize]

    # Build adjacency list
    adjacency = [Int[] for _ in 1:2]
    push!(adjacency[1], 1)

    # Specify senses
    graph = MultiObjectiveGraph(
        2,                               # n_vertices
        edges,                           # edges
        2,                               # n_objectives
        adjacency,                       # adjacency list
        ["Cost", "Profit"],              # objective names
        objective_sense = [:min, :max]   # Minimize cost, maximize profit
    )

    # Pareto front respects both senses
    pareto_front = compute_pareto_front(graph, 1, 2)

    println("✓ Graph with mixed senses created successfully")
    println("✓ Found $(length(pareto_front)) solutions")
    for sol in pareto_front
        println("  - Cost: $(sol.objectives[1]), Profit: $(sol.objectives[2])")
    end

    test_results["Mixed Objectives"] = true
    println("✓ PASSED")
catch e
    println("✗ FAILED: $e")
    test_results["Mixed Objectives"] = false
end

# Test 3: Cost-Time Trade-off Example (from docs/src/manual/multiobjective.md lines 156-193)
println("\n[Test 3] Cost-Time Trade-off Example")
println("-"^70)
try
    # Supply chain network: minimize cost AND time
    edges = [
        MultiObjectiveEdge(1, 2, [10.0, 1.0], 1),  # Cheap but slow
        MultiObjectiveEdge(1, 3, [30.0, 0.5], 2),  # Expensive but fast
        MultiObjectiveEdge(2, 4, [5.0, 2.0], 3),   # Cheap and slow
        MultiObjectiveEdge(3, 4, [15.0, 1.0], 4)   # Moderate
    ]

    # Build adjacency list
    adjacency = [Int[] for _ in 1:4]
    for (idx, edge) in enumerate(edges)
        push!(adjacency[edge.source], idx)
    end

    graph = MultiObjectiveGraph(
        4,                      # n_vertices
        edges,                  # edges
        2,                      # n_objectives (cost, time)
        adjacency,              # adjacency list
        ["Cost", "Time"]        # objective names
    )

    # Find all Pareto-optimal paths
    pareto_front = compute_pareto_front(graph, 1, 4)

    println("✓ Found $(length(pareto_front)) Pareto-optimal solutions:")
    for (i, sol) in enumerate(pareto_front)
        println("  $i. Cost: $(sol.objectives[1]), Time: $(sol.objectives[2])")
    end

    # Select best trade-off
    best = get_knee_point(pareto_front)
    println("✓ Best trade-off: Cost=$(best.objectives[1]), Time=$(best.objectives[2])")

    test_results["Cost-Time Trade-off"] = true
    println("✓ PASSED")
catch e
    println("✗ FAILED: $e")
    test_results["Cost-Time Trade-off"] = false
end

# Test 4: Examples.md Multi-Objective Example (from docs/src/examples.md lines 118-149)
println("\n[Test 4] Examples.md Multi-Objective Example")
println("-"^70)
try
    # Create multi-objective graph
    edges = [
        MultiObjectiveEdge(1, 2, [1.0, 10.0], 1),  # Cheap but slow
        MultiObjectiveEdge(2, 3, [2.0, 5.0], 2),   # Moderate
        MultiObjectiveEdge(1, 3, [5.0, 3.0], 3)    # Expensive but fast
    ]

    # Build adjacency list
    adjacency = [Int[] for _ in 1:3]
    for (idx, edge) in enumerate(edges)
        push!(adjacency[edge.source], idx)
    end

    graph = MultiObjectiveGraph(
        3,                      # n_vertices
        edges,                  # edges
        2,                      # n_objectives
        adjacency,              # adjacency list
        ["Cost", "Time"]        # objective names
    )

    # Compute Pareto front
    solutions = compute_pareto_front(graph, 1, 3)

    # Find best trade-off
    best = get_knee_point(solutions)
    println("✓ Best trade-off - Cost: $(best.objectives[1]), Time: $(best.objectives[2])")

    test_results["Examples.md Example"] = true
    println("✓ PASSED")
catch e
    println("✗ FAILED: $e")
    test_results["Examples.md Example"] = false
end

# Summary
println("\n" * "="^70)
println("SUMMARY")
println("="^70)

passed = sum(values(test_results))
total = length(test_results)

for (name, result) in test_results
    status = result ? "✓ PASSED" : "✗ FAILED"
    println("$status: $name")
end

println("\nResults: $passed/$total tests passed")

if passed == total
    println("\n🎉 All documentation examples are executable and correct!")
    exit(0)
else
    println("\n⚠️  Some tests failed. Please review the errors above.")
    exit(1)
end

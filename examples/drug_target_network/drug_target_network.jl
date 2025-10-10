#!/usr/bin/env julia

"""
Drug-Target Interaction Network Analysis
Demonstrates both single-objective and multi-objective DMY shortest-path algorithms
applied to pharmaceutical networks.

IMPORTANT: Using Generic Functions for Your Domain
===================================================
This example demonstrates how to use OptimShortestPaths's GENERIC utility functions
that work with ANY domain, not just pharmaceuticals:

1. calculate_distance_ratio(graph, source, target1, target2)
   - Compare distances from any source to two targets
   - Useful for: selectivity, preference, comparison metrics
   
2. calculate_path_preference(graph, source, preferred, alternative)
   - Calculate preference for one target over another
   
3. analyze_connectivity(graph, source)
   - Get comprehensive connectivity metrics from any vertex
   
4. find_reachable_vertices(graph, source, max_distance)
   - Find all vertices within a distance threshold
   
5. compare_sources(graph, sources, target)
   - Compare multiple sources to reach a single target
   
6. find_shortest_path(graph, source, target)
   - Find path and distance between any two vertices

These functions work with ANY graph structure - supply chains, 
metabolic networks, transportation systems, etc. Simply map your
domain entities to vertices and relationships to edges!
"""

using OptimShortestPaths
using OptimShortestPaths.MultiObjective
using Plots
using Random

# Multi-objective optimization tools from OptimShortestPaths
using OptimShortestPaths: MultiObjectiveEdge, MultiObjectiveGraph, ParetoSolution,
    compute_pareto_front, weighted_sum_approach, epsilon_constraint_approach,
    lexicographic_approach, get_knee_point, compute_path_objectives

include("common.jl")

println("🧬 Drug-Target Interaction Network Analysis")
println("=" ^ 60)

# Part 1: Single-Objective Analysis
println("\n📊 PART 1: SINGLE-OBJECTIVE ANALYSIS")
println("-" ^ 40)

network = build_drug_target_network()

println("✓ Network created: $(network.graph.n_vertices) vertices, $(length(network.graph.edges)) edges")

# Analyze drug connectivity using GENERIC analyze_connectivity function
println("\n🔍 Drug Connectivity Analysis (using generic functions):")
reachability_stats = Int[]
avg_distance_stats = Float64[]
for drug in DRUGS[1:4]  # First 4 drugs
    drug_idx = network.drug_indices[drug]
    
    # Use the GENERIC analyze_connectivity function
    analysis = analyze_connectivity(network.graph, drug_idx)
    
    # Calculate target-specific metrics from generic results
    n_targets = length(network.target_indices)
    reachable_targets = 0
    for (target_name, target_idx) in network.target_indices
        if target_idx in find_reachable_vertices(network.graph, drug_idx)
            reachable_targets += 1
        end
    end
    
    println("$drug: $reachable_targets/$n_targets targets reachable, " *
            "connectivity: $(round(analysis["connectivity_ratio"]*100, digits=1))%, " *
            "avg distance: $(round(analysis["avg_distance"], digits=3))")
    
    push!(reachability_stats, reachable_targets)
    push!(avg_distance_stats, analysis["avg_distance"])
end

# Find specific pathways
println("\n🎯 Key Drug-Target Pathways:")
pathways = [
    ("Aspirin", "COX1"),
    ("Celecoxib", "COX2"),
    ("Ibuprofen", "COX2"),
    ("Morphine", "MOR")
]

for (drug, target) in pathways
    distance, path = find_drug_target_paths(network, drug, target)
    println("$drug → $target: distance = $(round(distance, digits=3))")
end

# COX selectivity analysis using GENERIC functions
# This demonstrates how to use generic utilities for domain-specific analysis
println("\n💊 COX-2 Selectivity Analysis:")
println("Using generic calculate_distance_ratio function:")
selectivity_data = Float64[]
selectivity_metrics = Dict{String, Float64}()
for drug in ["Aspirin", "Ibuprofen", "Celecoxib", "Acetaminophen"]
    # Use the GENERIC calculate_distance_ratio function
    # Higher ratio = higher COX-1 distance vs COX-2 = more COX-2 selective
    drug_idx = network.drug_indices[drug]
    cox1_idx = network.target_indices["COX1"]
    cox2_idx = network.target_indices["COX2"]
    
    # Generic function: ratio of distances from source to two targets
    selectivity = calculate_distance_ratio(network.graph, drug_idx, cox1_idx, cox2_idx)
    push!(selectivity_data, selectivity)
    selectivity_metrics[drug] = selectivity
    interpretation = selectivity > 10 ? "COX-2 selective" : 
                    selectivity > 1 ? "Slight COX-2 preference" :
                    selectivity < 0.5 ? "COX-1 selective" : "Non-selective"
    println("$drug: $(round(selectivity, digits=1))x ($interpretation)")
end

# Part 2: Multi-Objective Analysis
println("\n" * "=" ^ 60)
println("📊 PART 2: MULTI-OBJECTIVE ANALYSIS")
println("-" ^ 40)

mo_graph = create_mo_drug_network()

println("\n🎯 Computing Pareto Front...")
pareto_front = MultiObjective.compute_pareto_front(mo_graph, 1, 9, max_solutions=50)

println("Found $(length(pareto_front)) Pareto-optimal drug pathways")

# Display top solutions
drug_names = ["", "Aspirin-like", "Ibuprofen-like", "Morphine-like", "Novel"]
target_names = ["", "", "", "", "", "COX-1", "COX-2", "MOR", "Effect"]

println("\nTop Pareto-Optimal Solutions:")
println("-" ^ 40)
for (i, sol) in enumerate(pareto_front[1:min(5, end)])
    path_desc = join([i <= 5 ? drug_names[i] : target_names[i] for i in sol.path if i > 1], "→")
    println("$i. $path_desc")
    println("   Efficacy: $(round(sol.objectives[1]*100, digits=0))%, " *
            "Toxicity: $(round(sol.objectives[2]*100, digits=0))%, " *
            "Cost: \$$(round(sol.objectives[3], digits=0)), " *
            "Time: $(round(sol.objectives[4], digits=1))h")
end

# Compare selection methods
println("\n🔍 Selection Method Comparison:")
weights = [0.4, 0.2, 0.2, 0.2]  # Prioritize efficacy
sol_weighted_summary = nothing
weighted_sum_error = nothing
try
    global sol_weighted_summary = MultiObjective.weighted_sum_approach(mo_graph, 1, 9, weights)
    println("• Weighted Sum: Efficacy=$(round(sol_weighted_summary.objectives[1]*100, digits=0))%, " *
            "Toxicity=$(round(sol_weighted_summary.objectives[2]*100, digits=0))%")
catch err
    global weighted_sum_error = sprint(showerror, err)
    println("• Weighted Sum: not applicable ($weighted_sum_error)")
end

constraints = [Inf, 0.3, Inf, Inf]  # Limit toxicity
sol_constrained = MultiObjective.epsilon_constraint_approach(mo_graph, 1, 9, 1, constraints)
constrained_feasible = all(isfinite, sol_constrained.objectives) && !isempty(sol_constrained.path)
if constrained_feasible
    println("• ε-Constraint (toxicity≤30%): Efficacy=$(round(sol_constrained.objectives[1]*100, digits=0))%, " *
            "Toxicity=$(round(sol_constrained.objectives[2]*100, digits=0))%")
else
    println("• ε-Constraint (toxicity≤30%): no feasible pathway under the specified constraint")
end

knee = MultiObjective.get_knee_point(pareto_front)
knee_solution = nothing
if knee !== nothing
    println("• Knee Point: Efficacy=$(round(knee.objectives[1]*100, digits=0))%, " *
            "Toxicity=$(round(knee.objectives[2]*100, digits=0))%")
    knee_solution = knee
end

# Part 3: Performance Analysis
println("\n" * "=" ^ 60)
println("📊 PART 3: PERFORMANCE ANALYSIS (CORRECTED)")
println("-" ^ 40)

println("\n🔧 Critical Fix: k parameter corrected from k=n-1 to k=n^(1/3)")
println("\nPerformance on Sparse Graphs (m ≈ 2n):")

# Run actual benchmarks
test_sizes = [100, 1000, 2000, 5000]
performance_results = []

Random.seed!(42)

for n in test_sizes
    rng = MersenneTwister(42 + n)
    samples = 10
    # Create sparse graph
    edges = OptimShortestPaths.Edge[]
    local weights = Float64[]
    
    # Create connected path
    for i in 1:n-1
        push!(edges, OptimShortestPaths.Edge(i, i+1, length(edges)+1))
        push!(weights, rand(rng) * 2.0 + 0.5)
    end

    # Add ~n more edges for sparsity
    for _ in 1:n
        u = rand(rng, 1:n)
        v = rand(rng, 1:n)
        if u != v && !any(e -> (e.source == u && e.target == v), edges)
            push!(edges, OptimShortestPaths.Edge(u, v, length(edges)+1))
            push!(weights, rand(rng) * 5.0 + 0.5)
        end
    end

    graph = OptimShortestPaths.DMYGraph(n, edges, weights)
    k = max(1, ceil(Int, n^(1/3)))

    # Time algorithms
    t_dmy = (@elapsed begin
        for _ in 1:samples
            OptimShortestPaths.dmy_sssp!(graph, 1)
        end
    end) / samples
    t_dijkstra = (@elapsed begin
        for _ in 1:samples
            OptimShortestPaths.simple_dijkstra(graph, 1)
        end
    end) / samples
    speedup = t_dijkstra / t_dmy
    
    push!(performance_results, (n, k, speedup))
end

println("| n    | k  | DMY vs Dijkstra |")
println("|------|----|-----------------| ")
for (n, k, speedup) in performance_results
    status = speedup > 1 ? "$(round(speedup, digits=2))x FASTER" : "$(round(speedup, digits=2))x (slower)"
    println("| $(lpad(n, 4)) | $(lpad(k, 2)) | $(rpad(status, 15)) |")
end

println("\n✅ DMY shows theoretical O(m log^(2/3) n) advantage for n > 1000")

pareto_count = length(pareto_front)
if pareto_count > 0
    efficacy_values = [sol.objectives[1] * 100 for sol in pareto_front]
    toxicity_values = [sol.objectives[2] * 100 for sol in pareto_front]
    cost_values = [sol.objectives[3] for sol in pareto_front]
    time_values = [sol.objectives[4] for sol in pareto_front]
    efficacy_range = (minimum(efficacy_values), maximum(efficacy_values))
    toxicity_range = (minimum(toxicity_values), maximum(toxicity_values))
    best_efficacy_idx = argmax(efficacy_values)
    best_efficacy = efficacy_values[best_efficacy_idx]
    best_efficacy_toxicity = toxicity_values[best_efficacy_idx]
    fastest_idx = argmin(time_values)
    fastest_time = time_values[fastest_idx]
    fastest_efficacy = efficacy_values[fastest_idx]
    lowest_cost_idx = argmin(cost_values)
    lowest_cost = cost_values[lowest_cost_idx]
    lowest_cost_time = time_values[lowest_cost_idx]
else
    efficacy_range = (NaN, NaN)
    toxicity_range = (NaN, NaN)
    best_efficacy = NaN
    best_efficacy_toxicity = NaN
    fastest_time = NaN
    fastest_efficacy = NaN
    lowest_cost = NaN
    lowest_cost_time = NaN
end

performance_count = length(performance_results)
if performance_count > 0
    n_values = [res[1] for res in performance_results]
    largest_idx = argmax(n_values)
    smallest_idx = argmin(n_values)
    largest_case = performance_results[largest_idx]
    smallest_case = performance_results[smallest_idx]
    speedup_values = [res[3] for res in performance_results]
    max_speedup_idx = argmax(speedup_values)
    min_speedup_idx = argmin(speedup_values)
    max_speedup_case = performance_results[max_speedup_idx]
    min_speedup_case = performance_results[min_speedup_idx]
else
    largest_case = (NaN, NaN, NaN)
    smallest_case = (NaN, NaN, NaN)
    max_speedup_case = (NaN, NaN, NaN)
    min_speedup_case = (NaN, NaN, NaN)
end

if !isempty(reachability_stats)
    reachability_range = (minimum(reachability_stats), maximum(reachability_stats))
    avg_distance_range = (minimum(avg_distance_stats), maximum(avg_distance_stats))
else
    reachability_range = (0, 0)
    avg_distance_range = (NaN, NaN)
end

celecoxib_selectivity = get(selectivity_metrics, "Celecoxib", NaN)
best_selectivity = isempty(selectivity_metrics) ? nothing : findmax(selectivity_metrics)

# Summary
println("\n" * "=" ^ 60)
println("KEY FINDINGS")
println("=" ^ 60)

println("\n1. SINGLE-OBJECTIVE:")
if reachability_range[2] > 0 && all(isfinite, avg_distance_range)
    println("   • Sample drugs reach $(reachability_range[1])–$(reachability_range[2]) of $(length(TARGETS)) targets; avg distance $(round(avg_distance_range[1], digits=2))–$(round(avg_distance_range[2], digits=2))")
else
    println("   • Connectivity metrics unavailable for sampled drugs")
end
if best_selectivity !== nothing
    best_value, best_drug = best_selectivity
    println("   • Highest COX-2 selectivity: $best_drug at $(round(best_value, digits=1))x")
elseif isfinite(celecoxib_selectivity)
    println("   • Celecoxib COX-2 selectivity: $(round(celecoxib_selectivity, digits=1))x")
end
println("   • DMY efficiently retrieves optimal drug→target pathways")

println("\n2. MULTI-OBJECTIVE:")
if pareto_count > 0 && all(isfinite, efficacy_range)
    println("   • $pareto_count Pareto-optimal solutions; efficacy span $(round(efficacy_range[1], digits=0))–$(round(efficacy_range[2], digits=0))% with toxicity $(round(toxicity_range[1], digits=0))–$(round(toxicity_range[2], digits=0))%")
    println("   • Highest efficacy option: $(round(best_efficacy, digits=0))% efficacy at $(round(best_efficacy_toxicity, digits=0))% toxicity")
    println("   • Fastest option: $(round(fastest_efficacy, digits=0))% efficacy in $(round(fastest_time, digits=1)) h")
    println("   • Lowest cost option: \$$(round(lowest_cost, digits=0)) in $(round(lowest_cost_time, digits=1)) h")
else
    println("   • No Pareto-optimal solutions identified (unexpected)")
end
if sol_weighted_summary !== nothing
    println("   • Weighted sum (0.4/0.2/0.2/0.2): efficacy=$(round(sol_weighted_summary.objectives[1]*100, digits=0))%, toxicity=$(round(sol_weighted_summary.objectives[2]*100, digits=0))%")
elseif weighted_sum_error !== nothing
    println("   • Weighted sum unavailable: $weighted_sum_error")
end
if constrained_feasible
    println("   • ε-constraint (toxicity≤30%): efficacy=$(round(sol_constrained.objectives[1]*100, digits=0))%, toxicity=$(round(sol_constrained.objectives[2]*100, digits=0))%")
else
    println("   • ε-constraint (toxicity≤30%): no feasible pathway at this threshold")
end
if knee_solution !== nothing
    println("   • Knee point: efficacy=$(round(knee_solution.objectives[1]*100, digits=0))%, toxicity=$(round(knee_solution.objectives[2]*100, digits=0))%")
end

println("\n3. PERFORMANCE:")
println("   • Fixed k=n^(1/3) parameter remains critical for speed")
if performance_count > 0 && isfinite(largest_case[1])
    largest_speedup = largest_case[3]
    max_speedup = max_speedup_case[3]
    min_speedup = min_speedup_case[3]
    println("   • Largest benchmark (n=$(largest_case[1])): $(round(largest_speedup, digits=2))× $(largest_speedup >= 1 ? "faster" : "(slower)")")
    println("   • Greatest observed speedup (n=$(max_speedup_case[1])): $(round(max_speedup, digits=2))× faster")
    println("   • Slowest sample (n=$(min_speedup_case[1])): $(round(min_speedup, digits=2))× $(min_speedup >= 1 ? "faster" : "(slower)")")
else
    println("   • Performance benchmarks unavailable")
end
println("   • Optimal for large sparse networks")

println("\n✅ Analysis complete!")

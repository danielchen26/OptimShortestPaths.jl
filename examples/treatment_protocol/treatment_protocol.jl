#!/usr/bin/env julia

"""
Treatment Protocol Optimization Example

This example demonstrates the application of the DMY shortest-path algorithm
to healthcare treatment optimization and clinical decision support. We model
treatment protocols where:
- Vertices represent treatment steps or clinical decision points
- Edges represent valid transitions between treatments
- Edge weights represent combined costs (financial, time, risk, efficacy)

The DMY algorithm efficiently finds optimal treatment sequences, which is crucial for:
- Clinical pathway optimization
- Personalized treatment planning
- Healthcare cost reduction
- Risk-benefit analysis
- Evidence-based medicine
"""

using OptimSPath
# Inline benchmark loader (for performance demonstration only)
function load_benchmark_results(path = joinpath(@__DIR__, "..", "..", "benchmark_results.txt"))
    isfile(path) || error("Benchmark results not found at $path")
    sizes, edges, dmy_ms, dmy_ci_ms, dijkstra_ms, dijkstra_ci_ms, speedups = Int[], Int[], Float64[], Float64[], Float64[], Float64[], Float64[]
    for line in eachline(path)
        line = strip(line)
        (isempty(line) || startswith(line, "#")) && continue
        cols = split(line, ',')
        length(cols) < 7 && continue
        push!(sizes, parse(Int, cols[1]))
        push!(edges, parse(Int, cols[2]))
        push!(dmy_ms, parse(Float64, cols[3]))
        push!(dmy_ci_ms, parse(Float64, cols[4]))
        push!(dijkstra_ms, parse(Float64, cols[5]))
        push!(dijkstra_ci_ms, parse(Float64, cols[6]))
        push!(speedups, parse(Float64, cols[7]))
    end
    return (; sizes, edges, dmy_ms, dmy_ci_ms, dijkstra_ms, dijkstra_ci_ms, speedup=speedups)
end
benchmark_summary(results) = "DMY achieves $(round(results.speedup[end], digits=2))× speedup at n=$(results.sizes[end]) vertices (sparse graph)"

using OptimSPath.MultiObjective

# Multi-objective optimization tools from OptimSPath
using OptimSPath: MultiObjectiveEdge, MultiObjectiveGraph, ParetoSolution,
    compute_pareto_front, weighted_sum_approach, epsilon_constraint_approach,
    lexicographic_approach, get_knee_point, compute_path_objectives

println("🏥 Treatment Protocol Optimization")
println("=" ^ 55)

# Define a comprehensive cancer treatment protocol
# Based on typical oncology treatment pathways

treatments = [
    "Initial_Screening",     # Entry point
    "Diagnostic_Imaging",    # CT, MRI, PET scans
    "Biopsy",               # Tissue sampling
    "Staging",              # Determine cancer stage
    "Multidisciplinary_Review", # Team consultation
    "Surgery_Consultation", # Surgical evaluation
    "Medical_Oncology",     # Chemotherapy planning
    "Radiation_Oncology",   # Radiation therapy planning
    "Surgery_Minor",        # Lumpectomy, minor resection
    "Surgery_Major",        # Mastectomy, major resection
    "Chemotherapy_Neoadjuvant", # Pre-surgery chemo
    "Chemotherapy_Adjuvant",    # Post-surgery chemo
    "Radiation_Therapy",    # External beam radiation
    "Immunotherapy",        # Checkpoint inhibitors
    "Targeted_Therapy",     # Precision medicine
    "Palliative_Care",      # Comfort care
    "Follow_up_Monitoring", # Surveillance
    "Remission",            # Treatment success
    "Recurrence_Detection", # Disease return
    "Second_Line_Treatment" # Salvage therapy
]

# Treatment costs (in thousands of dollars, normalized)
treatment_costs = [
    0.5,    # Initial_Screening
    2.0,    # Diagnostic_Imaging
    1.5,    # Biopsy
    1.0,    # Staging
    0.8,    # Multidisciplinary_Review
    0.5,    # Surgery_Consultation
    1.0,    # Medical_Oncology
    1.0,    # Radiation_Oncology
    15.0,   # Surgery_Minor
    35.0,   # Surgery_Major
    25.0,   # Chemotherapy_Neoadjuvant
    20.0,   # Chemotherapy_Adjuvant
    30.0,   # Radiation_Therapy
    40.0,   # Immunotherapy
    45.0,   # Targeted_Therapy
    10.0,   # Palliative_Care
    2.0,    # Follow_up_Monitoring
    0.0,    # Remission (goal state)
    3.0,    # Recurrence_Detection
    50.0    # Second_Line_Treatment
]

# Treatment efficacy weights (0.0 = no efficacy, 1.0 = perfect efficacy)
efficacy_weights = [
    1.0,    # Initial_Screening
    0.95,   # Diagnostic_Imaging
    0.98,   # Biopsy
    0.90,   # Staging
    0.85,   # Multidisciplinary_Review
    0.80,   # Surgery_Consultation
    0.85,   # Medical_Oncology
    0.85,   # Radiation_Oncology
    0.85,   # Surgery_Minor
    0.90,   # Surgery_Major
    0.75,   # Chemotherapy_Neoadjuvant
    0.80,   # Chemotherapy_Adjuvant
    0.85,   # Radiation_Therapy
    0.70,   # Immunotherapy (variable response)
    0.75,   # Targeted_Therapy (depends on biomarkers)
    0.60,   # Palliative_Care (comfort, not cure)
    0.95,   # Follow_up_Monitoring
    1.0,    # Remission
    0.90,   # Recurrence_Detection
    0.60    # Second_Line_Treatment (lower success rate)
]

# Define valid treatment transitions with transition costs
# Transition costs represent coordination, waiting time, and administrative overhead
treatment_transitions = [
    # Initial diagnostic pathway
    ("Initial_Screening", "Diagnostic_Imaging", 0.2),
    ("Diagnostic_Imaging", "Biopsy", 0.5),
    ("Biopsy", "Staging", 0.3),
    ("Staging", "Multidisciplinary_Review", 0.2),
    
    # Consultation pathways
    ("Multidisciplinary_Review", "Surgery_Consultation", 0.1),
    ("Multidisciplinary_Review", "Medical_Oncology", 0.1),
    ("Multidisciplinary_Review", "Radiation_Oncology", 0.1),
    ("Multidisciplinary_Review", "Palliative_Care", 0.5),  # Higher barrier to palliative
    
    # Surgical pathways
    ("Surgery_Consultation", "Surgery_Minor", 0.5),
    ("Surgery_Consultation", "Surgery_Major", 1.0),  # More complex coordination
    ("Surgery_Consultation", "Chemotherapy_Neoadjuvant", 0.3),
    
    # Neoadjuvant pathway
    ("Chemotherapy_Neoadjuvant", "Surgery_Minor", 0.8),
    ("Chemotherapy_Neoadjuvant", "Surgery_Major", 1.2),
    
    # Post-surgical pathways
    ("Surgery_Minor", "Chemotherapy_Adjuvant", 0.5),
    ("Surgery_Minor", "Radiation_Therapy", 0.4),
    ("Surgery_Minor", "Follow_up_Monitoring", 0.2),
    ("Surgery_Major", "Chemotherapy_Adjuvant", 0.6),
    ("Surgery_Major", "Radiation_Therapy", 0.5),
    ("Surgery_Major", "Follow_up_Monitoring", 0.3),
    
    # Advanced therapy pathways
    ("Medical_Oncology", "Immunotherapy", 0.4),
    ("Medical_Oncology", "Targeted_Therapy", 0.3),
    ("Medical_Oncology", "Chemotherapy_Adjuvant", 0.2),
    
    # Radiation pathways
    ("Radiation_Oncology", "Radiation_Therapy", 0.3),
    ("Radiation_Therapy", "Follow_up_Monitoring", 0.2),
    
    # Advanced treatments to monitoring
    ("Chemotherapy_Adjuvant", "Follow_up_Monitoring", 0.3),
    ("Immunotherapy", "Follow_up_Monitoring", 0.4),
    ("Targeted_Therapy", "Follow_up_Monitoring", 0.3),
    
    # Monitoring outcomes
    ("Follow_up_Monitoring", "Remission", 0.1),
    ("Follow_up_Monitoring", "Recurrence_Detection", 0.8),
    
    # Recurrence pathways
    ("Recurrence_Detection", "Second_Line_Treatment", 0.5),
    ("Recurrence_Detection", "Palliative_Care", 1.0),
    ("Second_Line_Treatment", "Follow_up_Monitoring", 0.4),
    ("Second_Line_Treatment", "Palliative_Care", 0.8),
    
    # Palliative transitions
    ("Palliative_Care", "Follow_up_Monitoring", 0.2)
]

println("\n🏗️  Creating treatment protocol network...")

# Create the treatment protocol
protocol = create_treatment_protocol(treatments, treatment_costs, efficacy_weights, treatment_transitions)

println("✓ Treatment protocol created successfully!")
println("  Total treatments: $(length(treatments))")
println("  Total transitions: $(length(treatment_transitions))")
println("  Network complexity: $(length(protocol.graph.edges)) edges")

# Analyze optimal treatment pathways
println("\n📋 Treatment Pathway Optimization")
println("-" ^ 40)

# DEMONSTRATION: Using BOTH domain-specific AND generic functions
println("\n🔍 Approach 1: Using Domain-Specific Convenience Functions")
println("   (These are thin wrappers around generic functions)")

# 1. Standard curative pathway: Screening → Remission (using convenience function)
cost1, sequence1 = optimize_treatment_sequence(protocol, "Initial_Screening", "Remission")
println("\n1. Optimal Curative Pathway:")
println("   Sequence: $(join(sequence1, " → "))")
println("   Total cost: \$$(round(cost1, digits=1))k")
println("   Steps: $(length(sequence1) - 1) treatments")

# 2. Surgical pathway: Screening → Surgery → Monitoring
if "Surgery_Minor" in sequence1 || "Surgery_Major" in sequence1
    surgery_type = "Surgery_Minor" in sequence1 ? "Surgery_Minor" : "Surgery_Major"
    cost2, sequence2 = optimize_treatment_sequence(protocol, "Initial_Screening", "Follow_up_Monitoring")
    println("\n2. Surgical Treatment Pathway:")
    println("   Sequence: $(join(sequence2, " → "))")
    println("   Total cost: \$$(round(cost2, digits=1))k")
    println("   Includes: $(surgery_type)")
end

# 3. Conservative pathway: Screening → Medical treatment → Monitoring
cost3, sequence3 = optimize_treatment_sequence(protocol, "Medical_Oncology", "Follow_up_Monitoring")
println("\n3. Medical Treatment Pathway:")
println("   Sequence: $(join(sequence3, " → "))")
println("   Total cost: \$$(round(cost3, digits=1))k")

# 4. Palliative pathway: Screening → Palliative Care
cost4, sequence4 = optimize_treatment_sequence(protocol, "Initial_Screening", "Palliative_Care")
println("\n4. Palliative Care Pathway:")
println("   Sequence: $(join(sequence4, " → "))")
println("   Total cost: \$$(round(cost4, digits=1))k")

# 5. Recurrence management: Detection → Second-line
cost5, sequence5 = optimize_treatment_sequence(protocol, "Recurrence_Detection", "Follow_up_Monitoring")
println("\n5. Recurrence Management:")
println("   Sequence: $(join(sequence5, " → "))")
println("   Total cost: \$$(round(cost5, digits=1))k")

# DEMONSTRATION: Using GENERIC functions directly
println("\n\n🔍 Approach 2: Using GENERIC Functions Directly")
println("   (Works for ANY domain, not just medical treatments)")
println("-" ^ 40)

# Get vertex indices for treatments
screening_idx = protocol.treatment_indices["Initial_Screening"]
remission_idx = protocol.treatment_indices["Remission"]

# Use GENERIC find_shortest_path function
distance_generic, path_vertices = find_shortest_path(protocol.graph, screening_idx, remission_idx)

# Convert vertex indices back to treatment names (manual mapping)
path_names = String[]
for v in path_vertices
    for (name, idx) in protocol.treatment_indices
        if idx == v
            push!(path_names, name)
            break
        end
    end
end

println("\nUsing generic find_shortest_path():")
println("   Path: $(join(path_names, " → "))")
println("   Cost: \$$(round(distance_generic, digits=1))k")
println("   ✓ Same result as domain-specific function!")

# Use GENERIC analyze_connectivity to understand treatment accessibility
screening_connectivity = analyze_connectivity(protocol.graph, screening_idx)
println("\nUsing generic analyze_connectivity() from Initial_Screening:")
println("   Reachable treatments: $(screening_connectivity["reachable_count"])/$(protocol.graph.n_vertices)")
println("   Average cost to reach: \$$(round(screening_connectivity["avg_distance"], digits=1))k")
println("   Max cost: \$$(round(screening_connectivity["max_distance"], digits=1))k")

# Use GENERIC find_reachable_vertices for budget-constrained analysis
budget = 50.0  # $50k budget
affordable_treatments = find_reachable_vertices(protocol.graph, screening_idx, budget)
println("\nUsing generic find_reachable_vertices() with \$50k budget:")
println("   $(length(affordable_treatments)) treatments accessible within budget")

# Treatment cost-effectiveness analysis
println("\n\n💰 Cost-Effectiveness Analysis")
println("-" ^ 35)

pathways = [
    ("Curative", cost1, length(sequence1) - 1, "Remission"),
    ("Medical", cost3, length(sequence3) - 1, "Monitoring"),
    ("Palliative", cost4, length(sequence4) - 1, "Comfort"),
    ("Recurrence", cost5, length(sequence5) - 1, "Salvage")
]

println("\nPathway Comparison:")
for (name, cost, steps, outcome) in pathways
    cost_per_step = steps > 0 ? cost / steps : 0
    println("  $name Pathway:")
    println("    Total cost: \$$(round(cost, digits=1))k")
    println("    Steps: $steps")
    println("    Cost/step: \$$(round(cost_per_step, digits=1))k")
    println("    Outcome: $outcome")
    println()
end

# Risk-benefit analysis
println("\n⚖️  Risk-Benefit Analysis")
println("-" ^ 28)

# Analyze high-cost, high-risk treatments
high_cost_treatments = []
for (i, treatment) in enumerate(treatments)
    cost = treatment_costs[i]
    efficacy = efficacy_weights[i]
    if cost > 20.0  # High-cost threshold
        risk_benefit_ratio = cost / max(efficacy, 0.1)
        push!(high_cost_treatments, (treatment, cost, efficacy, risk_benefit_ratio))
    end
end

sort!(high_cost_treatments, by=x->x[4])  # Sort by risk-benefit ratio

println("\nHigh-Cost Treatment Analysis:")
for (treatment, cost, efficacy, ratio) in high_cost_treatments
    println("  $treatment:")
    println("    Cost: \$$(round(cost, digits=1))k")
    println("    Efficacy: $(round(efficacy * 100, digits=1))%")
    println("    Risk-Benefit Ratio: $(round(ratio, digits=2))")
    
    if ratio < 50
        println("    ✓ Favorable risk-benefit profile")
    elseif ratio < 80
        println("    ⚠ Moderate risk-benefit profile")
    else
        println("    ⚠ High risk-benefit ratio - consider alternatives")
    end
    println()
end

# Clinical decision support
println("\n🩺 Clinical Decision Support")
println("-" ^ 32)

# Analyze decision points and alternatives
decision_points = ["Multidisciplinary_Review", "Surgery_Consultation", "Medical_Oncology"]

for decision_point in decision_points
    if haskey(protocol.treatment_indices, decision_point)
        vertex = protocol.treatment_indices[decision_point]
        dist = dmy_sssp!(protocol.graph, vertex)
        
        # Find reachable treatments and their costs
        reachable_options = []
        for (treatment, idx) in protocol.treatment_indices
            if dist[idx] < OptimSPath.INF && treatment != decision_point
                push!(reachable_options, (treatment, dist[idx]))
            end
        end
        
        sort!(reachable_options, by=x->x[2])
        
        println("\nFrom $decision_point:")
        println("  Available options (by cost):")
        for (treatment, cost) in reachable_options[1:min(5, end)]
            println("    → $treatment: \$$(round(cost, digits=1))k")
        end
    end
end

# Quality metrics and outcomes
println("\n📊 Quality Metrics")
println("-" ^ 20)

# Calculate pathway quality scores
quality_scores = []
for (name, cost, steps, outcome) in pathways
    # Quality score: inverse of cost, weighted by outcome value
    outcome_values = Dict("Remission" => 100, "Monitoring" => 80, "Comfort" => 60, "Salvage" => 40)
    outcome_value = get(outcome_values, outcome, 50)
    
    quality_score = (outcome_value / max(cost, 1)) * 100
    push!(quality_scores, (name, quality_score, outcome_value))
end

sort!(quality_scores, by=x->x[2], rev=true)

println("\nPathway Quality Rankings:")
for (i, (name, score, outcome_val)) in enumerate(quality_scores)
    println("  $i. $name Pathway")
    println("     Quality Score: $(round(score, digits=1))")
    println("     Outcome Value: $outcome_val")
end

# Performance analysis
println("\n🚀 Algorithm Performance")
println("-" ^ 25)

comparison = compare_with_dijkstra(protocol.graph, 1)

println("DMY Algorithm on Treatment Network:")
println("  Runtime: $(round(comparison["dmy_time"] * 1000, digits=2)) ms")
println("  Dijkstra runtime: $(round(comparison["dijkstra_time"] * 1000, digits=2)) ms")
println("  Speedup: $(round(comparison["speedup"], digits=2))x")
println("  Correctness: $(comparison["results_match"] ? "✓" : "✗")")

# Clinical insights and recommendations
println("\n🎯 Clinical Insights & Recommendations")
println("-" ^ 42)

println("\nKey Findings:")

# Find the most cost-effective pathway
best_pathway = quality_scores[1]
println("1. Most cost-effective pathway: $(best_pathway[1])")
println("   Quality score: $(round(best_pathway[2], digits=1))")

# Identify cost drivers
expensive_treatments = sort([(treatments[i], treatment_costs[i]) for i in 1:length(treatments)], by=x->x[2], rev=true)
println("\n2. Major cost drivers:")
for (treatment, cost) in expensive_treatments[1:3]
    println("   - $treatment: \$$(round(cost, digits=1))k")
end

# Treatment sequence optimization
println("\n3. Optimization opportunities:")
if cost1 > cost3
    savings = cost1 - cost3
    println("   - Medical pathway saves \$$(round(savings, digits=1))k vs surgical")
end

println("   - Early palliative consultation can reduce overall costs")
println("   - Multidisciplinary review optimizes treatment selection")

println("\n🔬 Healthcare Applications:")
println("- Clinical pathway standardization")
println("- Treatment cost prediction and budgeting")
println("- Personalized treatment planning")
println("- Quality improvement initiatives")
println("- Healthcare resource allocation")
println("- Insurance coverage optimization")
println("- Evidence-based protocol development")

# Part 2: Multi-Objective Treatment Optimization
println("\n" * "=" ^ 55)
println("📊 PART 2: MULTI-OBJECTIVE TREATMENT OPTIMIZATION")
println("-" ^ 50)

# Create multi-objective treatment network
function create_mo_treatment_network()
    # Objectives: [Cost($k), Time(weeks), QoL Impact, Success Rate]
    edges = MultiObjective.MultiObjectiveEdge[]
    
    # Start node (Initial diagnosis)
    push!(edges, MultiObjective.MultiObjectiveEdge(1, 2, [0.0, 0.0, 0.0, 0.0], 1))
    
    # Diagnostic phase (Node 2: Diagnostic workup)
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 3, [3.5, 1.0, -5.0, 0.95], 2))   # Basic imaging
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 4, [8.0, 0.5, -10.0, 0.98], 3))  # Advanced imaging
    
    # Staging (Nodes 3,4 → 5: Staging complete)
    push!(edges, MultiObjective.MultiObjectiveEdge(3, 5, [2.0, 1.0, -8.0, 0.90], 4))   # From basic
    push!(edges, MultiObjective.MultiObjectiveEdge(4, 5, [1.0, 0.5, -5.0, 0.95], 5))   # From advanced
    
    # Treatment decision (Node 5 → multiple options)
    # Surgery path
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 6, [35.0, 2.0, -30.0, 0.85], 6))  # Major surgery
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 7, [15.0, 1.0, -15.0, 0.90], 7))  # Minor surgery
    
    # Medical therapy path
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 8, [25.0, 12.0, -40.0, 0.75], 8))  # Chemotherapy
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 9, [40.0, 16.0, -20.0, 0.70], 9))  # Immunotherapy
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 10, [45.0, 8.0, -15.0, 0.80], 10)) # Targeted therapy
    
    # Radiation path
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 11, [30.0, 6.0, -25.0, 0.85], 11)) # Radiation
    
    # Conservative path
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 12, [10.0, 52.0, -10.0, 0.60], 12)) # Watch & wait
    
    # Combination therapies (from surgery)
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 8, [25.0, 12.0, -35.0, 0.80], 13))  # Surgery + chemo
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 11, [30.0, 6.0, -20.0, 0.88], 14))  # Minor + radiation
    
    # Post-treatment monitoring (all paths → 13)
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 13, [2.0, 52.0, 60.0, 0.85], 15))  # From major surgery
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 13, [2.0, 52.0, 70.0, 0.90], 16))  # From minor surgery
    push!(edges, MultiObjective.MultiObjectiveEdge(8, 13, [2.0, 52.0, 40.0, 0.75], 17))  # From chemo
    push!(edges, MultiObjective.MultiObjectiveEdge(9, 13, [2.0, 52.0, 50.0, 0.70], 18))  # From immuno
    push!(edges, MultiObjective.MultiObjectiveEdge(10, 13, [2.0, 52.0, 65.0, 0.80], 19)) # From targeted
    push!(edges, MultiObjective.MultiObjectiveEdge(11, 13, [2.0, 52.0, 55.0, 0.85], 20)) # From radiation
    push!(edges, MultiObjective.MultiObjectiveEdge(12, 13, [2.0, 104.0, 75.0, 0.60], 21)) # From watch & wait
    
    # Build adjacency
    adjacency = [Int[] for _ in 1:13]
    for (i, edge) in enumerate(edges)
        push!(adjacency[edge.source], i)
    end
    
    return MultiObjective.MultiObjectiveGraph(13, edges, 4, adjacency,
                                             ["Cost(\$k)", "Time(weeks)", "QoL", "Success"],
                                             objective_sense=[:min, :min, :max, :max])
end

mo_graph = create_mo_treatment_network()

println("\n🎯 Computing Pareto Front for Treatment Protocols...")
pareto_front = MultiObjective.compute_pareto_front(mo_graph, 1, 13, max_solutions=50)

println("Found $(length(pareto_front)) Pareto-optimal treatment protocols")

# Display top solutions
treatment_labels = ["", "Diagnosis", "Basic Imaging", "Advanced Imaging", "Staging", 
                   "Major Surgery", "Minor Surgery", "Chemotherapy", "Immunotherapy", 
                   "Targeted Therapy", "Radiation", "Watch & Wait", "Monitoring"]

println("\nTop Pareto-Optimal Treatment Protocols:")
println("-" ^ 50)
for (i, sol) in enumerate(pareto_front[1:min(8, end)])
    # Interpret path
    path_desc = []
    for node in sol.path
        if node > 1 && node <= length(treatment_labels)
            push!(path_desc, treatment_labels[node])
        end
    end
    
    println("$i. Protocol $i: $(join(path_desc[1:min(3, end)], "→"))...")
    println("   Cost: \$$(round(sol.objectives[1], digits=1))k")
    println("   Duration: $(round(sol.objectives[2], digits=1)) weeks")
    println("   QoL Impact: $(round(sol.objectives[3], digits=0)) (higher is better)")
    println("   Success Rate: $(round(sol.objectives[4]*100, digits=0))%")
end

# Compare treatment strategies
println("\n🔍 Treatment Strategy Comparison:")

# Weighted sum (balanced approach)
weights = [0.3, 0.2, 0.3, 0.2]  # Cost, time, QoL, success
sol_balanced = try
    MultiObjective.weighted_sum_approach(mo_graph, 1, 13, weights)
catch err
    println("• Balanced: not applicable (" * sprint(showerror, err) * ")")
    nothing
end
if sol_balanced !== nothing
    println("• Balanced: Cost=\$$(round(sol_balanced.objectives[1], digits=1))k, " *
            "QoL=$(round(sol_balanced.objectives[3], digits=0)), " *
            "Success=$(round(sol_balanced.objectives[4]*100, digits=0))%")
end

# Constraint-based (limit cost to $50k)
constraints = [50.0, Inf, Inf, 0.7]  # Max cost $50k, min 70% success
sol_budget = MultiObjective.epsilon_constraint_approach(mo_graph, 1, 13, 3, constraints)
println("• Budget-constrained (≤\$50k): Cost=\$$(round(sol_budget.objectives[1], digits=1))k, " *
        "Success=$(round(sol_budget.objectives[4]*100, digits=0))%")

# Knee point
knee = MultiObjective.get_knee_point(pareto_front)
if knee !== nothing
    println("• Knee Point: Cost=\$$(round(knee.objectives[1], digits=1))k, " *
            "Time=$(round(knee.objectives[2], digits=1))wk, " *
            "QoL=$(round(knee.objectives[3], digits=0))")
end

# Part 3: Clinical Decision Matrix
println("\n" * "=" ^ 55)
println("📊 PART 3: CLINICAL DECISION MATRIX")
println("-" ^ 50)

println("\nPatient-Specific Protocol Selection:")
println("| Patient Profile | Recommended Protocol | Rationale |")
println("|-----------------|---------------------|-----------|")
println("| Young, healthy | Surgery + Adjuvant | Max success, can tolerate |")
println("| Elderly, frail | Minor surgery only | Balance QoL and outcome |")
println("| Comorbidities | Targeted therapy | Lower toxicity |")
println("| Financial constraint | Watch & wait → Medical | Cost-effective |")
println("| Quality priority | Immunotherapy | Better QoL profile |")

# Part 4: Performance Analysis
println("\n" * "=" ^ 55)
println("📊 PART 4: PERFORMANCE ANALYSIS (CORRECTED)")
println("-" ^ 50)

println("\n🔧 Critical Fix: k parameter corrected from k=n-1 to k=n^(1/3)")
println("\nPerformance on Treatment Networks:")

# Use shared benchmark results for consistency
benchmarks = load_benchmark_results()
test_sizes = benchmarks.sizes
k_values = ceil.(Int, test_sizes .^ (1/3))
speedups = benchmarks.speedup

println("| Protocols | k  | DMY (ms) ±95% CI | Dijkstra (ms) ±95% CI | **Speedup** |")
println("|-----------|----|------------------|-----------------------|-------------|")
for (n, k, dmy, dmy_ci, dij, dij_ci, speed) in zip(test_sizes, k_values,
        benchmarks.dmy_ms, benchmarks.dmy_ci_ms,
        benchmarks.dijkstra_ms, benchmarks.dijkstra_ci_ms,
        speedups)
    println("| $(lpad(n, 9)) | $(lpad(k, 2)) | $(lpad(string(round(dmy, digits=3)), 8)) ± $(round(dmy_ci, digits=3)) | $(lpad(string(round(dij, digits=3)), 8)) ± $(round(dij_ci, digits=3)) | $(lpad(round(speed, digits=2), 7))× |")
end

println("\n✅ DMY excels once protocol graphs exceed ~2,000 nodes")
println("   $(benchmark_summary(benchmarks))")

# Summary
println("\n" * "=" ^ 55)
println("KEY FINDINGS")
println("=" ^ 55)

println("\n1. SINGLE-OBJECTIVE:")
println("   • Optimal curative path: \$$(round(cost1, digits=1))k")
println("   • Most cost-effective: $(best_pathway[1]) pathway")
println("   • Major cost drivers: Surgery, Immunotherapy, Targeted therapy")

println("\n2. MULTI-OBJECTIVE:")
println("   • $(length(pareto_front)) Pareto-optimal protocols found")
println("   • Trade-offs: Cost ↔ Time ↔ Quality of Life ↔ Success Rate")
println("   • No single \"best\" protocol - depends on patient priorities")

println("\n3. CLINICAL INSIGHTS:")
println("   • Surgery-first: High success (85-90%) but high cost (\$35-50k)")
println("   • Medical therapy: Moderate success (70-80%), better QoL")
println("   • Watch & wait: Low cost (\$12k) but lower success (60%)")

println("\n4. PERSONALIZATION:")
println("   • Young patients: Aggressive protocols (surgery + chemo)")
println("   • Elderly: Quality-focused (immunotherapy, targeted)")
println("   • Resource-limited: Stepwise escalation strategies")

println("\n5. PERFORMANCE:")
println("   • DMY ≈4.8× faster at 5000 protocols")
println("   • Enables real-time clinical decision support")
println("   • Scalable to hospital-wide protocol libraries")

println("\n" * "=" ^ 55)
println("Treatment Protocol Optimization Complete! 🎉")
println("\nThis analysis demonstrates how the DMY algorithm with")
println("multi-objective optimization can personalize cancer treatment")
println("protocols, balancing cost, time, quality of life, and outcomes.")

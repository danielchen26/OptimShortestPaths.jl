#!/usr/bin/env julia

"""
Generate Figures for Treatment Protocol Analysis
Creates visualizations for single and multi-objective optimization results.
"""

using OptimSPath
using OptimSPath.MultiObjective
using Plots
using StatsPlots
using Random
Random.seed!(42)
# Inline benchmark loader - reads from canonical benchmark_results.txt
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

# Multi-objective optimization tools from OptimSPath
using OptimSPath: MultiObjectiveEdge, MultiObjectiveGraph, ParetoSolution,
    compute_pareto_front, weighted_sum_approach, epsilon_constraint_approach,
    lexicographic_approach, get_knee_point, compute_path_objectives

println("🎨 Generating Treatment Protocol Visualizations")
println("=" ^ 60)

# Create figures directory
mkpath("figures")

# Part 1: Treatment Cost Analysis
println("\n📊 Creating treatment cost analysis...")

treatments = ["Screening", "Imaging", "Biopsy", "Surgery_Minor", "Surgery_Major", 
              "Chemo", "Radiation", "Immuno", "Targeted", "Palliative"]
costs = [0.5, 3.5, 1.5, 15.0, 35.0, 25.0, 30.0, 40.0, 45.0, 10.0]
efficacy = [100, 95, 98, 85, 90, 75, 85, 70, 80, 60]

p1 = groupedbar([costs efficacy/2],
    labels=["Cost (\$k)" "Efficacy (%)"],
    xticks=(1:length(treatments), treatments),
    xrotation=45,
    title="Treatment Cost vs Efficacy",
    ylabel="Value",
    xlabel="Treatment",
    legend=:topright,
    color=[:red :green],
    size=(800, 500))
savefig(p1, "figures/treatment_cost_efficacy.png")

# Part 2: Treatment Pathway Network
println("📊 Creating treatment pathway network...")

# Create adjacency matrix for treatment pathways
n_treatments = 13
adj_matrix = zeros(n_treatments, n_treatments)
pathways = [
    (1, 2), (2, 3), (3, 4), (4, 5),  # Diagnostic pathway
    (5, 6), (5, 7), (5, 8), (5, 9),  # Treatment options
    (6, 11), (7, 11), (8, 11), (9, 11),  # To monitoring
    (5, 10), (5, 11), (5, 12),  # Alternative paths
    (11, 13), (12, 13)  # To outcome
]

for (i, j) in pathways
    adj_matrix[i, j] = 1
end

pathway_labels = ["Start", "Screen", "Image", "Biopsy", "Stage", 
                 "Surgery", "Chemo", "Radiation", "Immuno", 
                 "Targeted", "Palliative", "Monitor", "Outcome"]

p2 = heatmap(adj_matrix,
    xticks=(1:n_treatments, pathway_labels),
    yticks=(1:n_treatments, pathway_labels),
    xrotation=45,
    title="Treatment Pathway Network",
    xlabel="Next Step",
    ylabel="Current Step",
    color=:viridis,
    clims=(0, 1),
    size=(800, 700))
savefig(p2, "figures/treatment_network.png")

# Part 3: Multi-Objective Pareto Front
println("📊 Creating Pareto front visualizations...")

# Create multi-objective treatment network
function create_mo_treatment_network()
    edges = MultiObjective.MultiObjectiveEdge[]
    
    # Objectives: [Cost($k), Time(weeks), QoL Impact, Success Rate]
    push!(edges, MultiObjective.MultiObjectiveEdge(1, 2, [0.0, 0.0, 0.0, 0.0], 1))
    
    # Diagnostic phase
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 3, [3.5, 1.0, -5.0, 0.95], 2))
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 4, [8.0, 0.5, -10.0, 0.98], 3))
    
    # Staging
    push!(edges, MultiObjective.MultiObjectiveEdge(3, 5, [2.0, 1.0, -8.0, 0.90], 4))
    push!(edges, MultiObjective.MultiObjectiveEdge(4, 5, [1.0, 0.5, -5.0, 0.95], 5))
    
    # Treatment options
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 6, [35.0, 2.0, -30.0, 0.85], 6))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 7, [15.0, 1.0, -15.0, 0.90], 7))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 8, [25.0, 12.0, -40.0, 0.75], 8))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 9, [40.0, 16.0, -20.0, 0.70], 9))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 10, [45.0, 8.0, -15.0, 0.80], 10))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 11, [30.0, 6.0, -25.0, 0.85], 11))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 12, [10.0, 52.0, -10.0, 0.60], 12))
    
    # Combination therapies
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 8, [25.0, 12.0, -35.0, 0.80], 13))
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 11, [30.0, 6.0, -20.0, 0.88], 14))
    
    # Post-treatment monitoring
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 13, [2.0, 52.0, 60.0, 0.85], 15))
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 13, [2.0, 52.0, 70.0, 0.90], 16))
    push!(edges, MultiObjective.MultiObjectiveEdge(8, 13, [2.0, 52.0, 40.0, 0.75], 17))
    push!(edges, MultiObjective.MultiObjectiveEdge(9, 13, [2.0, 52.0, 50.0, 0.70], 18))
    push!(edges, MultiObjective.MultiObjectiveEdge(10, 13, [2.0, 52.0, 65.0, 0.80], 19))
    push!(edges, MultiObjective.MultiObjectiveEdge(11, 13, [2.0, 52.0, 55.0, 0.85], 20))
    push!(edges, MultiObjective.MultiObjectiveEdge(12, 13, [2.0, 104.0, 75.0, 0.60], 21))
    
    adjacency = [Int[] for _ in 1:13]
    for (i, edge) in enumerate(edges)
        push!(adjacency[edge.source], i)
    end
    
    return MultiObjective.MultiObjectiveGraph(13, edges, 4, adjacency,
                                             ["Cost(\$k)", "Time(weeks)", "QoL", "Success"],
                                             objective_sense=[:min, :min, :max, :max])
end

mo_graph = create_mo_treatment_network()
pareto_front = MultiObjective.compute_pareto_front(mo_graph, 1, 13, max_solutions=50)

# Extract objectives for plotting
cost_values = [sol.objectives[1] for sol in pareto_front]
time_values = [sol.objectives[2] for sol in pareto_front]
qol_values = [sol.objectives[3] for sol in pareto_front]
success_values = [sol.objectives[4] * 100 for sol in pareto_front]  # Convert to percentage

# Create 2D projections
p3 = plot(layout=(2, 2), size=(1000, 800))

# Cost vs Success
scatter!(p3[1], cost_values, success_values,
    xlabel="Cost (\$k)",
    ylabel="Success Rate (%)",
    title="Cost vs Success Trade-off",
    label="Pareto Solutions",
    markersize=6,
    color=:viridis,
    alpha=0.8)

# Time vs QoL
scatter!(p3[2], time_values, qol_values,
    xlabel="Time (weeks)",
    ylabel="Quality of Life",
    title="Duration vs QoL",
    label="Pareto Solutions",
    markersize=6,
    color=:plasma,
    alpha=0.8)

# Cost vs QoL
scatter!(p3[3], cost_values, qol_values,
    xlabel="Cost (\$k)",
    ylabel="Quality of Life",
    title="Cost vs Quality",
    label="Pareto Solutions",
    markersize=6,
    color=:turbo,
    alpha=0.8)

# Success vs Time
scatter!(p3[4], time_values, success_values,
    xlabel="Time (weeks)",
    ylabel="Success Rate (%)",
    title="Speed vs Success",
    label="Pareto Solutions",
    markersize=6,
    color=:cividis,
    alpha=0.8)

savefig(p3, "figures/treatment_pareto_2d.png")

# Create 3D Pareto visualization with special solutions highlighted
println("📊 Creating 3D Pareto visualization...")

# Find special solutions
weights_balanced = [0.3, 0.2, 0.3, 0.2]
sol_balanced = try
    MultiObjective.weighted_sum_approach(mo_graph, 1, 13, weights_balanced)
catch err
    @info "Weighted sum not applicable for treatment protocol graph" exception=err
    nothing
end

constraints_budget = [50.0, Inf, Inf, 0.7]
sol_budget = MultiObjective.epsilon_constraint_approach(mo_graph, 1, 13, 3, constraints_budget)

knee = MultiObjective.get_knee_point(pareto_front)

p4 = scatter3d(cost_values, success_values, qol_values,
    xlabel="Cost (\$k)",
    ylabel="Success Rate (%)",
    zlabel="Quality of Life",
    title="3D Pareto Front: Treatment Protocols",
    label="Pareto Solutions",
    markersize=5,
    color=:gray,
    alpha=0.5,
    camera=(30, 30),
    size=(800, 600))

# Highlight special solutions
if sol_balanced !== nothing
    scatter3d!([sol_balanced.objectives[1]], [sol_balanced.objectives[4]*100], [sol_balanced.objectives[3]],
        label="Balanced",
        markersize=10,
        color=:blue,
        markershape=:star5)
end

if sol_budget !== nothing
    scatter3d!([sol_budget.objectives[1]], [sol_budget.objectives[4]*100], [sol_budget.objectives[3]],
        label="Budget-constrained",
        markersize=10,
        color=:green,
        markershape=:diamond)
end

if knee !== nothing
    scatter3d!([knee.objectives[1]], [knee.objectives[4]*100], [-knee.objectives[3]],
        label="Knee Point",
        markersize=10,
        color=:red,
        markershape=:hexagon)
end

savefig(p4, "figures/treatment_pareto_3d.png")

# Part 4: Treatment Strategy Comparison
println("📊 Creating treatment strategy comparison...")

strategies = ["Surgery+Chemo", "Surgery Only", "Chemo+Radiation", "Immuno", "Targeted", "Watch&Wait"]
strategy_cost = [60.0, 35.0, 55.0, 42.0, 47.0, 12.0]
strategy_success = [88.0, 85.0, 80.0, 70.0, 80.0, 60.0]
strategy_qol = [30.0, 60.0, 35.0, 50.0, 65.0, 75.0]

p5 = groupedbar([strategy_cost strategy_success strategy_qol],
    labels=["Cost (\$k)" "Success (%)" "QoL Score"],
    xticks=(1:length(strategies), strategies),
    xrotation=45,
    title="Treatment Strategy Comparison",
    ylabel="Value",
    xlabel="Strategy",
    legend=:topright,
    size=(800, 500))
savefig(p5, "figures/treatment_strategies.png")

# Part 5: Risk-Benefit Analysis
println("📊 Creating risk-benefit analysis...")

treatments_rb = ["Surgery", "Chemo", "Radiation", "Immuno", "Targeted", "Palliative"]
risk_scores = [30, 40, 25, 20, 15, 10]  # Risk level (0-100)
benefit_scores = [85, 75, 85, 70, 80, 60]  # Benefit level (0-100)

p6 = scatter(risk_scores, benefit_scores,
    xlabel="Risk Score",
    ylabel="Benefit Score",
    title="Risk-Benefit Analysis",
    label=nothing,
    markersize=10,
    color=:viridis,
    alpha=0.8,
    size=(800, 500))

# Add treatment labels
for (i, txt) in enumerate(treatments_rb)
    annotate!(risk_scores[i], benefit_scores[i], 
        text(txt, 8, :center))
end

# Add quadrant lines
hline!([70], line=(:dash, :gray), label=nothing)
vline!([25], line=(:dash, :gray), label=nothing)

# Add quadrant labels
annotate!(12, 90, text("Low Risk\nHigh Benefit", 8, :green))
annotate!(38, 90, text("High Risk\nHigh Benefit", 8, :yellow))
annotate!(12, 50, text("Low Risk\nLow Benefit", 8, :blue))
annotate!(38, 50, text("High Risk\nLow Benefit", 8, :red))

savefig(p6, "figures/risk_benefit.png")

# Part 6: Performance Comparison
println("📊 Creating performance comparison...")

# Performance data (shared benchmarks)
benchmarks = load_benchmark_results()
sizes = benchmarks.sizes
k_values = ceil.(Int, sizes .^ (1/3))
dmy_times = benchmarks.dmy_ms
dijkstra_times = benchmarks.dijkstra_ms
dmy_ci = benchmarks.dmy_ci_ms
dijkstra_ci = benchmarks.dijkstra_ci_ms

p7 = plot(sizes, [dmy_times dijkstra_times],
    xlabel="Number of Treatment Protocols",
    ylabel="Runtime (ms)",
    title="Performance: DMY vs Dijkstra (Corrected)",
    label=["DMY (k=n^(1/3))" "Dijkstra"],
    lw=2,
    marker=:circle,
    markersize=6,
    xscale=:log10,
    yscale=:log10,
    xlims=(100, 10000),
    ylims=(0.01, 50),
    legend=:topleft,
    size=(800, 500))

# Add speedup annotations
for (n, dmy, ci_dmy, dijk, ci_dij) in zip(sizes, dmy_times, dmy_ci, dijkstra_times, dijkstra_ci)
    if ci_dmy > 0
        plot!(p7, [n, n], [dmy - ci_dmy, dmy + ci_dmy]; color=:green, lw=1)
    end
    if ci_dij > 0
        plot!(p7, [n, n], [dijk - ci_dij, dijk + ci_dij]; color=:orange, lw=1)
    end
    speedup = dijk / dmy
    if speedup > 1
        annotate!(n, dmy, text("$(round(speedup, digits=2))x", 8, :green, :bottom))
    end
end

savefig(p7, "figures/treatment_performance.png")
println("  $(benchmark_summary(benchmarks))")

# Part 7: Patient-Specific Protocol Selection
println("📊 Creating patient profile analysis...")

profiles = ["Young\nHealthy", "Elderly\nFrail", "High\nComorbidity", "Limited\nResources", "Quality\nFocus"]
profile_cost = [60, 25, 45, 15, 40]
profile_success = [90, 70, 75, 65, 72]
profile_qol = [40, 75, 60, 65, 85]

p8 = groupedbar([profile_cost profile_success profile_qol],
    labels=["Cost (\$k)" "Success (%)" "QoL Score"],
    xticks=(1:length(profiles), profiles),
    title="Patient-Specific Protocol Selection",
    ylabel="Value",
    xlabel="Patient Profile",
    legend=:topright,
    size=(800, 500))
savefig(p8, "figures/patient_profiles.png")

# Part 8: Clinical Decision Tree
println("📊 Creating clinical decision tree visualization...")

# Simple decision tree representation
decision_data = [
    "Initial Assessment" => [70, 80],
    "High Risk" => [40, 85],
    "Low Risk" => [30, 70],
    "Aggressive" => [60, 90],
    "Conservative" => [20, 65],
    "Palliative" => [15, 60]
]

labels = [k for (k, v) in decision_data]
x_pos = [1, 0.5, 1.5, 0.2, 0.8, 1.2]
y_pos = [3, 2, 2, 1, 1, 1]
costs = [v[1] for (k, v) in decision_data]

p9 = scatter(x_pos, y_pos,
    markersize=costs/2,
    color=:viridis,
    xlabel="Treatment Intensity",
    ylabel="Decision Level",
    title="Clinical Decision Tree",
    label=nothing,
    xlims=(0, 2),
    ylims=(0.5, 3.5),
    size=(800, 500))

# Add labels
for (i, txt) in enumerate(labels)
    annotate!(x_pos[i], y_pos[i], text(txt, 8, :center))
end

# Add decision arrows
plot!([1, 0.5], [2.8, 2.2], arrow=true, color=:gray, label=nothing)
plot!([1, 1.5], [2.8, 2.2], arrow=true, color=:gray, label=nothing)
plot!([0.5, 0.2], [1.8, 1.2], arrow=true, color=:gray, label=nothing)
plot!([0.5, 0.8], [1.8, 1.2], arrow=true, color=:gray, label=nothing)
plot!([1.5, 1.2], [1.8, 1.2], arrow=true, color=:gray, label=nothing)

savefig(p9, "figures/decision_tree.png")

println("\n✅ All figures generated successfully!")
println("\nFigures created in 'figures/' directory:")
println("  1. treatment_cost_efficacy.png - Cost vs efficacy analysis")
println("  2. treatment_network.png - Treatment pathway network")
println("  3. treatment_pareto_2d.png - 2D Pareto projections")
println("  4. treatment_pareto_3d.png - 3D Pareto visualization")
println("  5. treatment_strategies.png - Strategy comparison")
println("  6. risk_benefit.png - Risk-benefit analysis")
println("  7. treatment_performance.png - Algorithm performance")
println("  8. patient_profiles.png - Patient-specific protocols")
println("  9. decision_tree.png - Clinical decision tree")

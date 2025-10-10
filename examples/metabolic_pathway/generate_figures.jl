#!/usr/bin/env julia

"""
Generate Figures for Metabolic Pathway Analysis
Creates visualizations for single and multi-objective optimization results.
"""

using OptimShortestPaths
using OptimShortestPaths.MultiObjective
using Plots
using StatsPlots
using Random
include(joinpath(@__DIR__, "..", "utils", "seed_utils.jl"))
using .ExampleSeedUtils
const BASE_SEED = configure_global_rng()
reset_global_rng(BASE_SEED, :metabolic_figures)
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

# Multi-objective optimization tools from OptimShortestPaths
using OptimShortestPaths: MultiObjectiveEdge, MultiObjectiveGraph, ParetoSolution,
    compute_pareto_front, weighted_sum_approach, epsilon_constraint_approach,
    lexicographic_approach, get_knee_point, compute_path_objectives

include("common.jl")

println("🎨 Generating Metabolic Pathway Visualizations")
println("=" ^ 60)

# Create figures directory
fig_dir = joinpath(@__DIR__, "figures")
mkpath(fig_dir)

# Part 1: Metabolic Network Visualization
println("\n📊 Creating metabolic network diagram...")

# Build adjacency matrix directly from the shared reaction network
metabolites = METABOLITES
n_met = length(metabolites)
adj_matrix = zeros(n_met, n_met)

met_indices = metabolite_indices()
for (substrate, _, product) in REACTION_NETWORK
    if haskey(met_indices, substrate) && haskey(met_indices, product)
        adj_matrix[met_indices[substrate], met_indices[product]] = 1
    end
end

# Create pathway network heatmap
p1 = heatmap(adj_matrix,
    xticks=(1:n_met, metabolites),
    yticks=(1:n_met, metabolites),
    xrotation=45,
    title="Metabolic Pathway Network",
    xlabel="Product",
    ylabel="Substrate",
    color=:viridis,
    clims=(0, 1),
    size=(800, 700))
savefig(p1, joinpath(fig_dir, "metabolic_network.png"))

# Part 2: Enzyme Cost Analysis
println("📊 Creating enzyme cost analysis...")

enzyme_data = enzyme_cost_dataframe()

p2 = groupedbar([enzyme_data.costs enzyme_data.loads],
    labels=["ATP Cost" "Enzyme Load"],
    xticks=(1:length(enzyme_data.names), enzyme_data.names),
    xrotation=45,
    title="Enzyme Costs in Metabolic Pathways",
    ylabel="Cost/Load (arbitrary units)",
    xlabel="Enzyme",
    legend=:topright,
    size=(800, 500))
savefig(p2, joinpath(fig_dir, "enzyme_costs.png"))

# Part 3: Multi-Objective Pareto Front
println("📊 Creating Pareto front visualizations...")

mo_graph, atp_adjustments = create_mo_metabolic_network()
pareto_front = MultiObjective.compute_pareto_front(mo_graph, 1, 11, max_solutions=50)
pareto_front = apply_atp_adjustment!(mo_graph, pareto_front, atp_adjustments)

# Extract objectives for plotting
atp_values = [-sol.objectives[1] for sol in pareto_front]  # Negate for ATP production
time_values = [sol.objectives[2] for sol in pareto_front]
enzyme_values = [sol.objectives[3] for sol in pareto_front]
byproduct_values = [sol.objectives[4] for sol in pareto_front]

# Create 2D projections
p3 = plot(layout=(2, 2), size=(1000, 800))

# ATP vs Time
scatter!(p3[1], time_values, atp_values,
    xlabel="Time (min)",
    ylabel="ATP Production",
    title="ATP vs Time Trade-off",
    label="Pareto Solutions",
    markersize=6,
    color=:viridis,
    alpha=0.8)

# ATP vs Enzyme Load
scatter!(p3[2], enzyme_values, atp_values,
    xlabel="Enzyme Load",
    ylabel="ATP Production",
    title="ATP vs Enzyme Load",
    label="Pareto Solutions",
    markersize=6,
    color=:plasma,
    alpha=0.8)

# Time vs Byproducts
scatter!(p3[3], byproduct_values, time_values,
    xlabel="Byproduct Load (×)",
    ylabel="Time (min)",
    title="Speed vs Cleanliness",
    label="Pareto Solutions",
    markersize=6,
    color=:turbo,
    alpha=0.8)

# Enzyme Load vs Byproducts
scatter!(p3[4], byproduct_values, enzyme_values,
    xlabel="Byproduct Load (×)",
    ylabel="Enzyme Load",
    title="Efficiency vs Cleanliness",
    label="Pareto Solutions",
    markersize=6,
    color=:cividis,
    alpha=0.8)

savefig(p3, joinpath(fig_dir, "metabolic_pareto_2d.png"))

# Create 3D Pareto visualization with special solutions highlighted
println("📊 Creating 3D Pareto visualization...")

# Find special solutions
weights_balanced = [0.4, 0.2, 0.2, 0.2]
sol_balanced = try
    MultiObjective.weighted_sum_approach(mo_graph, 1, 11, weights_balanced)
catch err
    @info "Weighted sum not applicable for metabolic network" exception=err
    nothing
end

constraints_clean = [Inf, Inf, Inf, 0.3]
sol_clean = MultiObjective.epsilon_constraint_approach(mo_graph, 1, 11, 1, constraints_clean)

knee = MultiObjective.get_knee_point(pareto_front)

p4 = scatter3d(time_values, atp_values, enzyme_values,
    xlabel="Time (min)",
    ylabel="ATP Production",
    zlabel="Enzyme Load",
    title="3D Pareto Front: Metabolic Pathways",
    label="Pareto Solutions",
    markersize=5,
    color=:gray,
    alpha=0.5,
    camera=(30, 30),
    size=(800, 600))

# Highlight special solutions
if sol_balanced !== nothing
    scatter3d!([sol_balanced.objectives[2]], [-sol_balanced.objectives[1]], [sol_balanced.objectives[3]],
        label="Balanced",
        markersize=10,
        color=:blue,
        markershape=:star5)
end

if sol_clean !== nothing
    scatter3d!([sol_clean.objectives[2]], [-sol_clean.objectives[1]], [sol_clean.objectives[3]],
        label="Load ≤0.30×",
        markersize=10,
        color=:green,
        markershape=:diamond)
end

if knee !== nothing
    scatter3d!([knee.objectives[2]], [-knee.objectives[1]], [knee.objectives[3]],
        label="Knee Point",
        markersize=10,
        color=:red,
        markershape=:hexagon)
end

savefig(p4, joinpath(fig_dir, "metabolic_pareto_3d.png"))

# Part 4: Pathway Strategy Comparison
println("📊 Creating pathway strategy comparison...")

# Define metabolic strategies
strategies = ["Aerobic", "Anaerobic", "PPP", "Balanced", "Clean", "Knee"]
strategy_atp = [30.0, 2.0, 5.0, 15.0, 10.0, 18.0]
strategy_time = [8.0, 2.0, 4.0, 5.0, 6.0, 4.5]
strategy_byproducts = [0.2, 1.0, 0.5, 0.4, 0.3, 0.35]

p5 = groupedbar([strategy_atp strategy_time strategy_byproducts],
    labels=["ATP Yield" "Time (min)" "Load (×)"],
    xticks=(1:length(strategies), strategies),
    xrotation=45,
    title="Metabolic Strategy Comparison",
    ylabel="Value",
    xlabel="Strategy",
    legend=:topright,
    size=(800, 500))
savefig(p5, joinpath(fig_dir, "metabolic_strategies.png"))

# Part 5: Performance Comparison
println("📊 Creating performance comparison...")

benchmarks = load_benchmark_results()
sizes = benchmarks.sizes
dmy_times = benchmarks.dmy_ms
dmy_ci = benchmarks.dmy_ci_ms
dijkstra_times = benchmarks.dijkstra_ms
dijkstra_ci = benchmarks.dijkstra_ci_ms

p6 = plot(sizes, [dmy_times dijkstra_times],
    xlabel="Number of Metabolites",
    ylabel="Runtime (ms)",
    title="Performance: DMY vs Dijkstra (k = ⌈n^{1/3}⌉)",
    label=["DMY" "Dijkstra"],
    lw=2,
    marker=:circle,
    markersize=6,
    xscale=:log10,
    yscale=:log10,
    xlims=(100, 10000),
    ylims=(0.01, 50),
    legend=:topleft,
    size=(900, 520))

for (size, dmy, dmy_err, dijk, dijk_err) in zip(sizes, dmy_times, dmy_ci, dijkstra_times, dijkstra_ci)
    if dmy_err > 0
        plot!(p6, [size, size], [dmy - dmy_err, dmy + dmy_err]; color=:green, lw=1)
    end
    if dijk_err > 0
        plot!(p6, [size, size], [dijk - dijk_err, dijk + dijk_err]; color=:orange, lw=1)
    end
    speedup = dijk / dmy
    if speedup > 1
        annotate!(size, dmy, text("$(round(speedup, digits=2))x", 8, :green, :bottom))
    end
end

savefig(p6, joinpath(fig_dir, "metabolic_performance.png"))
println("  $(benchmark_summary(benchmarks))")

# Part 6: ATP Yield Pathways
println("📊 Creating ATP yield analysis...")

pathways = ["Glycolysis", "Fermentation", "Aerobic", "PPP+Glycolysis"]
gross_atp = [4.0, 2.0, 36.0, 3.0]
atp_cost = [2.0, 0.0, 4.0, 1.0]
net_atp = gross_atp .- atp_cost

p7 = groupedbar([gross_atp atp_cost net_atp],
    labels=["Gross ATP" "ATP Cost" "Net ATP"],
    xticks=(1:length(pathways), pathways),
    xrotation=30,
    title="ATP Yield by Metabolic Pathway",
    ylabel="ATP molecules",
    xlabel="Pathway",
    legend=:topright,
    color=[:green :red :blue],
    size=(800, 500))
savefig(p7, joinpath(fig_dir, "atp_yield.png"))

println("\n✅ All figures generated successfully!")
println("\nFigures created in $(fig_dir):")
println("  1. metabolic_network.png - Network structure")
println("  2. enzyme_costs.png - Enzyme cost analysis")
println("  3. metabolic_pareto_2d.png - 2D Pareto projections")
println("  4. metabolic_pareto_3d.png - 3D Pareto visualization")
println("  5. metabolic_strategies.png - Strategy comparison")
println("  6. metabolic_performance.png - Algorithm performance")
println("  7. atp_yield.png - ATP yield analysis")

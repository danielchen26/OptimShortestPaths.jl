#!/usr/bin/env julia

"""
Generate Figures for Treatment Protocol Analysis
Creates visualizations for single and multi-objective optimization results.
"""

using OptimShortestPaths
using OptimShortestPaths.MultiObjective
using Plots
using StatsPlots
using Colors
using Random
include(joinpath(@__DIR__, "..", "utils", "seed_utils.jl"))
using .ExampleSeedUtils
const BASE_SEED = configure_global_rng()
reset_global_rng(BASE_SEED, :treatment_figures)
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

# Set plotting defaults for publication quality
gr(dpi=300)
default(
    titlefont = (14, "sans-serif"),
    guidefont = (12, "sans-serif"),
    tickfont = (10, "sans-serif"),
    legendfont = (10, "sans-serif"),
    framestyle = :box,
    grid = true,
    dpi = 300
)

println("🎨 Generating Treatment Protocol Visualizations")
println("=" ^ 60)

# Create figures directory
fig_dir = joinpath(@__DIR__, "figures")
mkpath(fig_dir)

# Part 1: Treatment Cost Analysis
println("\n📊 Creating treatment cost analysis...")

selection = [
    ("Initial_Screening", "Screening"),
    ("Diagnostic_Imaging", "Imaging"),
    ("Biopsy", "Biopsy"),
    ("Surgery_Minor", "Surgery_Minor"),
    ("Surgery_Major", "Surgery_Major"),
    ("Chemotherapy_Neoadjuvant", "Chemo"),
    ("Radiation_Therapy", "Radiation"),
    ("Immunotherapy", "Immuno"),
    ("Targeted_Therapy", "Targeted"),
    ("Palliative_Care", "Palliative")
]

index_map = treatment_index_map()
costs = [TREATMENT_COSTS[index_map[name]] for (name, _) in selection]
efficacy = [EFFICACY_WEIGHTS[index_map[name]] * 100 for (name, _) in selection]
labels = [label for (_, label) in selection]

p1 = groupedbar([costs efficacy],
    labels=["Cost (\$k)" "Efficacy (%)"],
    xticks=(1:length(labels), labels),
    xrotation=45,
    title="Treatment Cost vs Efficacy",
    ylabel="Value",
    xlabel="Treatment",
    legend=:topright,
    color=[:red :green],
    size=(800, 500),
    dpi=300)
savefig(p1, joinpath(fig_dir, "treatment_cost_efficacy.png"))

# Part 2: Treatment Pathway Network
println("📊 Creating treatment pathway network...")

all_nodes = unique(vcat([src for (src, _, _) in TREATMENT_TRANSITIONS],
                        [dst for (_, dst, _) in TREATMENT_TRANSITIONS]))

level_layout = [
    0 => ["Initial_Screening"],
    1 => ["Diagnostic_Imaging"],
    2 => ["Biopsy"],
    3 => ["Staging"],
    4 => ["Multidisciplinary_Review"],
    5 => ["Surgery_Consultation", "Medical_Oncology", "Radiation_Oncology"],
    6 => ["Chemotherapy_Neoadjuvant", "Surgery_Minor", "Surgery_Major"],
    7 => ["Chemotherapy_Adjuvant", "Radiation_Therapy", "Immunotherapy", "Targeted_Therapy"],
    8 => ["Follow_up_Monitoring", "Palliative_Care"],
    9 => ["Recurrence_Detection", "Second_Line_Treatment"],
    10 => ["Remission"]
]

coords = Dict{String, Tuple{Float64, Float64}}()
for (lvl, names) in level_layout
    spacing = length(names) == 1 ? [0.0] : collect(range(-(length(names)-1)/2, (length(names)-1)/2, length=length(names)))
    for (idx, name) in enumerate(names)
        coords[name] = (Float64(lvl), Float64(spacing[idx]))
    end
end

missing = setdiff(all_nodes, keys(coords))
!isempty(missing) && error("Missing layout positions for nodes: $(collect(missing))")

function treatment_category(name::String)
    if name in ("Initial_Screening", "Diagnostic_Imaging", "Biopsy")
        return "Diagnostics"
    elseif name in ("Staging", "Multidisciplinary_Review")
        return "Planning"
    elseif name in ("Surgery_Consultation", "Medical_Oncology", "Radiation_Oncology")
        return "Specialist Consults"
    elseif name in ("Chemotherapy_Neoadjuvant", "Surgery_Minor", "Surgery_Major",
                    "Chemotherapy_Adjuvant", "Radiation_Therapy", "Immunotherapy", "Targeted_Therapy")
        return "Active Treatment"
    else
        return "Follow-up & Support"
    end
end

function pretty_label(name::String)
    words = split(replace(name, "_" => " "))
    if length(words) <= 2
        return join(words, "\n")
    else
        split_idx = ceil(Int, length(words) / 2)
        return join(words[1:split_idx], " ") * "\n" * join(words[split_idx+1:end], " ")
    end
end

p2 = plot(title="Treatment Pathway Network",
    size=(950, 550),
    dpi=300,
    xlims=(-0.5, 10.5),
    ylims=(-3.0, 3.0),
    xticks=[],
    yticks=[],
    framestyle=:none,
    legend=:outerright,
    background_color=:white)

for (src, dst, _) in TREATMENT_TRANSITIONS
    x1, y1 = coords[src]
    x2, y2 = coords[dst]
    plot!([x1, x2], [y1, y2];
        seriestype=:path,
        color=:gray70,
        linewidth=1.2,
        alpha=0.8,
        arrow=:arrow,
        label="")
end

category_palette = Dict(
    "Diagnostics" => RGB(0.20, 0.47, 0.75),
    "Planning" => RGB(0.93, 0.53, 0.18),
    "Specialist Consults" => RGB(0.57, 0.27, 0.68),
    "Active Treatment" => RGB(0.18, 0.62, 0.36),
    "Follow-up & Support" => RGB(0.80, 0.20, 0.33)
)

ordered_categories = ["Diagnostics", "Planning", "Specialist Consults", "Active Treatment", "Follow-up & Support"]
for category in ordered_categories
    nodes = [name for name in keys(coords) if treatment_category(name) == category]
    isempty(nodes) && continue
    xs = [coords[name][1] for name in nodes]
    ys = [coords[name][2] for name in nodes]
    scatter!(xs, ys;
        markersize=12,
        marker=:circle,
        markerstrokecolor=:black,
        markerstrokealpha=0.5,
        markercolor=category_palette[category],
        label=category)
    for name in nodes
        x, y = coords[name]
        annotate!(x, y + 0.35, text(pretty_label(name), 8, :center))
    end
end

# Highlight terminal remission node
if haskey(coords, "Remission")
    x_rem, y_rem = coords["Remission"]
    scatter!([x_rem], [y_rem];
        markersize=14,
        marker=:star5,
        markerstrokecolor=:goldenrod,
        markerstrokewidth=1.5,
        markercolor=:gold,
        label="Remission")
end

savefig(p2, joinpath(fig_dir, "treatment_network.png"))

# Part 3: Multi-Objective Pareto Front
println("📊 Creating Pareto front visualizations...")

mo_graph = create_mo_treatment_network()
pareto_front = MultiObjective.compute_pareto_front(mo_graph, 1, 13, max_solutions=50)

# Extract objectives for plotting
cost_values = [sol.objectives[1] for sol in pareto_front]
time_values = [sol.objectives[2] for sol in pareto_front]
qol_values = [sol.objectives[3] for sol in pareto_front]
success_values = [sol.objectives[4] * 100 for sol in pareto_front]  # Convert to percentage

# Create 2D projections
p3 = plot(layout=(2, 2), size=(1000, 800), dpi=300)

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

savefig(p3, joinpath(fig_dir, "treatment_pareto_2d.png"))

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
    size=(800, 600),
    dpi=300)

# Highlight special solutions
if sol_balanced !== nothing
    scatter3d!([sol_balanced.objectives[1]], [sol_balanced.objectives[4]*100], [sol_balanced.objectives[3]],
        label="Balanced",
        markersize=10,
        color=:blue,
        markershape=:star5)
end

if sol_budget !== nothing && all(isfinite, sol_budget.objectives)
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

if sol_budget === nothing || !all(isfinite, sol_budget.objectives)
    annotate!(p4, minimum(cost_values) + 5, maximum(success_values) - 5,
        text("Budget constraint (≤\$50k) infeasible", 8, :green))
end

savefig(p4, joinpath(fig_dir, "treatment_pareto_3d.png"))

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
    size=(800, 500),
    dpi=300)
savefig(p5, joinpath(fig_dir, "treatment_strategies.png"))

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
    size=(800, 500),
    dpi=300)

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

savefig(p6, joinpath(fig_dir, "risk_benefit.png"))

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

p7 = plot(sizes, dmy_times;
    xlabel="Number of Treatment Protocols",
    ylabel="Runtime (ms)",
    title="Performance: DMY vs Dijkstra",
    label="DMY (k = n^{1/3})",
    lw=3,
    marker=:circle,
    markersize=7,
    color=:navy,
    xscale=:log10,
    yscale=:log10,
    xlims=(100, 10000),
    ylims=(0.01, 50),
    legend=:bottomright,
    size=(850, 520),
    dpi=300)

plot!(p7, sizes, dijkstra_times;
    label="Dijkstra",
    lw=3,
    marker=:diamond,
    markersize=7,
    color=:darkorange)

# Add speedup annotations
for (n, dmy, ci_dmy, dijk, ci_dij) in zip(sizes, dmy_times, dmy_ci, dijkstra_times, dijkstra_ci)
    if ci_dmy > 0
        lower = max(dmy - ci_dmy, 1e-4)
        upper = dmy + ci_dmy
        plot!(p7, [n, n], [lower, upper]; color=:navy, lw=1.2, label="")
    end
    if ci_dij > 0
        lower = max(dijk - ci_dij, 1e-4)
        upper = dijk + ci_dij
        plot!(p7, [n, n], [lower, upper]; color=:darkorange, lw=1.2, label="")
    end
    speedup = dijk / dmy
    if speedup > 1
        annotate!(n, dmy,
            text("$(round(speedup, digits=2))×", 8, :black, :bottom))
    end
end

savefig(p7, joinpath(fig_dir, "treatment_performance.png"))
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
    size=(800, 500),
    dpi=300)
savefig(p8, joinpath(fig_dir, "patient_profiles.png"))

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
    size=(800, 500),
    dpi=300)

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

savefig(p9, joinpath(fig_dir, "decision_tree.png"))

println("\n✅ All figures generated successfully!")
println("\nFigures created in $(fig_dir):")
println("  1. treatment_cost_efficacy.png - Cost vs efficacy analysis")
println("  2. treatment_network.png - Treatment pathway network")
println("  3. treatment_pareto_2d.png - 2D Pareto projections")
println("  4. treatment_pareto_3d.png - 3D Pareto visualization")
println("  5. treatment_strategies.png - Strategy comparison")
println("  6. risk_benefit.png - Risk-benefit analysis")
println("  7. treatment_performance.png - Algorithm performance")
println("  8. patient_profiles.png - Patient-specific protocols")
println("  9. decision_tree.png - Clinical decision tree")

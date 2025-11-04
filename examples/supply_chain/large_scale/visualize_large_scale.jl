#!/usr/bin/env julia

"""
Visualize Large-Scale Network Structure and Paths

Creates graph visualizations showing:
1. Network topology with geographic regions
2. Sample optimal paths from factories to customers
3. Pareto front visualization for multi-objective optimization
"""

using Random
using Statistics
using OptimShortestPaths
using OptimShortestPaths.MultiObjective
using Plots
using Colors

println("=" ^ 80)
println("🎨 LARGE-SCALE NETWORK VISUALIZATION")
println("=" ^ 80)
println()

# Load the network (smaller version for visualization clarity)
const RNG = MersenneTwister(42)
const N_FACTORIES = 5
const N_DCS = 15
const N_WAREHOUSES = 30
const N_CUSTOMERS = 50
const TOTAL_NODES = N_FACTORIES + N_DCS + N_WAREHOUSES + N_CUSTOMERS

println("Creating visualizable network ($(TOTAL_NODES) nodes for clarity)...")

# Node ranges
factory_range = 1:N_FACTORIES
dc_range = (N_FACTORIES + 1):(N_FACTORIES + N_DCS)
warehouse_range = (N_FACTORIES + N_DCS + 1):(N_FACTORIES + N_DCS + N_WAREHOUSES)
customer_range = (N_FACTORIES + N_DCS + N_WAREHOUSES + 1):TOTAL_NODES

# Assign to regions
n_regions = 4
factory_regions = [rand(RNG, 1:n_regions) for _ in 1:N_FACTORIES]
dc_regions = [rand(RNG, 1:n_regions) for _ in 1:N_DCS]
warehouse_regions = [rand(RNG, 1:n_regions) for _ in 1:N_WAREHOUSES]
customer_regions = [rand(RNG, 1:n_regions) for _ in 1:N_CUSTOMERS]

# Generate positions based on regions (for visualization)
function generate_positions(node_range, regions, n_regions, layer_y)
    positions = Tuple{Float64, Float64}[]
    for (i, node) in enumerate(node_range)
        region = regions[i]
        # Spread nodes within their region
        region_x = (region - 1) * (1.0 / n_regions) + 0.5 / n_regions
        jitter_x = (rand(RNG) - 0.5) * 0.15 / n_regions
        jitter_y = (rand(RNG) - 0.5) * 0.1
        push!(positions, (region_x + jitter_x, layer_y + jitter_y))
    end
    return positions
end

factory_pos = generate_positions(factory_range, factory_regions, n_regions, 0.9)
dc_pos = generate_positions(dc_range, dc_regions, n_regions, 0.6)
warehouse_pos = generate_positions(warehouse_range, warehouse_regions, n_regions, 0.3)
customer_pos = generate_positions(customer_range, customer_regions, n_regions, 0.05)

all_positions = vcat(factory_pos, dc_pos, warehouse_pos, customer_pos)

# Build network
function calculate_distance(region1, region2, base_dist, rng)
    if region1 == region2
        return base_dist * rand(rng, 50:200)
    else
        return base_dist * rand(rng, 500:3000)
    end
end

edges = Edge[]
weights = Float64[]
global edge_idx = 0

# Factory → DC
for (i, factory) in enumerate(factory_range)
    factory_region = factory_regions[i]
    same_region_dcs = [dc for (dc_idx, dc) in enumerate(dc_range) if dc_regions[dc_idx] == factory_region]
    n_connections = min(length(same_region_dcs), 5)
    if n_connections > 0
        for dc in shuffle(RNG, same_region_dcs)[1:n_connections]
            global edge_idx += 1
            push!(edges, Edge(factory, dc, edge_idx))
            dc_idx = dc - N_FACTORIES
            push!(weights, calculate_distance(factory_region, dc_regions[dc_idx], 1.0, RNG))
        end
    end
end

# DC → Warehouse
for (i, dc) in enumerate(dc_range)
    dc_region = dc_regions[i]
    same_region_wh = [wh for (wh_idx, wh) in enumerate(warehouse_range) if warehouse_regions[wh_idx] == dc_region]
    n_connections = min(length(same_region_wh), 4)
    if n_connections > 0
        for warehouse in shuffle(RNG, same_region_wh)[1:n_connections]
            global edge_idx += 1
            push!(edges, Edge(dc, warehouse, edge_idx))
            wh_idx = warehouse - N_FACTORIES - N_DCS
            push!(weights, calculate_distance(dc_region, warehouse_regions[wh_idx], 0.5, RNG))
        end
    end
end

# Warehouse → Customer
customers_per_warehouse = div(N_CUSTOMERS, N_WAREHOUSES) + 1
customer_assignments = shuffle(RNG, collect(customer_range))
for (i, warehouse) in enumerate(warehouse_range)
    wh_region = warehouse_regions[i]
    start_idx = (i - 1) * customers_per_warehouse + 1
    end_idx = min(i * customers_per_warehouse, N_CUSTOMERS)

    if start_idx <= length(customer_assignments)
        assigned_customers = customer_assignments[start_idx:min(end_idx, length(customer_assignments))]
        for customer in assigned_customers
            global edge_idx += 1
            push!(edges, Edge(warehouse, customer, edge_idx))
            cust_idx = customer - N_FACTORIES - N_DCS - N_WAREHOUSES
            push!(weights, calculate_distance(wh_region, customer_regions[cust_idx], 0.2, RNG))
        end
    end
end

graph = DMYGraph(TOTAL_NODES, edges, weights)
println("  Network built: $(length(edges)) edges")
println()

# Color palette
COLORS = [
    colorant"#E69F00",  # Orange
    colorant"#56B4E9",  # Sky Blue
    colorant"#009E73",  # Green
    colorant"#F0E442",  # Yellow
    colorant"#0072B2",  # Blue
    colorant"#D55E00",  # Vermillion
    colorant"#CC79A7",  # Pink
    colorant"#999999",  # Gray
]

figures_dir = joinpath(@__DIR__, "figures")
mkpath(figures_dir)

println("1. Network Topology Visualization...")

# Publication-quality topology figure
p1 = plot(legend=:outerright, size=(1400, 900),
          xlims=(-0.08, 1.08), ylims=(-0.08, 1.08),
          xlabel="Geographic Region", ylabel="Supply Chain Echelon",
          title="Multi-Echelon Supply Chain Network Topology",
          titlefontsize=18, labelfontsize=14, tickfontsize=12,
          guidefontsize=14, legendfontsize=12,
          framestyle=:box, grid=true, gridlinewidth=0.5, gridalpha=0.2,
          margin=8Plots.mm, dpi=300,
          xticks=([0, 0.33, 0.67, 1.0], ["Region 1", "Region 2", "Region 3", "Region 4"]),
          yticks=([0.05, 0.3, 0.6, 0.9], ["Customers", "Warehouses", "DCs", "Factories"]))

# Draw edges with directional flow (Factory → DC → Warehouse → Customer)
# Group edges by type for cleaner visualization
factory_dc_edges = [(e, w) for (e, w) in zip(edges, weights) if e.source in factory_range && e.target in dc_range]
dc_wh_edges = [(e, w) for (e, w) in zip(edges, weights) if e.source in dc_range && e.target in warehouse_range]
wh_cust_edges = [(e, w) for (e, w) in zip(edges, weights) if e.source in warehouse_range && e.target in customer_range]

# Draw edges with transparency based on layer
for (edge, weight) in factory_dc_edges
    x1, y1 = all_positions[edge.source]
    x2, y2 = all_positions[edge.target]
    plot!(p1, [x1, x2], [y1, y2], color=COLORS[1], alpha=0.15, linewidth=0.8, label="")
end
for (edge, weight) in dc_wh_edges
    x1, y1 = all_positions[edge.source]
    x2, y2 = all_positions[edge.target]
    plot!(p1, [x1, x2], [y1, y2], color=COLORS[2], alpha=0.12, linewidth=0.6, label="")
end
for (edge, weight) in wh_cust_edges
    x1, y1 = all_positions[edge.source]
    x2, y2 = all_positions[edge.target]
    plot!(p1, [x1, x2], [y1, y2], color=COLORS[3], alpha=0.08, linewidth=0.4, label="")
end

# Draw nodes by type with improved styling
scatter!(p1, [p[1] for p in factory_pos], [p[2] for p in factory_pos],
         color=COLORS[1], markersize=12, markershape=:square,
         markerstrokealpha=0.8, markerstrokewidth=1.5, markerstrokecolor=:white,
         label="Factories ($(N_FACTORIES))")
scatter!(p1, [p[1] for p in dc_pos], [p[2] for p in dc_pos],
         color=COLORS[2], markersize=9, markershape=:diamond,
         markerstrokealpha=0.8, markerstrokewidth=1.5, markerstrokecolor=:white,
         label="Distribution Centers ($(N_DCS))")
scatter!(p1, [p[1] for p in warehouse_pos], [p[2] for p in warehouse_pos],
         color=COLORS[3], markersize=7, markershape=:circle,
         markerstrokealpha=0.8, markerstrokewidth=1, markerstrokecolor=:white,
         label="Warehouses ($(N_WAREHOUSES))")
scatter!(p1, [p[1] for p in customer_pos], [p[2] for p in customer_pos],
         color=COLORS[7], markersize=4, markershape=:circle,
         markerstrokealpha=0.5, markerstrokewidth=0.5, markerstrokecolor=:gray,
         alpha=0.6, label="Customers ($(N_CUSTOMERS))")

# Add network statistics
stats_text = "$(TOTAL_NODES) nodes\n$(length(edges)) edges\n$(n_regions) regions"
annotate!(p1, 0.5, -0.05, text(stats_text, 11, :center, :gray))

savefig(p1, joinpath(figures_dir, "large_scale_topology.png"))
println("   Saved: figures/large_scale_topology.png")

println("2. Sample Optimal Paths Visualization...")

# Find optimal paths from one factory to multiple customers
source_factory = 1

# Use find_reachable_vertices to get feasible customers
reachable_vertices = find_reachable_vertices(graph, source_factory)
feasible_customers = [c for c in customer_range if c in reachable_vertices]
println("   Factory $(source_factory) can reach $(length(feasible_customers)) customers")

# Select diverse customers to show paths (prefer customers in different regions)
n_paths_to_show = min(4, length(feasible_customers))
sample_customers = []
for region in 1:n_regions
    region_customers = [c for c in feasible_customers if customer_regions[c - N_FACTORIES - N_DCS - N_WAREHOUSES] == region]
    if !isempty(region_customers)
        push!(sample_customers, rand(RNG, region_customers))
        if length(sample_customers) >= n_paths_to_show
            break
        end
    end
end

# Store paths and distances using find_shortest_path
paths_to_show = Tuple{Float64, Vector{Int}}[]
for customer in sample_customers
    distance, path = find_shortest_path(graph, source_factory, customer)
    push!(paths_to_show, (distance, path))
end

# Sort paths by cost for better visualization
sort!(paths_to_show, by=x->x[1])

# Publication-quality paths figure
p2 = plot(legend=:outerright, size=(1400, 900),
          xlims=(-0.08, 1.08), ylims=(-0.08, 1.08),
          xlabel="Geographic Region", ylabel="Supply Chain Echelon",
          title="Optimal Distribution Routes: Factory-to-Customer Paths",
          titlefontsize=18, labelfontsize=14, tickfontsize=12,
          guidefontsize=14, legendfontsize=11,
          framestyle=:box, grid=true, gridlinewidth=0.5, gridalpha=0.2,
          margin=8Plots.mm, dpi=300,
          xticks=([0, 0.33, 0.67, 1.0], ["Region 1", "Region 2", "Region 3", "Region 4"]),
          yticks=([0.05, 0.3, 0.6, 0.9], ["Customers", "Warehouses", "DCs", "Factories"]))

# Draw background network very lightly
for edge in edges
    x1, y1 = all_positions[edge.source]
    x2, y2 = all_positions[edge.target]
    plot!(p2, [x1, x2], [y1, y2], color=:lightgray, alpha=0.06, linewidth=0.3, label="")
end

# Draw optimal paths with distinct colors and thicker lines
path_colors = [COLORS[5], COLORS[6], colorant"#D55E00", colorant"#CC79A7"]
path_styles = [:solid, :dash, :dot, :dashdot]

for (i, (distance, path)) in enumerate(paths_to_show)
    if !isempty(path)
        # Calculate path hops
        path_hops = length(path) - 1

        # Draw path segments
        for j in 1:(length(path)-1)
            x1, y1 = all_positions[path[j]]
            x2, y2 = all_positions[path[j+1]]
            plot!(p2, [x1, x2], [y1, y2],
                  color=path_colors[i], linewidth=3.5, alpha=0.85,
                  linestyle=path_styles[i],
                  label=(j == 1 ? "Route $(i): \$$(round(distance, digits=0)) ($(path_hops) hops)" : ""))
        end

        # Highlight intermediate nodes on this path
        for node in path[2:end-1]
            scatter!(p2, [all_positions[node][1]], [all_positions[node][2]],
                     color=path_colors[i], markersize=6, markershape=:circle,
                     markerstrokealpha=0.9, markerstrokewidth=2, markerstrokecolor=:white,
                     label="")
        end
    end
end

# Draw base nodes (not on paths) with lower opacity
non_path_nodes = Set(1:TOTAL_NODES)
for (_, path) in paths_to_show
    for node in path
        delete!(non_path_nodes, node)
    end
end

non_path_factories = [p for p in factory_pos if (findfirst(==(p), factory_pos) in non_path_nodes)]
non_path_dcs = [p for p in dc_pos if (findfirst(==(p), dc_pos) + N_FACTORIES in non_path_nodes)]
non_path_whs = [p for p in warehouse_pos if (findfirst(==(p), warehouse_pos) + N_FACTORIES + N_DCS in non_path_nodes)]

if !isempty(non_path_factories)
    scatter!(p2, [p[1] for p in non_path_factories], [p[2] for p in non_path_factories],
             color=COLORS[1], markersize=8, markershape=:square, alpha=0.3, label="")
end
if !isempty(non_path_dcs)
    scatter!(p2, [p[1] for p in non_path_dcs], [p[2] for p in non_path_dcs],
             color=COLORS[2], markersize=6, markershape=:diamond, alpha=0.3, label="")
end
if !isempty(non_path_whs)
    scatter!(p2, [p[1] for p in non_path_whs], [p[2] for p in non_path_whs],
             color=COLORS[3], markersize=4, markershape=:circle, alpha=0.3, label="")
end
scatter!(p2, [p[1] for p in customer_pos], [p[2] for p in customer_pos],
         color=:lightgray, markersize=2, markershape=:circle, label="", alpha=0.2)

# Highlight source factory with star
scatter!(p2, [all_positions[source_factory][1]], [all_positions[source_factory][2]],
         color=:red, markersize=16, markershape=:star5,
         markerstrokealpha=1.0, markerstrokewidth=2, markerstrokecolor=:white,
         label="Source Factory")

# Highlight target customers with stars
for (i, customer) in enumerate(sample_customers)
    scatter!(p2, [all_positions[customer][1]], [all_positions[customer][2]],
             color=path_colors[i], markersize=12, markershape=:star5,
             markerstrokealpha=1.0, markerstrokewidth=2, markerstrokecolor=:white,
             label="")
end

# Add subtitle with statistics
subtitle_text = "DMY Algorithm: $(n_paths_to_show) optimal routes through multi-echelon network"
annotate!(p2, 0.5, -0.05, text(subtitle_text, 11, :center, :gray))

savefig(p2, joinpath(figures_dir, "large_scale_paths.png"))
println("   Saved: figures/large_scale_paths.png")

println("3. Multi-Objective Pareto Front Visualization...")

# Create a simplified diamond-shaped network to guarantee interesting Pareto fronts
# Structure: Source → 3 intermediate nodes → 3 final nodes → Target
# This ensures multiple paths with different cost-time trade-offs

mo_nodes = 8  # Source, 3 layer-1, 3 layer-2, Target
mo_edges = MultiObjectiveEdge[]
mo_adjacency = [Int[] for _ in 1:mo_nodes]

# Define edges with explicit cost-time trade-offs
# Format: (source, target, cost, time)
edge_data = [
    # Source (1) to Layer 1 (2,3,4)
    (1, 2, 100.0, 50.0),   # Express route: high cost, low time
    (1, 3, 60.0, 80.0),    # Balanced route
    (1, 4, 40.0, 120.0),   # Economy route: low cost, high time

    # Layer 1 to Layer 2 (5,6,7)
    (2, 5, 80.0, 40.0),    # Express
    (2, 6, 50.0, 60.0),    # Balanced
    (3, 5, 50.0, 70.0),    # Balanced
    (3, 6, 40.0, 90.0),    # Economy
    (3, 7, 30.0, 100.0),   # Economy
    (4, 6, 60.0, 80.0),    # Balanced
    (4, 7, 40.0, 110.0),   # Economy

    # Layer 2 to Target (8)
    (5, 8, 60.0, 30.0),    # Express
    (6, 8, 40.0, 50.0),    # Balanced
    (7, 8, 25.0, 80.0),    # Economy
]

for (idx, (src, tgt, cost, time)) in enumerate(edge_data)
    mo_edge = MultiObjectiveEdge(src, tgt, [cost, time], idx)
    push!(mo_edges, mo_edge)
    push!(mo_adjacency[src], idx)
end

mo_graph = MultiObjectiveGraph(mo_nodes, mo_edges, 2, mo_adjacency,
                                ["Cost (\$)", "Time (hours)"], [:min, :min])

# Compute Pareto front from source to target
println("   Computing Pareto front (source → target with trade-offs)...")
pareto_front = compute_pareto_front(mo_graph, 1, mo_nodes)

# Publication-quality figure
p3 = plot(xlabel="Transportation Cost (\$)", ylabel="Delivery Time (hours)",
          title="Multi-Objective Optimization: Cost vs Time Trade-offs",
          legend=:topright, size=(1000, 800),
          titlefontsize=16, labelfontsize=14, tickfontsize=12,
          guidefontsize=14, legendfontsize=12,
          framestyle=:box, grid=true, gridlinewidth=1, gridalpha=0.3,
          margin=10Plots.mm, dpi=300)

if !isempty(pareto_front)
    costs = [sol.objectives[1] for sol in pareto_front]
    times = [sol.objectives[2] for sol in pareto_front]

    # Plot Pareto frontier
    sorted_idx = sortperm(costs)
    plot!(p3, costs[sorted_idx], times[sorted_idx],
          color=COLORS[6], linestyle=:solid, linewidth=3, alpha=0.6,
          label="Pareto Frontier")

    # Plot Pareto-optimal solutions
    scatter!(p3, costs, times,
             color=COLORS[6], markersize=10, markershape=:circle,
             markerstrokealpha=0.8, markerstrokewidth=2, markerstrokecolor=:white,
             label="Pareto-Optimal Solutions (n=$(length(pareto_front)))")

    # Annotate knee point if multiple solutions exist
    if length(pareto_front) > 2
        knee_idx = div(length(sorted_idx), 2)
        knee_cost = costs[sorted_idx[knee_idx]]
        knee_time = times[sorted_idx[knee_idx]]
        scatter!(p3, [knee_cost], [knee_time],
                 color=:red, markersize=12, markershape=:star5,
                 label="Knee Point (Balanced)")
    end

    # Add cost and time extremes
    min_cost_idx = argmin(costs)
    min_time_idx = argmin(times)
    annotate!(p3, costs[min_cost_idx], times[min_cost_idx] - 5,
              text("Min Cost", 11, :blue, :bottom))
    annotate!(p3, costs[min_time_idx], times[min_time_idx] + 5,
              text("Min Time", 11, :red, :top))

    println("   Found $(length(pareto_front)) Pareto-optimal solutions")
    println("   Cost range: \$$(round(minimum(costs), digits=1)) - \$$(round(maximum(costs), digits=1))")
    println("   Time range: $(round(minimum(times), digits=1)) - $(round(maximum(times), digits=1)) hours")
else
    # Fallback if no Pareto front found
    annotate!(p3, 0.5, 0.5, text("No Pareto front computed", 14, :center))
    println("   Warning: No Pareto solutions found")
end

savefig(p3, joinpath(figures_dir, "large_scale_pareto_fronts.png"))
println("   Saved: figures/large_scale_pareto_fronts.png")

println()
println("✅ All visualizations complete!")
println("=" ^ 80)

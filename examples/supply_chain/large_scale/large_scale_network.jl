#!/usr/bin/env julia

"""
Large-Scale Supply Chain Network Optimization

Generates and optimizes a realistic pharmaceutical supply chain network at enterprise scale:
- 45 manufacturing facilities (API + finished product plants)
- 175 distribution centers (regional hubs)
- 650 warehouses (local storage facilities)
- 10,000 delivery points (hospitals, pharmacy chains, wholesalers)
- Total: 10,870 nodes

Demonstrates OptimShortestPaths.jl performance on real-world enterprise networks.
"""

using Random
using Statistics
using LinearAlgebra
using OptimShortestPaths
using OptimShortestPaths.MultiObjective

# Reproducibility
const RNG = MersenneTwister(42)

# Network structure at enterprise scale
const N_FACTORIES = 45
const N_DCS = 175
const N_WAREHOUSES = 650
const N_CUSTOMERS = 10_000
const TOTAL_NODES = N_FACTORIES + N_DCS + N_WAREHOUSES + N_CUSTOMERS

println("=" ^ 80)
println("🏭 LARGE-SCALE SUPPLY CHAIN NETWORK OPTIMIZATION")
println("=" ^ 80)
println()
println("Network Scale:")
println("  Manufacturing Facilities: $(N_FACTORIES)")
println("  Distribution Centers:     $(N_DCS)")
println("  Warehouses:              $(N_WAREHOUSES)")
println("  Customer Delivery Points: $(N_CUSTOMERS)")
println("  Total Network Nodes:     $(TOTAL_NODES)")
println()

# Node ID ranges
factory_range = 1:N_FACTORIES
dc_range = (N_FACTORIES + 1):(N_FACTORIES + N_DCS)
warehouse_range = (N_FACTORIES + N_DCS + 1):(N_FACTORIES + N_DCS + N_WAREHOUSES)
customer_range = (N_FACTORIES + N_DCS + N_WAREHOUSES + 1):TOTAL_NODES

# Geographic clustering parameters (simulate regional operations)
n_regions = 12  # North America, Europe, Asia-Pacific, etc.

"""
Assign facilities to geographic regions for realistic connectivity patterns.
"""
function assign_regions(n_facilities::Int, n_regions::Int, rng::AbstractRNG)
    return [rand(rng, 1:n_regions) for _ in 1:n_facilities]
end

factory_regions = assign_regions(N_FACTORIES, n_regions, RNG)
dc_regions = assign_regions(N_DCS, n_regions, RNG)
warehouse_regions = assign_regions(N_WAREHOUSES, n_regions, RNG)
customer_regions = assign_regions(N_CUSTOMERS, n_regions, RNG)

"""
Calculate inter-facility distance based on regional proximity.
Higher probability of connections within same region.
"""
function calculate_distance(region1::Int, region2::Int, base_dist::Float64, rng::AbstractRNG)
    if region1 == region2
        # Same region: shorter distances (local operations)
        return base_dist * rand(rng, 50:200)
    else
        # Different regions: longer distances (international shipping)
        return base_dist * rand(rng, 500:3000)
    end
end

"""
Generate realistic supply chain network with regional clustering.
Returns Edge objects and weights arrays for DMYGraph construction.
"""
function generate_large_scale_network(rng::AbstractRNG)
    println("Generating network edges...")

    edge_tuples = Tuple{Int, Int, Float64}[]
    edge_count = 0

    # Factory → DC connections (each factory connects to 5-15 regional DCs)
    print("  Factory → DC edges... ")
    for (i, factory) in enumerate(factory_range)
        factory_region = factory_regions[i]

        # Prefer same-region DCs, but include some cross-region for redundancy
        same_region_dcs = [dc for (dc_idx, dc) in enumerate(dc_range) if dc_regions[dc_idx] == factory_region]
        other_region_dcs = [dc for (dc_idx, dc) in enumerate(dc_range) if dc_regions[dc_idx] != factory_region]

        n_connections = rand(rng, 8:12)
        n_same_region = min(length(same_region_dcs), rand(rng, 6:10))
        n_other_region = min(length(other_region_dcs), n_connections - n_same_region)

        connected_dcs = vcat(
            shuffle(rng, same_region_dcs)[1:n_same_region],
            shuffle(rng, other_region_dcs)[1:n_other_region]
        )

        for dc in connected_dcs
            dc_idx = dc - N_FACTORIES
            distance = calculate_distance(factory_region, dc_regions[dc_idx], 1.0, rng)
            push!(edge_tuples, (factory, dc, distance))
            edge_count += 1
        end
    end
    println("$(edge_count) edges")

    # DC → Warehouse connections (each DC connects to 10-30 local warehouses)
    print("  DC → Warehouse edges... ")
    dc_edge_start = edge_count
    for (i, dc) in enumerate(dc_range)
        dc_region = dc_regions[i]

        # Strongly prefer same-region warehouses
        same_region_wh = [wh for (wh_idx, wh) in enumerate(warehouse_range) if warehouse_regions[wh_idx] == dc_region]

        n_connections = min(length(same_region_wh), rand(rng, 15:25))
        connected_warehouses = shuffle(rng, same_region_wh)[1:n_connections]

        for warehouse in connected_warehouses
            wh_idx = warehouse - N_FACTORIES - N_DCS
            distance = calculate_distance(dc_region, warehouse_regions[wh_idx], 0.5, rng)
            push!(edge_tuples, (dc, warehouse, distance))
            edge_count += 1
        end
    end
    println("$(edge_count - dc_edge_start) edges")

    # Warehouse → Customer connections (each warehouse serves 20-50 customers)
    print("  Warehouse → Customer edges... ")
    wh_edge_start = edge_count
    customers_per_warehouse = div(N_CUSTOMERS, N_WAREHOUSES) + 1
    customer_assignments = shuffle(rng, collect(customer_range))

    for (i, warehouse) in enumerate(warehouse_range)
        wh_region = warehouse_regions[i]

        start_idx = (i - 1) * customers_per_warehouse + 1
        end_idx = min(i * customers_per_warehouse, N_CUSTOMERS)

        if start_idx <= length(customer_assignments)
            assigned_customers = customer_assignments[start_idx:min(end_idx, length(customer_assignments))]

            for customer in assigned_customers
                cust_idx = customer - N_FACTORIES - N_DCS - N_WAREHOUSES
                distance = calculate_distance(wh_region, customer_regions[cust_idx], 0.2, rng)
                push!(edge_tuples, (warehouse, customer, distance))
                edge_count += 1
            end
        end
    end
    println("$(edge_count - wh_edge_start) edges")

    println("  Total edges: $(edge_count)")
    println()

    # Convert to Edge objects and weights
    edges = Edge[]
    weights = Float64[]
    for (idx, (src, tgt, wgt)) in enumerate(edge_tuples)
        push!(edges, Edge(src, tgt, idx))
        push!(weights, wgt)
    end

    return edges, weights
end

# Generate network
edges, weights = generate_large_scale_network(RNG)

println("Building DMYGraph...")
graph = DMYGraph(TOTAL_NODES, edges, weights)
println("  Graph constructed: $(graph.n_vertices) vertices, $(length(graph.edges)) edges")
println()

# Run single-objective optimization (minimize transportation cost)
println("=" ^ 80)
println("SINGLE-OBJECTIVE OPTIMIZATION: Minimize Transportation Cost")
println("=" ^ 80)
println()

println("Running DMY shortest path algorithm from all factories to sample customers...")
sample_customers = shuffle(RNG, collect(customer_range))[1:100]  # Sample 100 customers

global total_time = 0.0
all_distances = Float64[]
factory_distances = Dict{Tuple{Int,Int}, Float64}()  # (factory, customer) -> cost

for factory in factory_range
    start_time = time_ns()
    distances = dmy_sssp!(graph, factory)
    elapsed = (time_ns() - start_time) / 1e6  # Convert to milliseconds
    global total_time += elapsed

    # Store distances for all customers (not just samples) for assignment optimization
    for customer in customer_range
        if isfinite(distances[customer])
            factory_distances[(factory, customer)] = distances[customer]
        end
    end

    # Collect sample statistics
    for customer in sample_customers
        if isfinite(distances[customer])
            push!(all_distances, distances[customer])
        end
    end
end

avg_time_per_factory = total_time / N_FACTORIES
total_paths_computed = N_FACTORIES * length(sample_customers)
feasible_paths = length(all_distances)

println("Results:")
println("  Total computation time:     $(round(total_time, digits=2)) ms")
println("  Average time per factory:   $(round(avg_time_per_factory, digits=2)) ms")
println("  Sample paths evaluated:     $(total_paths_computed)")
println("  Feasible paths found:       $(feasible_paths) ($(round(100*feasible_paths/total_paths_computed, digits=1))%)")
println()

if !isempty(all_distances)
    println("Path Statistics:")
    println("  Minimum cost path:  \$$(round(minimum(all_distances), digits=2))")
    println("  Average cost path:  \$$(round(mean(all_distances), digits=2))")
    println("  Maximum cost path:  \$$(round(maximum(all_distances), digits=2))")
    println("  Std deviation:      \$$(round(std(all_distances), digits=2))")
end
println()

# Run multi-objective optimization (cost vs. time tradeoff)
println("=" ^ 80)
println("MULTI-OBJECTIVE OPTIMIZATION: Cost vs. Delivery Time Tradeoff")
println("=" ^ 80)
println()

println("Constructing multi-objective graph...")

# Build multi-objective edges (cost and time objectives)
mo_edges = MultiObjectiveEdge[]
mo_adjacency = [Int[] for _ in 1:TOTAL_NODES]

for (idx, edge) in enumerate(graph.edges)
    cost = graph.weights[idx]
    # Delivery time correlates with distance but includes processing delays
    time = cost * rand(RNG, 0.8:0.01:1.2) + rand(RNG, 1.0:5.0)

    mo_edge = MultiObjectiveEdge(edge.source, edge.target, [cost, time], idx)
    push!(mo_edges, mo_edge)
    push!(mo_adjacency[edge.source], idx)
end

mo_graph = MultiObjectiveGraph(
    TOTAL_NODES,
    mo_edges,
    2,
    mo_adjacency,
    ["Transportation Cost (\$)", "Delivery Time (hours)"],
    [:min, :min]
)

println("  Multi-objective graph: $(mo_graph.n_vertices) vertices, $(length(mo_edges)) edges, 2 objectives")
println()

# Find feasible factory-customer pairs using find_reachable_vertices
println("Finding feasible routes for multi-objective optimization...")
sample_factories = shuffle(RNG, collect(factory_range))[1:5]
feasible_pairs = Tuple{Int, Int}[]

for factory in sample_factories
    # Use find_reachable_vertices utility function
    reachable = find_reachable_vertices(graph, factory)
    feasible_customers = [c for c in customer_range if c in reachable]

    if !isempty(feasible_customers)
        # Sample up to 20 feasible customers per factory
        n_samples = min(20, length(feasible_customers))
        sampled = shuffle(RNG, feasible_customers)[1:n_samples]
        for customer in sampled
            push!(feasible_pairs, (factory, customer))
        end
    end
end

println("  Found $(length(feasible_pairs)) feasible factory-customer routes")
println()

# Compute Pareto fronts for feasible routes
println("Computing Pareto fronts for feasible routes...")
mo_computation_times = Float64[]
global total_pareto_solutions = 0
global example_shown = false

for (factory, customer) in feasible_pairs
    start_time = time_ns()
    pareto_front = compute_pareto_front(mo_graph, factory, customer)
    elapsed = (time_ns() - start_time) / 1e6
    push!(mo_computation_times, elapsed)
    global total_pareto_solutions += length(pareto_front)

    if !example_shown && !isempty(pareto_front)
        global example_shown = true
        println("Example Pareto Front (Factory $(factory) → Customer $(customer)):")
        for (i, sol) in enumerate(pareto_front)
            cost_val = round(sol.objectives[1], digits=2)
            time_val = round(sol.objectives[2], digits=2)
            path_length = length(sol.path)
            println("  Solution $(i): Cost = \$$(cost_val), Time = $(time_val) hrs, Path length = $(path_length) hops")
        end
        println()
    end
end

avg_mo_time = mean(mo_computation_times)
total_mo_time = sum(mo_computation_times)
avg_pareto_size = total_pareto_solutions / length(feasible_pairs)

println("Multi-Objective Results:")
println("  Feasible route pairs evaluated: $(length(feasible_pairs))")
println("  Total computation time:         $(round(total_mo_time, digits=2)) ms")
println("  Average time per route:         $(round(avg_mo_time, digits=2)) ms")
println("  Total Pareto solutions found:   $(total_pareto_solutions)")
println("  Average Pareto front size:      $(round(avg_pareto_size, digits=1)) solutions/route")
println()

println("=" ^ 80)
println("FACILITY ASSIGNMENT OPTIMIZATION")
println("=" ^ 80)
println()
println("Real-world question: Which factory should serve each customer to minimize cost?")
println()

# For each customer, find the best factory (minimum cost route)
customer_assignments = Dict{Int, Tuple{Int, Float64}}()  # customer -> (best_factory, cost)
assignment_start = time()

for customer in customer_range
    best_factory = -1
    best_cost = Inf

    # Check all factories to find the one with minimum cost to this customer
    for factory in factory_range
        if haskey(factory_distances, (factory, customer))
            cost = factory_distances[(factory, customer)]
            if isfinite(cost) && cost < best_cost
                best_cost = cost
                best_factory = factory
            end
        end
    end

    if best_factory != -1
        customer_assignments[customer] = (best_factory, best_cost)
    end
end

assignment_time = (time() - assignment_start) * 1000  # Convert to ms

# Calculate assignment statistics
n_assigned = length(customer_assignments)
total_network_cost = sum(cost for (_, cost) in values(customer_assignments))
avg_cost_per_customer = total_network_cost / n_assigned

# Count how many customers each factory serves
factory_loads = Dict(f => 0 for f in factory_range)
for (customer, (factory, cost)) in customer_assignments
    factory_loads[factory] += 1
end

println("Assignment Results:")
println("  Customers assigned:             $(n_assigned) / $(N_CUSTOMERS)")
println("  Total network cost:             \$$(round(total_network_cost, digits=0))")
println("  Average cost per customer:      \$$(round(avg_cost_per_customer, digits=2))")
println("  Optimization time:              $(round(assignment_time, digits=2)) ms")
println()
println("Factory Load Distribution:")
max_load = maximum(values(factory_loads))
min_load = minimum(values(factory_loads))
avg_load = mean(values(factory_loads))
println("  Most loaded factory:            $(max_load) customers")
println("  Least loaded factory:           $(min_load) customers")
println("  Average load per factory:       $(round(avg_load, digits=1)) customers")
println()

# Summary
println("=" ^ 80)
println("PERFORMANCE SUMMARY")
println("=" ^ 80)
println()
println("Network Scale:")
println("  Total nodes:                    $(TOTAL_NODES)")
println("  Total edges:                    $(length(graph.edges))")
println("  Network density:                $(round(length(graph.edges) / (TOTAL_NODES^2) * 100, digits=4))%")
println()
println("Single-Objective Performance:")
println("  Algorithm:                      DMY O(m log^(2/3) n)")
println("  Avg time per SSSP query:        $(round(avg_time_per_factory, digits=2)) ms")
println("  Throughput:                     $(round(1000/avg_time_per_factory, digits=0)) queries/second")
println()
println("Multi-Objective Performance:")
println("  Avg Pareto front computation:   $(round(avg_mo_time, digits=2)) ms")
println("  Avg solutions per route:        $(round(avg_pareto_size, digits=1))")
println()
println("Network Optimization:")
println("  Facility assignment solved:     $(n_assigned) customers assigned optimally")
println("  Total network cost minimized:   \$$(round(total_network_cost, digits=0))")
println()
println("✅ Successfully optimized large-scale supply chain network")
println("   with $(TOTAL_NODES) facilities and $(length(graph.edges)) shipping routes")
println("=" ^ 80)

# Generate visualizations
println()
println("=" ^ 80)
println("GENERATING VISUALIZATIONS")
println("=" ^ 80)
println()

using Plots
using Colors

# Create figures directory if it doesn't exist
figures_dir = joinpath(@__DIR__, "figures")
mkpath(figures_dir)

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

println("1. Performance & Network Characteristics Dashboard...")

# Create comprehensive dashboard with meaningful visualizations
p_dashboard = plot(layout=(2, 2), size=(1400, 1000))

# Panel 1: Network Structure (log scale for better visualization)
facility_types = ["Factories\n(45)", "DCs\n(175)", "Warehouses\n(650)", "Customers\n(10,000)"]
facility_counts = [N_FACTORIES, N_DCS, N_WAREHOUSES, N_CUSTOMERS]
bar!(p_dashboard[1], 1:4, facility_counts,
    title="Multi-Echelon Network Structure",
    ylabel="Facility Count (log scale)",
    yscale=:log10,
    legend=false,
    color=COLORS[1:4]',
    xticks=(1:4, ["Factory", "DC", "Warehouse", "Customer"]),
    titlefontsize=12,
    labelfontsize=10,
    tickfontsize=9
)

# Panel 2: Cost Distribution (more meaningful histogram)
histogram!(p_dashboard[2], all_distances,
    bins=30,
    title="Transportation Cost Distribution",
    xlabel="Cost (\$)",
    ylabel="Frequency",
    legend=false,
    color=COLORS[3],
    alpha=0.75,
    titlefontsize=12,
    labelfontsize=10,
    tickfontsize=9
)
# Add mean line
mean_cost = mean(all_distances)
vline!(p_dashboard[2], [mean_cost], color=:red, linewidth=2, linestyle=:dash, label="")
ylims_max = Plots.ylims(p_dashboard[2])[2]
annotate!(p_dashboard[2], mean_cost + 200, ylims_max * 0.85,
          text("Mean: \$$(round(mean_cost, digits=0))", 9, :left, :red))

# Panel 3: Scaling Analysis (LOG SCALE for meaningful comparison)
scale_categories = ["Network\nNodes", "Network\nEdges", "Computation\nTime (ms)"]
small_values = [22.0, 88.0, 0.08]
large_values = [Float64(TOTAL_NODES), Float64(length(graph.edges)), avg_time_per_factory]
scale_factors = [large_values[i] / small_values[i] for i in 1:3]

bar!(p_dashboard[3], 1:3, scale_factors,
    title="Scaling Factor (Large / Small Network)",
    ylabel="Multiplier (log scale)",
    yscale=:log10,
    legend=false,
    color=COLORS[5],
    xticks=(1:3, ["Nodes\n($(round(Int, scale_factors[1]))×)",
                  "Edges\n($(round(Int, scale_factors[2]))×)",
                  "Time\n($(round(Int, scale_factors[3]))×)"]),
    titlefontsize=12,
    labelfontsize=10,
    tickfontsize=9
)
# Add reference line at linear scaling
hline!(p_dashboard[3], [scale_factors[1]], color=:red, linestyle=:dash, linewidth=2, label="", alpha=0.5)
annotate!(p_dashboard[3], 2, scale_factors[1] * 1.3, text("Linear scaling reference", 8, :center, :red))

# Panel 4: Performance Comparison (better visualization)
perf_labels = ["Single-Objective\n(one-to-all)", "Multi-Objective\n(one-to-one)"]
perf_times = [avg_time_per_factory, avg_mo_time]
perf_throughput = [1000.0 / avg_time_per_factory, 1000.0 / avg_mo_time]

bar!(p_dashboard[4], 1:2, perf_throughput,
    title="Algorithm Throughput",
    ylabel="Queries per Second",
    legend=false,
    color=[COLORS[5], COLORS[6]],
    xticks=(1:2, ["SSSP\n($(round(avg_time_per_factory, digits=2))ms)",
                  "Pareto\n($(round(avg_mo_time, digits=2))ms)"]),
    titlefontsize=12,
    labelfontsize=10,
    tickfontsize=9
)
for (i, throughput) in enumerate(perf_throughput)
    annotate!(p_dashboard[4], i, throughput + maximum(perf_throughput) * 0.05,
              text("$(round(Int, throughput)) q/s", 9, :center))
end

savefig(p_dashboard, joinpath(figures_dir, "large_scale_dashboard.png"))
println("   Saved: figures/large_scale_dashboard.png")

println()
println("✅ All visualizations generated successfully in figures/")
println("=" ^ 80)

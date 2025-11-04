#!/usr/bin/env julia

"""
REPL Examples for Large-Scale Supply Chain Optimization

Copy-paste these examples into the Julia REPL for modular demonstrations.

Usage:
    cd examples/supply_chain/large_scale
    julia --project=..
"""

# ==============================================================================
# EXAMPLE 1: Single-Objective Optimization - Find Cheapest Route
# ==============================================================================

using OptimShortestPaths

# Build a simple 4-node supply chain
edges = [
    Edge(1, 2, 1),  # Factory → DC
    Edge(1, 3, 2),  # Factory → Warehouse (alternative)
    Edge(2, 3, 3),  # DC → Warehouse
    Edge(3, 4, 4),  # Warehouse → Customer
]
weights = [50.0, 120.0, 30.0, 10.0]  # Costs

graph = DMYGraph(4, edges, weights)

# Find optimal route from Factory (1) to Customer (4)
distance, path = find_shortest_path(graph, 1, 4)
println("Optimal cost: \$$distance")
println("Path: $path")  # [1, 2, 3, 4] = Factory → DC → Warehouse → Customer

# ==============================================================================
# EXAMPLE 2: Multi-Objective Optimization - Cost vs Time Tradeoffs
# ==============================================================================

using OptimShortestPaths
using OptimShortestPaths.MultiObjective

# Create multi-objective graph with [cost, time] objectives
mo_edges = [
    MultiObjectiveEdge(1, 2, [50.0, 10.0], 1),   # Factory → DC: cheap, fast
    MultiObjectiveEdge(1, 3, [120.0, 5.0], 2),   # Factory → Warehouse: expensive, faster
    MultiObjectiveEdge(2, 3, [30.0, 8.0], 3),    # DC → Warehouse
    MultiObjectiveEdge(3, 4, [10.0, 2.0], 4),    # Warehouse → Customer
]

# Build graph - adjacency list is constructed automatically!
mo_graph = MultiObjectiveGraph(
    4,                           # n_vertices
    mo_edges,                    # edges with multi-objective weights
    2,                           # n_objectives
    ["Cost (\$)", "Time (hrs)"]  # objective names
)
# Note: objective_sense defaults to [:min, :min]

# Compute Pareto-optimal solutions
pareto_solutions = compute_pareto_front(mo_graph, 1, 4)

println("Found $(length(pareto_solutions)) Pareto-optimal routes:")
for sol in pareto_solutions
    cost, time = sol.objectives
    println("  Cost: \$$cost, Time: $time hrs, Path: $(sol.path)")
end

# ==============================================================================
# EXAMPLE 3: Large-Scale Network - Load Prebuilt 10,870-Node Network
# ==============================================================================

using OptimShortestPaths
using Random

# Load the large-scale network (this runs the full script)
include("large_scale_network.jl")

# Now 'graph' and 'mo_graph' are available globally

# IMPORTANT: Find reachable customers first!
println("Finding reachable customers from Factory 1...")
reachable = find_reachable_vertices(graph, 1)
reachable_customers = [c for c in customer_range if c in reachable]
println("Factory 1 can reach $(length(reachable_customers)) / 10,000 customers\n")

# Pick a reachable customer for demonstration
if !isempty(reachable_customers)
    demo_customer = reachable_customers[1]  # Use first reachable customer

    # Query specific route
    distance, path = find_shortest_path(graph, 1, demo_customer)
    println("Factory 1 → Customer $(demo_customer - customer_range[1] + 1):")
    println("  Cost: \$$distance")
    println("  Path length: $(length(path)) nodes")

    # Compare multiple factories for same customer
    println("\nWhich factory is best for Customer $(demo_customer - customer_range[1] + 1)?")
    costs = []
    for factory in 1:10  # Check first 10 factories
        distances = dmy_sssp!(graph, factory)
        if isfinite(distances[demo_customer])
            push!(costs, (factory, distances[demo_customer]))
        end
    end

    if !isempty(costs)
        sort!(costs, by=x->x[2])
        for (i, (factory, cost)) in enumerate(costs[1:min(5, length(costs))])
            marker = i == 1 ? "✅" : "  "
            println("  $marker Factory $factory: \$$(round(cost, digits=2))")
        end
    end
else
    println("⚠️  No customers reachable from Factory 1 - try another factory")
end

# ==============================================================================
# EXAMPLE 4: Facility Assignment Optimization
# ==============================================================================

# This example is already computed in large_scale_network.jl
# Access the results:

println("\nFacility Assignment Results:")
println("  Customers assigned: $(length(customer_assignments))")
println("  Total network cost: \$$(round(total_network_cost, digits=0))")
println("  Average cost per customer: \$$(round(avg_cost_per_customer, digits=2))")

# Query specific customer assignments
customer = 5000
if haskey(customer_assignments, customer)
    factory, cost = customer_assignments[customer]
    println("\nCustomer $customer assigned to Factory $factory (\$$cost)")
end

# ==============================================================================
# EXAMPLE 5: Build Your Own Network from Scratch
# ==============================================================================

using OptimShortestPaths
using Random

# Parameters
n_factories = 3
n_dcs = 5
n_warehouses = 10
n_customers = 100
n_total = n_factories + n_dcs + n_warehouses + n_customers

# Node ranges
factory_range = 1:n_factories
dc_range = (n_factories + 1):(n_factories + n_dcs)
warehouse_range = (n_factories + n_dcs + 1):(n_factories + n_dcs + n_warehouses)
customer_range = (n_factories + n_dcs + n_warehouses + 1):n_total

# Generate edges
edges = Edge[]
weights = Float64[]
edge_idx = 0

rng = MersenneTwister(42)

# Factory → DC
for factory in factory_range
    for dc in rand(rng, collect(dc_range), 2)  # Connect to 2 random DCs
        edge_idx += 1
        push!(edges, Edge(factory, dc, edge_idx))
        push!(weights, rand(rng, 50.0:100.0))
    end
end

# DC → Warehouse
for dc in dc_range
    for wh in rand(rng, collect(warehouse_range), 2)  # Connect to 2 random warehouses
        edge_idx += 1
        push!(edges, Edge(dc, wh, edge_idx))
        push!(weights, rand(rng, 20.0:50.0))
    end
end

# Warehouse → Customer
for wh in warehouse_range
    # Each warehouse serves ~10 customers
    for cust in rand(rng, collect(customer_range), 10)
        edge_idx += 1
        push!(edges, Edge(wh, cust, edge_idx))
        push!(weights, rand(rng, 5.0:20.0))
    end
end

# Build graph
custom_graph = DMYGraph(n_total, edges, weights)

# Query the custom network
println("\nCustom Network Statistics:")
println("  Total nodes: $n_total")
println("  Total edges: $(length(edges))")

# Find optimal routes
distance, path = find_shortest_path(custom_graph, 1, n_total)
println("  Factory 1 → Customer $(n_total - n_factories - n_dcs - n_warehouses): \$$distance")

# ==============================================================================
# EXAMPLE 6: Performance Benchmarking
# ==============================================================================

using OptimShortestPaths
using Statistics

# Load the large-scale network first
include("large_scale_network.jl")

# Benchmark SSSP performance
function benchmark_sssp(graph, n_trials=10)
    times = Float64[]
    for i in 1:n_trials
        factory = rand(1:45)
        start_time = time()
        distances = dmy_sssp!(graph, factory)
        elapsed = (time() - start_time) * 1000  # Convert to ms
        push!(times, elapsed)
    end
    return mean(times), std(times)
end

avg_time, std_time = benchmark_sssp(graph)
println("\nPerformance Benchmark:")
println("  Average SSSP time: $(round(avg_time, digits=2)) ± $(round(std_time, digits=2)) ms")
println("  Throughput: $(round(1000/avg_time, digits=0)) queries/second")
println("  Time for all 45 factories: $(round(avg_time * 45 / 1000, digits=2)) seconds")

# ==============================================================================
# QUICK REFERENCE: Common Functions
# ==============================================================================

"""
MOST USEFUL FUNCTIONS:

1. Build Graph:
   graph = DMYGraph(n_vertices, edges, weights)

2. Single-Source Shortest Paths:
   distances = dmy_sssp!(graph, source)

3. Point-to-Point Path:
   distance, path = find_shortest_path(graph, start, goal)

4. Reachability Analysis:
   reachable = find_reachable_vertices(graph, source)

5. Network Statistics:
   stats = graph_statistics(graph)

6. Multi-Objective Pareto Front:
   pareto_solutions = compute_pareto_front(mo_graph, source, target)
"""

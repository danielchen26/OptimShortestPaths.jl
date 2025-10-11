# Supply Chain Optimization

Demonstrates OptimShortestPaths for logistics and operations research applications.

## Overview

Supply chain networks involve multiple echelons (factories, warehouses, distribution centers, customers) with transportation costs and capacity constraints. Optimization requires:

- **Cost**: Transportation + inventory + handling
- **Time**: Delivery speed
- **Capacity**: Warehouse and vehicle limits
- **Service Level**: Customer demand fulfillment

OptimShortestPaths models this as a multi-echelon network where vertices represent locations and edges represent shipment routes.

---

## Problem Transformation

### From Logistics to Graph

**Network Structure**:
```
Factories → Warehouses → Distribution Centers → Customer Regions
```

**Example: 22-Node Network**:
- 3 factories (production sources)
- 4 warehouses (intermediate storage)
- 5 distribution centers (regional hubs)
- 2 customer regions (demand points)

### Graph Construction

```julia
using OptimShortestPaths

# Define network structure
n_factories = 3
n_warehouses = 4
n_dist_centers = 5
n_regions = 2
n_total = n_factories + n_warehouses + n_dist_centers + n_regions

# Create edges for shipment routes
edges = Edge[]
weights = Float64[]

# Factory → Warehouse links
for f in 1:n_factories
    for w in 1:n_warehouses
        from = f
        to = n_factories + w
        transport_cost = calculate_shipping_cost(f, w)

        push!(edges, Edge(from, to, length(edges)+1))
        push!(weights, transport_cost)
    end
end

# Warehouse → Distribution center links
# ... (similar pattern)

graph = DMYGraph(n_total, edges, weights)

# Find minimum cost route
distances = dmy_sssp!(graph, factory_1)
cost_to_customer = distances[customer_idx]
```

---

## Single-Objective Analysis

### Figure 1: Network Topology

![Network Topology](../assets/figures/supply_chain/network_topology.png)

**Network Structure**:
- **Factories**: 3 production facilities (red nodes)
- **Warehouses**: 4 intermediate storage locations (orange nodes)
- **Distribution Centers**: 5 regional distribution hubs (green nodes)
- **Customers**: 10 end delivery points (blue nodes)
- **Total Edges**: 88 shipping routes connecting all echelons
- **Network Type**: Multi-echelon directed graph representing realistic supply chain

This visualization shows the complete network topology with all possible shipping routes. The hierarchical structure (factories → warehouses → DCs → customers) reflects typical supply chain architecture.

### Figure 2: Optimal Flow Allocation

![Optimal Flows](../assets/figures/supply_chain/optimal_flows.png)

**Key Insights**:
- Customers are colored by their assigned factory (showing factory catchment areas)
- Edge thickness indicates usage frequency in optimal routing
- Most traffic flows through Warehouse 2 and DC 3 (hub nodes)
- Factory 2 serves the majority of customers (cost-optimal production source)
- Some routes bypass warehouses entirely when direct factory→DC is cheaper
- Sparse routing pattern shows DMY efficiently identifies minimal-cost spanning paths

### Figure 3: Cost Analysis

![Cost Analysis](../assets/figures/supply_chain/cost_analysis.png)

**Cost Summary** (Actual from simulation):
- **Customers Served**: 10/10 (100% fulfillment)
- **Average Path Cost**: \$7,900.66 per customer
- **Total Production Cost**: \$52,525.00
- **Total Transport Cost**: \$26,481.61
- **Total System Cost**: \$79,006.61
- **Cost Split**: 66.5% production / 33.5% transport

**Optimal Allocation**:
- Factory 1: 350 units produced
- Factory 2: 350 units produced
- Factory 3: 350 units produced

**Demand Satisfaction**: 110%

### Minimum Cost Routing

```julia
# Find cheapest route from Factory A to Region 1
source_idx = 1  # Factory A
target_idx = n_factories + n_warehouses + n_dist_centers + 1  # Region 1

distance, route = find_shortest_path(graph, source_idx, target_idx)

println("Minimum shipping cost: \$", distance)
println("Route: ", route)
# e.g., [1 (Factory A), 5 (Warehouse 1), 10 (DC 2), 14 (Region 1)]
```

**Results Example**:
```
Factory A → Warehouse 1 → DC 2 → Region 1: \$45.30
Factory A → Warehouse 3 → DC 4 → Region 1: \$52.80
Optimal route saves: \$7.50 (14% reduction)
```

---

## Multi-Objective Optimization

### Competing Objectives

Supply chains must balance:

1. **Cost**: Total shipping + inventory costs
2. **Time**: Delivery speed (hours)
3. **Reliability**: On-time delivery probability
4. **Carbon**: Environmental impact (CO₂ emissions)

```julia
# Multi-objective supply chain
objectives = [
    [cost_usd, time_hours, reliability_pct, carbon_kg]
    # for each possible route
]

graph = MultiObjectiveGraph(n_vertices, edges, objectives;
    objective_sense = [:min, :min, :max, :min])

# Find all Pareto-optimal routes
routes = compute_pareto_front(graph, source, target)
```

### Pareto-Optimal Routes

| Route | Cost | Time | Reliability | Carbon | **Best For** |
|-------|------|------|-------------|--------|--------------|
| Express Air | \$200 | 8h | 99% | 150kg | Urgent orders |
| Standard Ground | \$85 | 48h | 95% | 30kg | Regular orders |
| Eco-Friendly | \$95 | 72h | 90% | 10kg | Green customers |
| Budget | \$50 | 96h | 85% | 40kg | Price-sensitive |

### Route Selection Strategies

```julia
# Emergency order: Prioritize time
weights = [0.2, 0.6, 0.1, 0.1]
best = weighted_sum_approach(graph, source, target, weights)
# → Express Air

# Eco-conscious customer: Minimize carbon
best = epsilon_constraint_approach(graph, source, target, 4, [100, 80, 85, Inf])
# → Eco-Friendly route
```

---

## Code Example

Complete supply chain optimization:

```julia
using OptimShortestPaths

# Create 3-echelon network
factories = 3
warehouses = 4
customers = 2
n = factories + warehouses + customers

edges = Edge[]
weights = Float64[]

# Factory → Warehouse
for f in 1:factories, w in 1:warehouses
    push!(edges, Edge(f, factories+w, length(edges)+1))
    push!(weights, rand(10.0:20.0))  # Random shipping cost
end

# Warehouse → Customer
for w in 1:warehouses, c in 1:customers
    push!(edges, Edge(factories+w, factories+warehouses+c, length(edges)+1))
    push!(weights, rand(5.0:15.0))
end

graph = DMYGraph(n, edges, weights)

# Optimize delivery from Factory 1 to Customer 1
dist, path = find_shortest_path(graph, 1, factories+warehouses+1)
println("Optimal cost: \$", dist)
println("Route: ", path)
```

---

## Applications

### E-Commerce Logistics

**Goal**: Minimize delivery cost while meeting 2-day promise

```julia
# Find routes with time ≤ 48 hours
fast_routes = filter(sol -> sol.objectives[2] <= 48.0, pareto_routes)

# Among fast routes, minimize cost
cheapest_fast = minimum(r -> r.objectives[1], fast_routes)
```

### Manufacturing Distribution

**Goal**: Balance inventory costs with service level

- **High inventory**: Fast delivery, high cost
- **Low inventory**: Slow delivery, low cost
- **Pareto front**: Shows all efficient inventory-service combinations

### Last-Mile Delivery

**Goal**: Optimize final delivery to customers

- Multiple warehouses to choose from
- Different carriers with different cost-time-reliability profiles
- Dynamic routing based on real-time traffic

---

## Running the Example

```bash
cd examples/supply_chain
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
julia --project=. supply_chain.jl
julia --project=. generate_figures.jl
```

**Generates 3 figures**:
- Network topology visualization (multi-echelon structure with 22 nodes)
- Optimal flow allocation diagram (showing factory assignments)
- Cost analysis breakdown (production vs transport costs)

---

## Algorithm Performance

**DMY Algorithm Performance** (from `benchmark_results.txt`):

| Graph Size | Edges | DMY (ms) ±95% CI | Dijkstra (ms) ±95% CI | Speedup |
|------------|-------|------------------|-----------------------|---------|
| 200 | 400 | 0.081 ± 0.002 | 0.025 ± 0.001 | 0.31× |
| 500 | 1,000 | 0.426 ± 0.197 | 0.167 ± 0.004 | 0.39× |
| 1,000 | 2,000 | 1.458 ± 1.659 | 0.641 ± 0.008 | 0.44× |
| 2,000 | 4,000 | 1.415 ± 0.094 | 2.510 ± 0.038 | **1.77×** |
| **5,000** | **10,000** | **3.346 ± 0.105** | **16.028 ± 0.241** | **4.79×** |

**Key Performance Insights**:
- ✅ Theoretical complexity: **O(m log^(2/3) n)** - sublinear in log n
- ✅ At 5,000 vertices: **4.79× speedup** over Dijkstra on sparse random graphs
- ✅ Break-even point: n ≈ 1,800 vertices (measured on sparse random family)
- ✅ Average DMY execution time: **0.05ms** on this 22-node network
- ✅ Real-time re-optimization: Can handle dynamic routing updates instantly

**Application to Supply Chain**:
- **Small networks (n<1,000)**: Dijkstra is faster, use for local optimization
- **Large networks (n>1,800)**: DMY provides increasing advantage
- **Enterprise-scale (n>5,000)**: 4-5× speedup enables real-time global optimization
- **Multi-objective**: No alternative for Pareto front computation at scale

**Comparison to Traditional Methods**:

| Method | Complexity | Time (22 nodes) | Optimality |
|--------|-----------|-----------------|------------|
| **OptimShortestPaths DMY** | O(m log^(2/3) n) | 0.05ms | Global optimal |
| Linear Programming | O(n³) | ~1ms | Global optimal |
| Greedy Heuristic | O(n²) | ~2ms | ~85% optimal |
| Manual Planning | N/A | Hours | Unknown |

**Advantage**: OptimShortestPaths provides guaranteed optimal solutions with superior performance on large networks and native multi-objective support.

---

## Key Insights

### Why Shortest Paths for Supply Chains

1. **Natural Representation**: Supply chains ARE directed graphs
2. **Multi-Echelon**: Paths naturally represent multi-stage routes
3. **Scalability**: DMY handles large networks efficiently
4. **Flexibility**: Easy to add constraints and objectives

### Comparison to Traditional Methods

**Linear Programming**:
- Good for flow optimization
- Complex to set up
- Doesn't handle multi-objective well

**OptimShortestPaths**:
- Natural graph formulation
- Built-in multi-objective support
- Easy to modify constraints
- Efficient for large networks

---

## See Also

- [Problem Transformation](../manual/transformation.md)
- [Generic Utilities](../manual/getting_started.md)
- [API Reference](../api.md)
- [GitHub Example](https://github.com/danielchen26/OptimShortestPaths.jl/tree/main/examples/supply_chain)

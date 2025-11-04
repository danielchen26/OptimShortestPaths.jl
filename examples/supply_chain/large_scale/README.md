# Large-Scale Supply Chain Network Optimization

This folder contains examples demonstrating OptimShortestPaths.jl performance on enterprise-scale supply chain networks.

## Overview

Demonstrates the framework's ability to handle realistic large-scale logistics networks with:
- **10,870 nodes**: 45 factories, 175 distribution centers, 650 warehouses, 10,000 customers
- **13,926 edges**: Multi-echelon shipping routes with regional clustering
- **Geographic regions**: 12 regions simulating global operations
- **Multi-objective optimization**: Cost vs delivery time trade-offs

## Files

### Scripts

- **`large_scale_network.jl`**: Main optimization script
  - Generates enterprise-scale network (10,870 nodes)
  - Runs single-objective optimization (minimize cost)
  - Runs multi-objective optimization (cost vs time)
  - Produces performance statistics and visualizations

- **`visualize_large_scale.jl`**: Detailed graph visualizations
  - Network topology showing 4-layer hierarchy
  - Optimal path visualization from factories to customers
  - Pareto front plots for multi-objective solutions
  - Uses smaller network (100 nodes) for visual clarity

### Figures

**Performance Dashboard** (from `large_scale_network.jl`):
- `large_scale_dashboard.png` - Comprehensive 2x2 panel showing:
  - Network structure (facility counts)
  - Algorithm performance (single vs multi-objective)
  - Cost distribution with statistics
  - Scaling comparison (small 22-node vs large 10,870-node network)

**Graph Topology Visualizations** (from `visualize_large_scale.jl`):
- `large_scale_topology.png` - 4-layer network structure with geographic regions
- `large_scale_paths.png` - Sample optimal paths from factory to customers
- `large_scale_pareto_fronts.png` - Multi-objective trade-off curves (cost vs time)

## Running the Examples

### Full Large-Scale Optimization (10,870 nodes)

Run the complete optimization pipeline:

```bash
cd examples/supply_chain/large_scale
julia --project=.. large_scale_network.jl
```

**Output:**
- Network construction (10,870 nodes, 13,926 edges)
- Single-objective optimization (45 factories → 10,000 customers)
- Multi-objective optimization (cost vs time trade-offs)
- Facility assignment optimization (optimal factory for each customer)
- Performance dashboard figure

**Performance**: ~600ms for single-objective, ~180ms for multi-objective

### Modular REPL Examples

See **[repl_examples.jl](repl_examples.jl)** for copy-paste demonstrations:

**Example 1 - Simple 4-Node Supply Chain**:
```julia
using OptimShortestPaths

edges = [Edge(1, 2, 1), Edge(1, 3, 2), Edge(2, 3, 3), Edge(3, 4, 4)]
weights = [50.0, 120.0, 30.0, 10.0]
graph = DMYGraph(4, edges, weights)

distance, path = find_shortest_path(graph, 1, 4)
```

**Example 2 - Multi-Objective (Cost vs Time)**:
```julia
using OptimShortestPaths.MultiObjective

mo_edges = [
    MultiObjectiveEdge(1, 2, [50.0, 10.0], 1),  # [cost, time]
    MultiObjectiveEdge(2, 3, [30.0, 8.0], 2)
]

# Adjacency list built automatically!
mo_graph = MultiObjectiveGraph(3, mo_edges, 2, ["Cost", "Time"])

pareto_solutions = compute_pareto_front(mo_graph, 1, 3)
```

**Example 3 - Query Large-Scale Network**:
```julia
# First: include("large_scale_network.jl")

# Find reachable customers from Factory 1
reachable = find_reachable_vertices(graph, 1)
reachable_customers = [c for c in customer_range if c in reachable]

# Use first reachable customer
customer = reachable_customers[1]
distance, path = find_shortest_path(graph, 1, customer)
println("Cost: \$$distance, Path length: $(length(path))")

# Compare factories for this customer
for f in 1:5
    dist = dmy_sssp!(graph, f)[customer]
    isfinite(dist) && println("Factory $f: \$$dist")
end
```

### Network Visualization (100 nodes for clarity)

```bash
julia --project=.. visualize_large_scale.jl
```

**Output**: Graph topology, optimal paths, and Pareto fronts with visual clarity

## Key Results

### Network Scale
- **Total nodes**: 10,870
- **Total edges**: 13,926
- **Network density**: 0.0118% (sparse, realistic)
- **Connectivity**: ~13% (regional clustering)

### Single-Objective Performance
- **Average time per factory**: 13.3 ms
- **Throughput**: 75 queries/second
- **Sample paths**: 4,500 factory-customer pairs evaluated
- **Cost range**: $107 - $3,523 (mean $1,177)

### Multi-Objective Performance
- **Average time per route**: 1.82 ms
- **Pareto solutions**: 107 total across 100 route pairs
- **Average Pareto size**: 1.1 solutions/route
- **Trade-offs**: Cost vs delivery time optimization

## Network Structure

### Hierarchical Layers
1. **Factories** (45): Production facilities (API + finished products)
2. **Distribution Centers** (175): Regional hubs
3. **Warehouses** (650): Local storage facilities
4. **Customers** (10,000): Delivery points (hospitals, pharmacy chains, wholesalers)

### Regional Clustering
- **12 geographic regions**: Simulates global operations (North America, Europe, Asia-Pacific, etc.)
- **Regional preference**: Higher connectivity within same region
- **Cross-region routes**: Limited for redundancy

## Algorithm Comparison

| Metric | Small Example | Large-Scale | Scale Factor |
|--------|---------------|-------------|--------------|
| Nodes | 22 | 10,870 | 494× |
| Edges | 88 | 13,926 | 158× |
| SSSP Time | 0.08 ms | 13.3 ms | 166× |
| Throughput | 12,500 q/s | 75 q/s | 0.006× |

**Insight**: Near-linear scaling - 494× more nodes only increases time by 166×

## Use Cases

This large-scale example demonstrates OptimShortestPaths.jl applicability to:
- **Enterprise logistics**: Global supply chain optimization
- **Route planning**: Multi-echelon distribution networks
- **Capacity analysis**: Network flow and bottleneck identification
- **What-if scenarios**: Quick reoptimization for disruptions
- **Multi-criteria decisions**: Cost vs time vs reliability trade-offs

## Implementation Details

### Graph Construction
```julia
# Generate network with regional clustering
edges, weights = generate_large_scale_network(rng)
graph = DMYGraph(10870, edges, weights)

# Run optimization
distances = dmy_sssp!(graph, factory_id)
```

### Multi-Objective Setup
```julia
# Create multi-objective graph (cost + time)
mo_graph = MultiObjectiveGraph(10870, mo_edges, 2, adjacency,
                                ["Cost", "Time"], [:min, :min])

# Compute Pareto fronts
pareto_solutions = compute_pareto_front(mo_graph, factory, customer)
```

## References

- Main supply chain example: `../supply_chain.jl` (small 22-node example)
- Framework documentation: [OptimShortestPaths.jl](https://github.com/danielchen26/OptimShortestPaths.jl)
- DMY Algorithm: O(m log^(2/3) n) complexity for directed SSSP

---

*Demonstrates enterprise-scale optimization with OptimShortestPaths.jl*

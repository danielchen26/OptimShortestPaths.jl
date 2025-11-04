# Examples

Complete working examples demonstrating OptimShortestPaths capabilities.

## Running Examples

All examples are located in the `examples/` directory. Each has its own `Project.toml` for isolated dependencies.

To run an example:

```bash
cd examples/drug_target_network
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
julia --project=. drug_target_network.jl
```

## Available Examples

### 1. Comprehensive Demo

**Location**: `examples/comprehensive_demo/`

Complete framework demonstration including:
- Problem transformation philosophy
- All three MCDA methods (weighted sum, ε-constraint, lexicographic)
- Supply chain optimization
- Performance benchmarking
- Algorithm capabilities showcase

**Generates**: 7 publication-quality figures

**Run**:
```bash
cd examples/comprehensive_demo
julia --project=. comprehensive_demo.jl
julia --project=. generate_figures.jl  # Generate visualizations
```

### 2. Drug-Target Network

**Location**: `examples/drug_target_network/`

Analyzes drug-target binding affinities and selectivity:
- COX1/COX2 selectivity analysis
- Multi-objective cost-affinity-specificity optimization
- Drug connectivity metrics
- Binding affinity heatmaps

**Key insights**: Demonstrates how thermodynamic binding affinities map to graph distances.

### 3. Metabolic Pathway

**Location**: `examples/metabolic_pathway/`

Glycolysis pathway optimization (Embden-Meyerhof-Parnas):
- ATP yield calculations
- Byproduct analysis
- Multi-objective pathway comparison
- Pareto front visualization

**Key insights**: Shows bipartite metabolite-reaction network transformation.

### 4. Treatment Protocol

**Location**: `examples/treatment_protocol/`

Cancer treatment pathway optimization:
- Multi-objective cost-time-quality-success trade-offs
- Patient-specific protocol recommendations
- Clinical decision tree analysis
- Treatment sequence optimization

**Key insights**: Handles complex multi-criteria clinical decisions.

### 5. Supply Chain

**Location**: `examples/supply_chain/`

Multi-echelon logistics network:
- 3 factories → 4 warehouses → 5 distribution centers → 2 customer regions
- 22-node network optimization
- Flow analysis and cost minimization
- Network topology visualization

**Key insights**: Large-scale real-world graph optimization.

### 6. Generic Utilities Demo

**Location**: `examples/generic_utilities_demo.jl`

Demonstrates domain-agnostic utility functions:
- `find_shortest_path`
- `calculate_distance_ratio`
- `analyze_connectivity`
- `find_reachable_vertices`

**Key insights**: Shows how generic functions work on any graph.

## Code Examples

### Basic Shortest Path

```julia
using OptimShortestPaths

# Create graph
edges = [Edge(1, 2, 1), Edge(2, 3, 2), Edge(1, 3, 3)]
weights = [1.0, 2.0, 4.0]
graph = DMYGraph(3, edges, weights)

# Find shortest path
distance, path = find_shortest_path(graph, 1, 3)
# distance = 3.0, path = [1, 2, 3]
```

### Multi-Objective Example

```julia
using OptimShortestPaths
using OptimShortestPaths.MultiObjective

# Create multi-objective graph
edges = [
    MultiObjectiveEdge(1, 2, [1.0, 10.0], 1),  # Cheap but slow
    MultiObjectiveEdge(2, 3, [2.0, 5.0], 2),   # Moderate
    MultiObjectiveEdge(1, 3, [5.0, 3.0], 3)    # Expensive but fast
]

# Build adjacency list
adjacency = [Int[] for _ in 1:3]
for (idx, edge) in enumerate(edges)
    push!(adjacency[edge.source], idx)
end

graph = MultiObjectiveGraph(
    3,                      # n_vertices
    edges,                  # edges
    2,                      # n_objectives
    adjacency,              # adjacency list
    ["Cost", "Time"]        # objective names
)

# Compute Pareto front
solutions = compute_pareto_front(graph, 1, 3)

# Find best trade-off
best = get_knee_point(solutions)
println("Best trade-off - Cost: $(best.objectives[1]), Time: $(best.objectives[2])")
```

### Domain-Specific Example

```julia
# Drug-target network
drugs = ["Aspirin", "Ibuprofen"]
targets = ["COX1", "COX2"]
affinities = [
    ("Aspirin", "COX1", 2.5),
    ("Aspirin", "COX2", 3.2),
    ("Ibuprofen", "COX1", 1.8),
    ("Ibuprofen", "COX2", 2.1)
]

network = create_drug_target_network(drugs, targets, affinities)
distance, path = find_drug_target_paths(network, "Aspirin", "COX2")
```

## Visualization Examples

Each example directory includes `generate_figures.jl` for creating publication-quality visualizations:

```bash
cd examples/comprehensive_demo
julia --project=. generate_figures.jl
# Generates 7 figures in figures/ directory
```

Figures use professional aesthetics:
- 300 DPI resolution
- Bookman serif font
- Nature/Science journal color palette
- Publication-ready quality

## See Also

- [Getting Started](manual/getting_started.md) for basic usage
- [API Reference](api.md) for complete function documentation
- [GitHub Examples](https://github.com/danielchen26/OptimShortestPaths.jl/tree/main/examples) for source code

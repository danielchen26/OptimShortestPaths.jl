# Comprehensive Framework Demonstration

Complete demonstration of OptimShortestPaths capabilities across all features and domains.

## Overview

The comprehensive demo showcases the entire OptimShortestPaths framework including:

1. **Problem Transformation Philosophy** - How to cast ANY problem as shortest paths
2. **Core Algorithm Capabilities** - DMY, BMSSP, pivot selection
3. **Multi-Objective Optimization** - Pareto fronts and decision methods
4. **Domain Applications** - Drug discovery, metabolism, treatment, supply chain
5. **Performance Benchmarking** - DMY vs Dijkstra across graph sizes

---

## Running the Demo

### Setup

```bash
cd examples/comprehensive_demo
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
```

### Run Complete Demonstration

```bash
julia --project=. comprehensive_demo.jl
```

**Output includes**:
- Problem transformation examples
- Algorithm validation tests
- Multi-objective Pareto analysis
- All 4 domain applications
- Performance comparisons

### Generate Publication-Quality Figures

```bash
julia --project=. generate_figures.jl
```

**Generates 7 figures** (300 DPI, Nature/Science quality):

1. **optimshortestpaths_philosophy.png** - Transformation framework overview
2. **problem_casting_methodology.png** - 8-step problem transformation workflow
3. **multi_domain_applications.png** - 8 domain examples (hub-and-spoke visualization)
4. **supply_chain_optimization.png** - Multi-echelon network example
5. **multi_objective_optimization.png** - Pareto front demonstrations
6. **real_world_applications.png** - Performance vs traditional methods
7. **algorithm_performance_comparison.png** - DMY vs Dijkstra benchmarks

---

## Framework Philosophy

### The Core Insight

**Every optimization problem seeks the "best path" through a decision space.**

By transforming to shortest paths, you can:
- ✅ Leverage powerful graph algorithms
- ✅ Handle complex multi-objective scenarios
- ✅ Use domain-agnostic generic tools
- ✅ Scale to large problem instances

### Transformation Methodology

**8-Step Process**:

1. **Problem Analysis**: Identify decisions, objectives, constraints
2. **State Mapping**: Enumerate states and properties
3. **Transition Design**: Define valid moves and dependencies
4. **Cost Modeling**: Quantify costs and penalties
5. **Graph Construction**: Build G=(V,E,w)
6. **Algorithm Selection**: Choose DMY vs Dijkstra
7. **Solution Extraction**: Run algorithm, get path
8. **Validation & Refinement**: Verify and iterate

---

## Multi-Domain Demonstrations

### 1. Drug Discovery

```julia
# Example from demo
drugs = ["Aspirin", "Ibuprofen"]
targets = ["COX-1", "COX-2"]
affinities = [("Aspirin", "COX-1", 2.5), ...]

network = create_drug_target_network(drugs, targets, affinities)
distance, path = find_drug_target_paths(network, "Aspirin", "COX-2")
```

**Demonstrates**: Biochemical affinity → graph distance transformation

### 2. Metabolic Pathways

```julia
# Example from demo
metabolites = ["Glucose", "G6P", "F6P", "Pyruvate", "ATP"]
reactions = [("Hexokinase", "Glucose", "G6P", -1.0), ...]

pathway = create_metabolic_pathway(metabolites, reactions)
atp_yield, path = find_metabolic_pathway(pathway, "Glucose", "ATP")
```

**Demonstrates**: Bipartite enzyme-metabolite graphs

### 3. Treatment Protocols

```julia
# Example from demo
treatments = ["Initial", "ChemoA", "Surgery", "Remission"]
costs = [0.0, 50.0, 100.0, 0.0]
efficacy = [0.0, 0.6, 0.8, 1.0]
transitions = [("Initial", "ChemoA", 0.1), ...]

protocol = create_treatment_protocol(treatments, costs, efficacy, transitions)
cost, sequence = optimize_treatment_sequence(protocol, "Initial", "Remission")
```

**Demonstrates**: Clinical decision graphs with multi-criteria trade-offs

### 4. Supply Chain

```julia
# Example from demo - generic graph construction
factories = 3
warehouses = 4
customers = 2
edges = build_supply_chain_edges(factories, warehouses, customers)

graph = DMYGraph(n_nodes, edges, shipping_costs)
optimal_cost = dmy_sssp!(graph, factory_1)[customer_1]
```

**Demonstrates**: Generic graph tools for custom domains

---

## Performance Benchmarking

### DMY vs Dijkstra

The demo includes comprehensive benchmarks loaded from `benchmark_results.txt`:

| Graph Size | DMY Time | Dijkstra Time | Speedup |
|------------|----------|---------------|---------|
| 200 | 0.08ms | 0.02ms | 0.31× |
| 500 | 0.43ms | 0.17ms | 0.39× |
| 1,000 | 1.46ms | 0.64ms | 0.44× |
| 2,000 | 1.42ms | 2.51ms | 1.77× |
| **5,000** | **3.35ms** | **16.03ms** | **4.79×** |

**Key Finding**: DMY becomes faster than Dijkstra at approximately n ≈ 1,800 vertices for sparse graphs (m ≈ 2n).

### Complexity Analysis

- **DMY**: O(m log^(2/3) n) - Sublinear in log n
- **Dijkstra**: O((m+n) log n) - Linear in log n
- **Bellman-Ford**: O(mn) - Linear in n

For sparse graphs (m = O(n)):
- DMY: O(n log^(2/3) n)
- Dijkstra: O(n log n)
- **Asymptotic advantage**: log^(1/3) n factor

---

## Code Examples

### Complete Demo Workflow

```julia
using OptimShortestPaths

println("="^70)
println("OptimShortestPaths FRAMEWORK DEMONSTRATION")
println("="^70)

# 1. Core Algorithm
edges = [Edge(1, 2, 1), Edge(2, 3, 2), Edge(1, 3, 3)]
graph = DMYGraph(3, edges, [1.0, 2.0, 4.0])
distances = dmy_sssp!(graph, 1)
println("✓ DMY algorithm works: ", distances)

# 2. Path reconstruction
dist, path = find_shortest_path(graph, 1, 3)
println("✓ Path finding: distance=", dist, ", path=", path)

# 3. Multi-objective
mo_edges = [MultiObjectiveEdge(1, 2, 1)]
mo_graph = MultiObjectiveGraph(2, mo_edges, [[1.0, 2.0]])
println("✓ Multi-objective graph created")

# 4. Domain-specific
drugs = ["Aspirin"]
targets = ["COX1"]
affinities = [("Aspirin", "COX1", 2.5)]
network = create_drug_target_network(drugs, targets, affinities)
println("✓ Drug-target network created")

println("\n✅ All framework components functional!")
```

---

## Running the Demo

### Interactive Demonstration

```bash
julia --project=. comprehensive_demo.jl
```

**Sections covered**:
1. Problem transformation philosophy
2. Core algorithm capabilities (SSSP, path reconstruction, bounded search)
3. Advanced features (BMSSP, pivot selection)
4. Multi-objective optimization (Pareto fronts, MCDA methods)
5. Domain applications (all 4 domains)
6. Performance analysis
7. Scalability demonstration

### Visualization Suite

```bash
julia --project=. generate_figures.jl
```

Creates 7 publication-ready figures demonstrating all aspects of the framework.

---

## What the Demo Shows

### Problem Transformation

**Any optimization problem can be cast as shortest paths**:
- Identify states → Vertices
- Define transitions → Edges
- Quantify costs → Weights
- Solve → Shortest path algorithm

### Algorithm Capabilities

**DMY Algorithm Features**:
- FindPivots: Frontier sparsification (k = n^(1/3) pivots)
- BMSSP: Bounded multi-source shortest path
- Recursive decomposition: O(log n) layers
- **Total complexity**: O(m log^(2/3) n)

### Multi-Objective Power

**Pareto Front Computation**:
- Identifies all non-dominated solutions
- Visualizes trade-off spaces
- Supports 3 decision methods (weighted sum, ε-constraint, lexicographic)
- Provides knee point selection for best compromise

### Domain Versatility

**Framework works for**:
- Pharmaceutical networks (drug binding)
- Biochemical networks (metabolism)
- Clinical networks (treatment)
- Logistics networks (supply chain)
- **...and ANY other optimization problem!**

---

## Performance Insights

### When to Use DMY

✅ **Large sparse graphs** (n > 1,800, m ≈ 2n)
✅ **Multi-objective scenarios** (no simple alternative)
✅ **Research applications** (breakthrough algorithm)

### When to Use Dijkstra

✅ **Small graphs** (n < 1,000)
✅ **Dense graphs** (m ≈ n²)
✅ **Production systems** (well-tested, reliable)

---

## Educational Value

The comprehensive demo serves as:

1. **Tutorial**: Learn the framework step-by-step
2. **Template**: Copy code patterns for your problems
3. **Validation**: Verify installation and functionality
4. **Benchmark**: Compare performance on your hardware
5. **Reference**: See all features demonstrated

---

## See Also

- [Getting Started](../manual/getting_started.md) - Basic usage
- [Problem Transformation](../manual/transformation.md) - Framework methodology
- [Multi-Objective](../manual/multiobjective.md) - Pareto optimization
- [All Examples](../examples.md) - Other domain examples
- [GitHub Demo](https://github.com/danielchen26/OptimShortestPaths.jl/tree/main/examples/comprehensive_demo)

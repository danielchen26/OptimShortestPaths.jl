# OptimShortestPaths.jl Examples

This directory contains comprehensive examples demonstrating real-world applications of OptimShortestPaths across multiple domains.

## Running Examples

Each example has its own project environment with plotting and visualization dependencies. To run an example:

```bash
cd examples/<example_name>
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
julia --project=. <example_name>.jl
```

Replace `<example_name>` with: `comprehensive_demo`, `drug_target_network`, `metabolic_pathway`, `treatment_protocol`, or `supply_chain`.

## Available Examples

### 1. Comprehensive Demo (`comprehensive_demo/`)

Complete framework demonstration showing the problem casting methodology.

**Files:**
- `comprehensive_demo.jl` - Main demo with all features
- `generate_figures.jl` - Publication-quality visualizations
- `run_benchmarks.jl` - Performance comparison (DMY vs Dijkstra)

**What it demonstrates:**
- Universal problem transformation methodology
- Performance benchmarks across graph sizes
- Multi-objective optimization with Pareto fronts
- Supply chain, scheduling, and network examples

**Key concepts:**
- How to map domain problems to graphs
- When DMY outperforms Dijkstra
- Multi-objective decision making

### 2. Drug-Target Network Analysis (`drug_target_network/`)

Pharmaceutical network optimization demonstrating both generic and domain-specific functions.

**Files:**
- `drug_target_network.jl` - Main analysis
- `generate_figures.jl` - Binding affinity heatmaps, selectivity charts

**What it demonstrates:**
- Binding affinity → distance transformation
- COX-2/COX-1 selectivity analysis (clinical relevance)
- Multi-objective drug discovery (efficacy vs toxicity vs cost)
- Comparison of generic vs domain-specific API

**Example output:**
```julia
# COX Selectivity Analysis:
# Aspirin:      COX1/COX2 ratio = 0.53  (non-selective)
# Ibuprofen:    COX1/COX2 ratio = 0.33  (slight COX-2)
# Celecoxib:    COX1/COX2 ratio = 0.05  (highly COX-2 selective)
```

**Demonstrates:**
- `create_drug_target_network()` - Domain-specific wrapper
- `calculate_distance_ratio()` - Generic selectivity function
- `compute_pareto_front()` - Multi-objective optimization

### 3. Metabolic Pathway Optimization (`metabolic_pathway/`)

Biochemical pathway analysis using bipartite graph representation.

**Files:**
- `metabolic_pathway.jl` - Glycolysis simulation
- `generate_figures.jl` - Pathway diagrams, ATP yield charts

**What it demonstrates:**
- Bipartite metabolite-reaction networks
- Glycolysis (Embden-Meyerhof-Parnas pathway)
- ATP yield calculations
- Aerobic vs anaerobic pathway comparison
- Generic vs domain-specific function comparison

**Network structure:**
```
Metabolites ←→ Reactions (bipartite)
17 metabolites, 15 enzymatic reactions
Glucose → Pyruvate (with branching to Lactate or Acetyl-CoA)
```

**Example output:**
```julia
# Glycolysis pathway:
# Net ATP yield: 2 ATP per glucose
# Optimal path cost: 12.7 ATP equivalents
# Aerobic (Pyruvate → Acetyl-CoA): Higher cost, enters TCA cycle
# Anaerobic (Pyruvate → Lactate): Lower cost, regenerates NAD+
```

### 4. Treatment Protocol Optimization (`treatment_protocol/`)

Healthcare decision pathway optimization.

**Files:**
- `treatment_protocol.jl` - Clinical pathway analysis
- `generate_figures.jl` - Decision trees, cost-efficacy charts

**What it demonstrates:**
- Clinical decision graph construction
- Cost-effectiveness analysis
- Risk-benefit scoring
- Multi-objective: outcome vs cost vs side effects
- Demonstrates both generic and domain-specific approaches

**Example structure:**
```
Screening → Imaging → Biopsy → {Surgery, Chemotherapy, Radiation} → Remission
```

**Example output:**
```julia
# Optimal treatment path (cost-minimizing):
# Initial_Screening → Diagnostic_Imaging → Biopsy → Staging → Multidisciplinary_Review → Radiation_Oncology → Follow_up_Monitoring → Remission
# Total cost: $10.8k (composite efficacy score ≈365)
```

### 5. Supply Chain Optimization (`supply_chain/`)

Logistics network optimization demonstrating multi-objective routing.

**Files:**
- `supply_chain.jl` - Network optimization
- `generate_figures.jl` - Network topology, flow charts

**What it demonstrates:**
- Multi-tier network (suppliers → warehouses → distributors → retailers)
- Multi-objective: cost vs time vs carbon emissions
- Generic graph functions applied to logistics

**Example output:**
```julia
# Optimal routes:
# Cost-optimal:   Factory → WH2 → DC3 → Retailer  ($150, 4.2 days, 75 kg CO₂)
# Time-optimal:   Factory → WH1 → DC1 → Retailer  ($180, 2.8 days, 95 kg CO₂)
# Carbon-optimal: Factory → WH2 → DC2 → Retailer  ($165, 3.5 days, 65 kg CO₂)
```

## Generic vs Domain-Specific Functions

All examples demonstrate both approaches:

**Generic Functions** (recommended for new domains):
```julia
graph = DMYGraph(vertices, edges, weights)
distances = dmy_sssp!(graph, source)
ratio = calculate_distance_ratio(graph, src, target1, target2)
metrics = analyze_connectivity(graph, vertex)
```

**Domain-Specific Functions** (convenience wrappers):
```julia
network = create_drug_target_network(drugs, targets, interactions)
distance, path = find_drug_target_paths(network, "Aspirin", "COX2")
```

Both give identical results - choose based on your use case.

## Generating Figures

Each example includes `generate_figures.jl` to create publication-quality visualizations:

```bash
cd examples/drug_target_network
julia --project=. generate_figures.jl
# Creates figures in docs/src/assets/figures/drug_target_network/
```

Figures use 300 DPI PNG format suitable for publications.

## Performance Notes

The DMY algorithm's theoretical O(m log^(2/3) n) advantage is most visible on large sparse graphs. From benchmarks:

- **Sparse graphs (m ≈ 2n)**: Crossover around n ≈ 1,800 vertices
- **n < 1,800**: Dijkstra often faster (lower constants)
- **n > 5,000**: DMY shows 4-5× speedup
- **Dense graphs**: Dijkstra may remain competitive

See `examples/comprehensive_demo/run_benchmarks.jl` for detailed performance analysis.

## Common Patterns

### Path Reconstruction
```julia
distance, path = find_shortest_path(graph, start, goal)
```

### Distance Comparison (Selectivity)
```julia
ratio = calculate_distance_ratio(graph, source, target1, target2)
# ratio > 1: target1 is farther (less preferred)
```

### Reachable Vertices (Budget Constraints)
```julia
reachable = find_reachable_vertices(graph, source, max_distance)
```

### Connectivity Analysis
```julia
metrics = analyze_connectivity(graph, vertex)
# Returns: out_degree, reachable_count, avg_distance
```

## Citation

If you use these examples in your research:

```bibtex
@software{optimshortestpaths2025,
  title = {OptimShortestPaths: Optimization via Shortest Paths},
  author = {Tianchi Chen},
  year = {2025},
  url = {https://github.com/danielchen26/OptimShortestPaths.jl}
}
```

And please cite the DMY algorithm paper [1].

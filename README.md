```
   ___        _   _           ____  _                _            _   ____       _   _
  / _ \ _ __ | |_(_)_ __ ___ / ___|| |__   ___  _ __| |_ ___  ___| |_|  _ \ __ _| |_| |__  ___
 | | | | '_ \| __| | '_ ` _ \\___ \| '_ \ / _ \| '__| __/ _ \/ __| __| |_) / _` | __| '_ \/ __|
 | |_| | |_) | |_| | | | | | |___) | | | | (_) | |  | ||  __/\__ \ |_|  __/ (_| | |_| | | \__ \
  \___/| .__/ \__|_|_| |_| |_|____/|_| |_|\___/|_|   \__\___||___/\__|_|   \__,_|\__|_| |_|___/
       |_|

  OptimShortestPaths.jl — Optimization via Shortest Paths
```

# OptimShortestPaths Framework

**OptimShortestPaths** is a practical Julia framework that casts optimization problems as graph shortest-path problems and leverages the breakthrough **2025 DMY algorithm** [1]. It provides multi-objective optimization tooling and domain-specific templates for pharmaceutical, metabolic, and healthcare applications.

## 🎯 **What OptimShortestPaths Is (and Isn't)**

### What OptimShortestPaths Provides (Value Added)
- **Domain Casting Framework**: Ready-made templates to transform optimization problems into graphs
- **Integration of DMY Algorithm**: Implementation of the STOC 2025 Best Paper algorithm [1]
- **Multi-Objective Tooling**: Standard MCDA approaches (weighted sum, ε-constraint, lexicographic)
- **Domain Applications**: Templates for drug discovery, metabolic pathways, and treatment protocols

### What's Derivative (Properly Attributed)
- The core speedup comes from the **DMY algorithm** (Duan-Mao-Yin, STOC 2025) [1]
- **Deterministic O(m log^(2/3) n)** time complexity for directed SSSP with non-negative weights
- Breaks the Dijkstra sorting barrier in the comparison-addition model

## 📋 **Model Assumptions & Scope**

### Algorithm Requirements
- **Non-negative edge weights** (required by DMY algorithm)
- **Directed graphs** (algorithm operates on directed edges)
- **Comparison-addition model** (theoretical complexity bounds)
- **Tie-breaking**: Uses consistent total ordering for deterministic results

### Multi-Objective Limitations
- Pareto set can grow exponentially in worst case
- Provides bounds/heuristics for practical computation
- Uses ε-dominance pruning for large problems
- Does NOT guarantee complete Pareto front for large networks

## 🚀 **Key Features**

- **Problem Casting Templates**: Transform domain problems into shortest-path formulations
- **DMY Algorithm Core**: O(m log^(2/3) n) complexity [1] (theoretically faster than Dijkstra's O(m log n))
- **Multi-Objective Optimization**: Pareto front computation with practical bounds
  - Weighted sum, ε-constraint, and lexicographic approaches
  - Knee point detection using established methods
  - ε-dominance pruning for computational tractability
- **Domain Applications**: 
  - Drug-target interaction networks
  - Metabolic pathway optimization
  - Treatment protocol sequencing
- **Testing**: 1,600+ assertions with validation against Dijkstra (randomized suites)

## 📁 **Project Structure**

```
OptimShortestPaths.jl/
├── src/                          # Source code
│   ├── OptimShortestPaths.jl                   # Main module (casting framework)
│   ├── core_types.jl             # Data structures
│   ├── graph_utils.jl            # Graph utilities
│   ├── bmssp.jl                  # Bounded Multi-Source Shortest Path
│   ├── pivot_selection.jl        # FindPivots implementation [1]
│   ├── dmy_algorithm.jl          # DMY algorithm implementation [1]
│   ├── multi_objective.jl        # Multi-objective extensions
│   ├── pharma_networks.jl        # Domain-specific applications
│   └── utilities.jl              # Helper functions
├── test/                         # Test suite
├── examples/                     # Application examples
├── Project.toml                 # Package configuration
└── README.md                    # This documentation
```

## 🛠️ **Installation and Setup**

```bash
# Clone the repository
git clone https://github.com/danielchen26/OptimShortestPaths.jl.git
cd OptimShortestPaths.jl

# Setup in development mode
julia --project=. -e "using Pkg; Pkg.develop(path=\".\"); Pkg.instantiate()"

# Run tests to verify installation
julia --project=. test/runtests.jl

# (Optional) Install visualization extras for figure generation
julia --project=. -e "using Pkg; Pkg.add.(\"Plots\", \"StatsPlots\", \"GraphRecipes\")"
```

## 🎯 **Quick Start**

### Basic Usage
```julia
using OptimShortestPaths

# Create a directed graph with non-negative weights
edges = [Edge(1, 2, 1), Edge(1, 3, 2), Edge(2, 4, 3), Edge(3, 4, 4)]
weights = [1.0, 2.0, 1.5, 0.5]  # Non-negative weights required
graph = DMYGraph(4, edges, weights)

# Compute shortest paths using DMY algorithm
distances = dmy_sssp!(graph, 1)
println(distances)  # [0.0, 1.0, 2.0, 2.5]
```

### Casting a domain problem
```julia
using OptimShortestPaths

metabolites = ["Glucose", "G6P", "Pyruvate"]
reactions = ["Hexokinase", "Pyruvate_Kinase"]
costs = [1.0, 0.5]
network = [("Glucose", "Hexokinase", "G6P"),
           ("G6P", "Pyruvate_Kinase", "Pyruvate")]

problem = OptimizationProblem(:metabolic, (metabolites, reactions, costs, network), 1)
distances = optimize_to_graph(problem)
```

### Running the packaged examples

Each example ships with its own project environment so that plotting and
benchmarking dependencies stay isolated. To run an example, change into its
directory, instantiate the environment once, and execute the desired script:

```bash
cd examples/<example_name>
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
julia --project=. <example_name>.jl          # or generate_figures.jl
cd ../..
```

Replace `<example_name>` with `comprehensive_demo`, `drug_target_network`,
`metabolic_pathway`, `treatment_protocol`, or `supply_chain` as needed.

## 🔄 **Two Approaches: Generic vs Domain-Specific Functions**

OptimShortestPaths provides **TWO ways** to use its shortest-path algorithms, giving you complete flexibility:

### **Approach 1: Generic Functions (Recommended for General Use)**
Use these domain-agnostic functions that work with ANY graph structure:

```julia
# Generic functions work with vertex indices directly
graph = DMYGraph(vertices, edges, weights)

# Core generic functions:
distances = dmy_sssp!(graph, source_vertex)                    # Single-source shortest paths
dist_ratio = calculate_distance_ratio(graph, src, target1, target2)  # Compare distances
metrics = analyze_connectivity(graph, vertex)                  # Connectivity analysis
reachable = find_reachable_vertices(graph, source, max_dist)  # Find vertices within budget
distance, path = find_shortest_path(graph, start, goal)       # Path finding
```

**✅ Benefits:**
- Works for ANY domain (logistics, networks, biology, economics, etc.)
- No domain knowledge required
- Direct control over graph structure
- Maximum flexibility

### **Approach 2: Domain-Specific Convenience Functions (Optional)**
For specific domains, we provide convenience wrappers that handle name mappings:

```julia
# Drug-target network example (pharmaceutical domain)
network = create_drug_target_network(drugs, targets, interactions)
distance, path = find_drug_target_paths(network, "Aspirin", "COX1")

# Treatment protocol example (healthcare domain)
protocol = create_treatment_protocol(treatments, costs, efficacy, transitions)
cost, sequence = optimize_treatment_sequence(protocol, "Screening", "Remission")
```

**✅ Benefits:**
- Intuitive domain-specific naming
- Automatic name-to-vertex mapping
- Domain-familiar terminology
- Easier for domain experts

### **Which Approach Should You Use?**

| Your Situation | Recommended Approach | Why |
|---------------|---------------------|-----|
| New domain not in examples | Generic Functions | No existing domain wrapper |
| Building a general tool | Generic Functions | Maximum flexibility |
| Working in pharmaceuticals/healthcare | Either | Domain wrappers available |
| Learning OptimShortestPaths | Start with Generic | Understand core concepts |
| Production system | Generic Functions | Better performance, control |
| Quick prototype in known domain | Domain Functions | Faster development |

### **Example: Same Problem, Both Approaches**

```julia
# Problem: Find best drug for COX-2 target

# GENERIC APPROACH (works for any domain):
cox2_vertex = 10  # COX-2 is vertex 10
aspirin_vertex = 1
ibuprofen_vertex = 2

dist_aspirin = dmy_sssp!(graph, aspirin_vertex)[cox2_vertex]
dist_ibuprofen = dmy_sssp!(graph, ibuprofen_vertex)[cox2_vertex]
best_drug = dist_aspirin < dist_ibuprofen ? "Aspirin" : "Ibuprofen"

# DOMAIN-SPECIFIC APPROACH (pharmaceutical convenience):
dist_aspirin, _ = find_drug_target_paths(network, "Aspirin", "COX2")
dist_ibuprofen, _ = find_drug_target_paths(network, "Ibuprofen", "COX2")
best_drug = dist_aspirin < dist_ibuprofen ? "Aspirin" : "Ibuprofen"
```

Both give the same result! Choose based on your needs.

## 📚 **Examples Gallery**

OptimShortestPaths includes comprehensive examples demonstrating real-world applications across multiple domains:

### 1. 🌟 **Comprehensive Demo** (`examples/comprehensive_demo/`)
Complete framework demonstration showcasing:
- Universal problem transformation methodology
- Performance benchmarks (DMY vs Dijkstra)
- Multi-objective optimization with Pareto fronts
- Supply chain, scheduling, portfolio, and social network examples
- Interactive visualizations and dashboard

**Quick Usage:**
```julia
using OptimShortestPaths

# Example: Supply chain optimization
# Transform locations into vertices, routes into edges
supply_nodes = 7  # Factory, 3 warehouses, 3 customers
supply_edges = [
    Edge(1, 2, 1), Edge(1, 3, 2), Edge(1, 4, 3),  # Factory to warehouses
    Edge(2, 5, 4), Edge(2, 6, 5), Edge(2, 7, 6),  # Warehouse 1 to customers
    Edge(3, 5, 7), Edge(3, 6, 8), Edge(3, 7, 9),  # Warehouse 2 to customers
]
supply_costs = [10.0, 15.0, 20.0, 5.0, 8.0, 12.0, 7.0, 6.0, 15.0]
supply_graph = DMYGraph(supply_nodes, supply_edges, supply_costs)

# Find optimal shipping routes from factory
distances = dmy_sssp!(supply_graph, 1)  # 1 = Factory vertex
println("Optimal cost to Customer-1: $", distances[5])
```

_See “Running the packaged examples” above for setup and execution commands._

### 2. 💊 **Drug-Target Network Analysis** (`examples/drug_target_network/`)
Pharmaceutical network optimization demonstrating:
- **BOTH approaches**: Generic functions AND domain-specific convenience functions
- Binding affinity to distance transformation using monotonic logit scaling
- COX-2/COX-1 selectivity analysis using generic `calculate_distance_ratio()`
- Multi-objective drug discovery (efficacy vs toxicity vs cost)
- 9 Pareto-optimal drug pathways identification
- Shows how to use generic functions for ANY selectivity analysis

**Quick Usage:**
```julia
using OptimShortestPaths

# Define drugs and targets with binding affinities
drugs = ["Aspirin", "Ibuprofen", "Celecoxib"]
targets = ["COX1", "COX2", "PGE2"]

# Binding affinity matrix (0-1, higher = stronger binding)
interactions = [
    0.80 0.20 0.50;  # Aspirin
    0.30 0.90 0.40;  # Ibuprofen  
    0.05 0.95 0.10   # Celecoxib (COX2 selective)
]

# Transform to graph (affinity → distance via -log(affinity / (1 + affinity)))
network = create_drug_target_network(drugs, targets, interactions)

# Find drug-target pathway
distance, path = find_drug_target_paths(network, "Celecoxib", "COX2")
println("Celecoxib → COX2 distance: ", round(distance, digits=3))

# Analyze drug connectivity
analysis = analyze_drug_connectivity(network, "Celecoxib")
println("Reachable targets: ", analysis["reachable_targets"], "/", analysis["total_targets"])
println("Average distance: ", round(analysis["avg_target_distance"], digits=3))
```

_See “Running the packaged examples” above for setup and execution commands._

### 3. 🧬 **Metabolic Pathway Optimization** (`examples/metabolic_pathway/`)
Systems biology application featuring:
- Bipartite graph representation of metabolic networks
- Glycolysis pathway optimization (canonical Embden-Meyerhof-Parnas)
- ATP yield calculation and flux distribution
- Thermodynamic constraint satisfaction (ΔG < 0)
- Energy landscape navigation

**Quick Usage:**
```julia
using OptimShortestPaths

# Define metabolites and enzymatic reactions
metabolites = ["Glucose", "G6P", "F6P", "Pyruvate", "Lactate", "ATP"]
reactions = ["Hexokinase", "PGI", "PFK", "Pyruvate_Kinase", "LDH"]

# Reaction costs (all must be non-negative for DMY algorithm)
reaction_costs = [
    1.0,   # Hexokinase (ATP consumption)
    0.5,   # Phosphoglucose isomerase
    1.0,   # Phosphofructokinase (ATP consumption)
    0.1,   # Pyruvate kinase (low cost - ATP producer)
    0.8    # Lactate dehydrogenase
]

# Build metabolic network (substrate → enzyme → product)
reaction_network = [
    ("Glucose", "Hexokinase", "G6P"),
    ("G6P", "PGI", "F6P"),
    ("F6P", "PFK", "Pyruvate"),
    ("Pyruvate", "LDH", "Lactate")
]

# Create and analyze pathway
pathway = create_metabolic_pathway(metabolites, reactions, 
                                  reaction_costs, reaction_network)
distance, path = find_metabolic_pathway(pathway, "Glucose", "Pyruvate")
println("Optimal path cost from Glucose to Pyruvate: ", round(distance, digits=2))
println("Path: ", join(path, " → "))
```

_See “Running the packaged examples” above for setup and execution commands._

### 4. 🏥 **Treatment Protocol Optimization** (`examples/treatment_protocol/`)
Healthcare pathway optimization including:
- **Demonstrates BOTH approaches side-by-side**:
  - Domain-specific: `optimize_treatment_sequence()`
  - Generic: `find_shortest_path()` and `analyze_connectivity()`
- Clinical decision graph construction
- Cost-effectiveness analysis using generic `find_reachable_vertices()` for budget constraints
- Risk-benefit scoring for treatment sequences
- Shows identical results from both approaches

**Quick Usage:**
```julia
using OptimShortestPaths

# Define treatment options and costs (in $1000s)
treatments = [
    "Screening", "Imaging", "Biopsy", "Surgery", 
    "Chemotherapy", "Radiation", "Immunotherapy", "Remission"
]
treatment_costs = [0.5, 2.0, 1.5, 35.0, 20.0, 30.0, 40.0, 0.0]

# Treatment efficacy scores (0-1)
efficacy = [1.0, 0.95, 0.98, 0.85, 0.75, 0.85, 0.70, 1.0]

# Define valid treatment transitions
transitions = [
    ("Screening", "Imaging", 0.2),      # transition cost
    ("Imaging", "Biopsy", 0.5),
    ("Biopsy", "Surgery", 1.0),
    ("Biopsy", "Chemotherapy", 0.8),
    ("Surgery", "Chemotherapy", 0.5),   # adjuvant
    ("Chemotherapy", "Radiation", 0.7),
    ("Radiation", "Remission", 0.3),
    ("Surgery", "Remission", 0.5)
]

# Create treatment protocol and find optimal path
protocol = create_treatment_protocol(treatments, treatment_costs, 
                                    efficacy, transitions)
distance, path = optimize_treatment_sequence(protocol, "Screening", "Remission")
println("Optimal treatment path cost: $", round(distance, digits=1), "k")
println("Treatment sequence: ", join(path, " → "))
```

_See “Running the packaged examples” above for setup and execution commands._

### Running All Examples

_See “Running the packaged examples” above for environment setup and execution
commands for each example._

## 🔬 **Core Algorithm Details**

### DMY Algorithm Components [1]
The implementation follows the STOC 2025 paper structure:

1. **FindPivots** (`pivot_selection.jl`): Frontier sparsification using pivot threshold
2. **BMSSP** (`bmssp.jl`): Bounded Multi-Source Shortest Path subroutine
3. **Recursive Structure** (`dmy_algorithm.jl`): Main algorithm with partial ordering

### Complexity Analysis
- **Theoretical**: O(m log^(2/3) n) time in comparison-addition model [1]
- **Practical**: Performance varies by graph structure, sparsity, and weight distribution
- **Comparison**: Asymptotically better than Dijkstra's O(m log n) for sparse graphs

## 📊 **Performance Benchmarks**

### Experimental Setup
- **Hardware**: Julia 1.9+ on modern CPU
- **Graph Types**: Sparse random graphs (m ≈ 2n edges)
- **Baseline**: Simple Dijkstra implementation
- **Methodology**: 40 warm start trials per solver, 95% confidence intervals (see `test/benchmark_performance.jl`)

| Graph Size | Edges | DMY (ms) ±95% CI | Dijkstra (ms) ±95% CI | Speedup |
|------------|-------|------------------|-----------------------|---------|
| 200        |   400 | 0.081 ± 0.002    | 0.025 ± 0.001         | 0.31×   |
| 500        | 1,000 | 0.426 ± 0.197    | 0.167 ± 0.004         | 0.39×   |
| 1,000      | 2,000 | 1.458 ± 1.659    | 0.641 ± 0.008         | 0.44×   |
| 2,000      | 4,000 | 1.415 ± 0.094    | 2.510 ± 0.038         | 1.77×   |
| 5,000      | 10,000| 3.346 ± 0.105    | 16.028 ± 0.241        | 4.79×   |

**Important Notes**: 
- Practical speedups vary with graph structure and constants
- Confidence intervals computed directly from the sampled trials
- Crossover in this configuration appears near n ≈ 1 800
- Performance benefits grow with larger sparse graphs

## ✅ **Testing and Validation**

### Test Coverage
- **1,600+ assertions** covering core functionality (exact totals vary with randomized cases)
- Correctness validation against Dijkstra (< 1e-10 difference)
- Edge cases and error handling
- Domain application validation

### Test Categories
1. Core data structures and validation
2. DMY algorithm implementation
3. BMSSP and FindPivots components
4. Multi-objective optimization (with bounds)
5. Domain-specific applications
6. Performance benchmarks

## 🔄 **The OptimShortestPaths Casting Paradigm**

### How to Cast Problems to Graphs

1. **Identify Entities → Vertices**
   - Drugs, metabolites, treatments, states

2. **Define Relationships → Edges**
   - Interactions, reactions, transitions

3. **Quantify Objectives → Weights**
   - Costs, affinities, durations (must be non-negative)

4. **Apply Graph Algorithms**
   - Single-objective: DMY for optimal paths
   - Multi-objective: Bounded Pareto front computation

5. **Interpret Results**
   - Map shortest paths back to domain solutions

## 💊 **Domain Applications**

### Drug Discovery Networks
- Convert binding affinities to distance metrics
- Identify polypharmacological targets
- Analyze off-target interactions

### Metabolic Pathway Analysis
- Find minimum energy pathways
- Predict flux distributions
- Optimize synthetic biology designs

### Treatment Protocol Optimization
- Sequence clinical interventions
- Balance cost, efficacy, and side effects
- Support personalized medicine

## 📚 **API Reference**

### Core Functions
```julia
dmy_sssp!(graph, source)                        # Main DMY algorithm
dmy_sssp_with_parents!(graph, source)           # With path reconstruction
dmy_sssp_bounded!(graph, source, max_distance)  # With distance bounds
```

### Multi-Objective Functions
```julia
compute_pareto_front(graph, source, target; max_solutions=1000)      # Bounded computation
weighted_sum_approach(graph, source, target, weights)                # Scalarization
epsilon_constraint_approach(graph, source, target, obj, constraints) # ε-constraint
lexicographic_approach(graph, source, target, priorities)            # Priority-based
get_knee_point(pareto_front)                                         # Trade-off selection
```

- `MultiObjectiveGraph` accepts an `objective_sense` vector to describe whether each
  objective is minimized (`:min`, default) or maximized (`:max`). The Pareto front and
  ε-constraint utilities respect these senses when comparing solutions.
- Algorithms that rely on the single-objective DMY core (`weighted_sum_approach`,
  `lexicographic_approach`) currently require every objective to be expressed as a cost
  (`sense = :min`). They raise an informative error if a maximizing objective is supplied.
  Convert such metrics to costs (e.g., by subtracting from a baseline) before using these
  helpers.

## 📄 **References**

[1] Duan, R., Mao, J., Yin, H., & Zhou, H. (2025). "Breaking the Dijkstra Barrier for Directed Single-Source Shortest-Paths via Structured Distances". *Proceedings of the 57th Annual ACM Symposium on Theory of Computing (STOC 2025)*. Best Paper Award.

[2] Ehrgott, M. (2005). *Multicriteria Optimization* (2nd ed.). Springer.

## 🔧 **Contributing**

Contributions welcome! Please:
- Add tests for new features
- Update benchmarks with your hardware specs
- Cite relevant papers for algorithmic contributions
- Follow Julia style guidelines
- Developer-facing utilities (e.g., verbose tracers) live under `dev/` so they stay out of the published package path

## 📝 **Citation**

If you use OptimShortestPaths in your research, please cite:

```bibtex
@software{optimshortestpaths2025,
  title = {OptimShortestPaths: Optimization via Shortest Paths},
  author = {Tianchi Chen},
  year = {2025},
  url = {https://github.com/danielchen26/OptimShortestPaths.jl}
}

@inproceedings{dmy2025,
  title = {Breaking the Dijkstra Barrier for Directed Single-Source Shortest-Paths via Structured Distances},
  author = {Duan, Ran and Mao, Jiayi and Yin, Hongxun and Zhou, Tianyi},
  booktitle = {STOC 2025},
  year = {2025}
}
```

## 📋 **License**

MIT License - See LICENSE file for details

---

**Framework Status**: Production-ready integration framework  
**Algorithm Attribution**: DMY algorithm (STOC 2025) [1]  
**Test Coverage**: 1,600+ assertions passing (randomized suites)  
**Domain Focus**: Pharmaceutical & healthcare optimization

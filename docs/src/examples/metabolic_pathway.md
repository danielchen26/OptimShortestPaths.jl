# Metabolic Pathway Optimization

Demonstrates OptimShortestPaths for metabolic engineering and systems biology applications.

## Overview

Metabolic pathways are networks of biochemical reactions where enzymes catalyze conversions between metabolites. Optimizing these pathways requires balancing:

- **ATP Yield**: Energy production efficiency
- **Time**: Pathway completion speed
- **Enzyme Load**: Protein expression cost
- **Byproducts**: Toxic metabolite accumulation

OptimShortestPaths models this as a bipartite graph where metabolites and reactions alternate as vertices, with edge weights representing enzymatic costs.

---

## Problem Transformation

### From Biochemistry to Graph

**Bipartite Network Structure**:
```
Metabolite → Reaction → Metabolite → Reaction → ...
```

**Example: Glycolysis**:
```
Glucose → [Hexokinase] → G6P → [PGI] → F6P → [PFK] → ... → Pyruvate
```

### Graph Construction

```julia
using OptimShortestPaths

# Define metabolites
metabolites = ["Glucose", "G6P", "F6P", "F16BP", "DHAP", "G3P", "PEP", "Pyruvate", "ATP"]

# Define reactions with ATP costs
reactions = [
    ("Hexokinase", "Glucose", "G6P", -1.0),    # Consumes 1 ATP
    ("PGI", "G6P", "F6P", 0.0),               # No ATP change
    ("PFK", "F6P", "F16BP", -1.0),            # Consumes 1 ATP
    ("Aldolase", "F16BP", "DHAP", 0.0),
    ("GAPDH", "G3P", "PEP", 2.0),             # Produces 2 ATP
    ("PK", "PEP", "Pyruvate", 2.0),           # Produces 2 ATP
]

# Create pathway
pathway = create_metabolic_pathway(metabolites, reactions)

# Find optimal pathway
atp_cost, path = find_metabolic_pathway(pathway, "Glucose", "Pyruvate")
println("Net ATP: ", -atp_cost, " molecules")  # Net +2 ATP for glycolysis
```

---

## Single-Objective Analysis

### ATP-Optimal Pathway

```julia
# Find pathway maximizing ATP production
distance, pathway_steps = find_metabolic_pathway(network, "Glucose", "ATP")

# Distance represents negative ATP yield
net_atp = -distance
println("ATP yield: ", net_atp, " molecules")
```

**Results**:
- **Glycolysis**: Net +2 ATP (anaerobic)
- **Aerobic respiration**: Net +32 ATP (with O₂)
- **Fermentation**: Net +2 ATP (produces lactate)

---

## Multi-Objective Pareto Analysis

### Competing Objectives

Real cells must balance multiple metabolic objectives:

```julia
# Create multi-objective metabolic network
objectives = [
    [atp_yield, time, enzyme_load, byproduct_ratio]
    # for each possible pathway
]

graph = MultiObjectiveGraph(n_vertices, edges, objectives;
    objective_sense = [:max, :min, :min, :min])  # Maximize ATP, minimize rest

# Compute Pareto front
strategies = compute_pareto_front(graph, glucose_idx, pyruvate_idx)
```

### Pareto-Optimal Strategies

| Strategy | ATP | Time | Enzymes | Byproducts | **Use Case** |
|----------|-----|------|---------|------------|--------------|
| Aerobic Respiration | 30 | 8.0min | 14.0 | 30% | Energy storage |
| Enhanced Glycolysis | 18 | 4.5min | 9.0 | 35% | Moderate activity |
| Balanced Strategy | 15 | 5.0min | 8.0 | 40% | Standard growth |
| Clean Metabolism | 10 | 6.0min | 7.0 | 30% | Detoxification |
| Rapid Glycolysis | 5 | 3.0min | 5.5 | 60% | Burst activity |
| Fermentation | 2 | 2.0min | 3.0 | 100% | Anaerobic stress |

### Selecting Strategy

```julia
# For fast energy needs (exercise)
best = weighted_sum_approach(graph, source, target, [0.3, 0.5, 0.1, 0.1])
# → Rapid Glycolysis

# For sustained growth
best = get_knee_point(strategies)
# → Balanced Strategy (optimal trade-off)
```

---

## Applications

### Metabolic Engineering

**Goal**: Design bacteria to produce biofuels efficiently

```julia
# Optimize ethanol production pathway
# Maximize: Ethanol yield
# Minimize: Byproducts, enzyme cost

pareto_pathways = compute_pareto_front(metabolic_graph, glucose, ethanol)

# Select based on industrial constraints
best_pathway = filter(sol -> sol.objectives[2] < 50.0, pareto_pathways)  # Low byproducts
```

### Systems Biology

**Goal**: Understand cellular metabolism under different conditions

- **Aerobic**: Cells prefer high-ATP aerobic pathways
- **Anaerobic**: Cells switch to fermentation (low ATP but fast)
- **Growth**: Balanced strategy (moderate ATP, moderate speed)
- **Stress**: Clean metabolism (minimize toxic byproducts)

### Personalized Medicine

**Goal**: Predict metabolic disease phenotypes

- **Diabetes**: Glucose metabolism dysregulation
- **Cancer (Warburg effect)**: Excessive fermentation even with oxygen
- **Mitochondrial disease**: Impaired aerobic respiration

---

## Running the Example

### Setup

```bash
cd examples/metabolic_pathway
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
```

### Run Analysis

```bash
julia --project=. metabolic_pathway.jl
```

### Generate Figures

```bash
julia --project=. generate_figures.jl
```

**Generates 8 figures**:
- Network structure
- Enzyme cost analysis
- ATP yield comparison
- Pareto front visualizations (2D and 3D)
- Strategy comparison
- Performance benchmarks

---

## Key Insights

### Why Graph-Based Approach Works

1. **Natural Fit**: Metabolism IS a directed graph
2. **Multi-objective**: Pareto front captures biological reality
3. **Efficiency**: O(m log^(2/3) n) scales to genome-wide models
4. **Interpretable**: Paths = actual biochemical pathways

### Clinical Relevance

- Cancer metabolism differences (Warburg effect)
- Metabolic syndrome (insulin resistance)
- Inborn errors of metabolism
- Drug effects on metabolic pathways

---

## See Also

- [Problem Transformation](../manual/transformation.md)
- [Multi-Objective Optimization](../manual/multiobjective.md)
- [API Reference](../api.md)
- [GitHub Example](https://github.com/danielchen26/OptimShortestPaths.jl/tree/main/examples/metabolic_pathway)

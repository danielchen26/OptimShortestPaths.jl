# Domain Applications

OptimShortestPaths provides built-in support for common application domains, particularly in pharmaceutical and healthcare optimization.

## Drug-Target Networks

Analyze drug-target interactions and selectivity.

### Creating a Network

```julia
using OptimShortestPaths

drugs = ["Aspirin", "Ibuprofen", "Celecoxib"]
targets = ["COX1", "COX2", "5-LOX", "PGHS"]

# Binding affinities (lower = stronger binding)
affinities = [
    ("Aspirin", "COX1", 2.5),
    ("Aspirin", "COX2", 3.2),
    ("Ibuprofen", "COX1", 1.8),
    ("Ibuprofen", "COX2", 2.1),
    ("Celecoxib", "COX2", 0.5),  # Highly selective
]

network = create_drug_target_network(drugs, targets, affinities)
```

### Finding Paths

```julia
# Find shortest path from drug to target
distance, path = find_drug_target_paths(network, "Aspirin", "COX2")
println("Binding affinity: ", distance)
```

### Analyzing Selectivity

```julia
# Compare drug affinity for two targets
ratio = calculate_distance_ratio(network.graph, drug_idx, cox1_idx, cox2_idx)
println("COX2/COX1 selectivity ratio: ", ratio)

# Analyze overall connectivity
stats = analyze_drug_connectivity(network, "Celecoxib")
println("Reachable targets: ", stats)
```

## Metabolic Pathways

Optimize biochemical reaction pathways.

### Creating a Pathway

```julia
metabolites = ["Glucose", "G6P", "F6P", "F16BP", "DHAP", "G3P", "PEP", "Pyruvate", "ATP"]

reactions = [
    ("Hexokinase", "Glucose", "G6P", -1.0),      # ATP cost
    ("PGI", "G6P", "F6P", 0.0),
    ("PFK", "F6P", "F16BP", -1.0),               # ATP cost
    ("Aldolase", "F16BP", "DHAP", 0.0),
    ("TPI", "DHAP", "G3P", 0.0),
    ("GAPDH", "G3P", "PEP", 2.0),                # ATP production
    ("PK", "PEP", "Pyruvate", 2.0),              # ATP production
]

pathway = create_metabolic_pathway(metabolites, reactions)
```

### Finding Optimal Pathways

```julia
# Find pathway from substrate to product
atp_cost, pathway_steps = find_metabolic_pathway(pathway, "Glucose", "Pyruvate")
println("Net ATP yield: ", -atp_cost)  # Negative cost = ATP production
println("Pathway: ", pathway_steps)
```

## Treatment Protocols

Optimize clinical treatment sequences.

### Creating a Protocol

```julia
treatments = ["Initial", "ChemoA", "ChemoB", "Surgery", "Radiation", "Remission"]

# Costs in thousands of dollars
costs = [0.0, 50.0, 60.0, 100.0, 40.0, 0.0]

# Efficacy weights (higher = better outcome)
efficacy = [0.0, 0.6, 0.7, 0.8, 0.5, 1.0]

# Valid treatment transitions (from, to, additional_risk)
transitions = [
    ("Initial", "ChemoA", 0.1),
    ("Initial", "Surgery", 0.3),
    ("ChemoA", "ChemoB", 0.05),
    ("ChemoA", "Surgery", 0.2),
    ("ChemoB", "Radiation", 0.15),
    ("Surgery", "Radiation", 0.1),
    ("Radiation", "Remission", 0.05),
]

protocol = create_treatment_protocol(treatments, costs, efficacy, transitions)
```

### Optimizing Sequences

```julia
# Find lowest-cost path to remission
total_cost, sequence = optimize_treatment_sequence(protocol, "Initial", "Remission")

println("Total cost: \$", total_cost * 1000)
println("Optimal sequence: ", sequence)
```

## Supply Chain Optimization

For custom domains like supply chain, use the generic interface:

```julia
# Entities: Factories, warehouses, distribution centers
# Edges: Transportation links
# Weights: Shipping cost + inventory holding cost

factories = 3
warehouses = 4
dist_centers = 5
n_vertices = factories + warehouses + dist_centers

edges = Edge[]
weights = Float64[]

# Factory → Warehouse links
for f in 1:factories
    for w in 1:warehouses
        from = f
        to = factories + w
        transport_cost = rand(10:20)
        push!(edges, Edge(from, to, length(edges)+1))
        push!(weights, float(transport_cost))
    end
end

# Warehouse → Distribution center links
for w in 1:warehouses
    for d in 1:dist_centers
        from = factories + w
        to = factories + warehouses + d
        cost = rand(5:15)
        push!(edges, Edge(from, to, length(edges)+1))
        push!(weights, float(cost))
    end
end

graph = DMYGraph(n_vertices, edges, weights)

# Find optimal route from factory 1 to dist center 3
target = factories + warehouses + 3
distances = dmy_sssp!(graph, 1)
println("Minimum cost to DC 3: \$", distances[target])
```

## Generic Pattern

All domain applications follow this pattern:

1. **Define entities** (metabolites, drugs, locations, etc.)
2. **Define relationships** (reactions, bindings, routes, etc.)
3. **Assign costs/weights** (affinities, times, distances, etc.)
4. **Create graph** using domain constructor or generic DMYGraph
5. **Run algorithm** to find optimal solutions

## See Also

- [Problem Transformation](transformation.md) for general framework
- [API Reference - Domain Functions](../api.md#Domain-Specific-Applications)
- [Examples](../examples.md) for complete worked examples

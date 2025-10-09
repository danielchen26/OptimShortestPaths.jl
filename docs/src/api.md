# API Reference

Complete reference for all exported functions and types in OptimShortestPaths.

## Core Algorithm

### Main Functions

```@docs
dmy_sssp!
dmy_sssp_with_parents!
dmy_sssp_bounded!
```

### Graph Types

```@docs
DMYGraph
Edge
Block
```

### Algorithm Components

```@docs
recursive_layer!
bmssp!
bmssp_single_round!
select_pivots
partition_blocks
partition_blocks_adaptive
```

### Validation

```@docs
validate_bmssp_input
validate_dmy_input
```

### Statistics

```@docs
bmssp_with_statistics!
dmy_algorithm_statistics
count_relaxations
```

## Multi-Objective Optimization

### Main Functions

```@docs
compute_pareto_front
get_knee_point
compute_path_objectives
```

### Optimization Methods

```@docs
weighted_sum_approach
epsilon_constraint_approach
lexicographic_approach
```

### Types

```@docs
ParetoSolution
MultiObjectiveGraph
MultiObjectiveEdge
```

## Problem Transformation

The core innovation of OptimShortestPaths - transforming optimization problems into graphs.

```@docs
OptimizationProblem
optimize_to_graph
cast_problem
objectives_to_weights
```

## Domain-Specific Applications

### Pharmaceutical Networks

#### Types

```@docs
PharmaNetwork
DrugTargetNetwork
MetabolicPathway
TreatmentProtocol
```

#### Constructors

```@docs
create_drug_target_network
create_metabolic_pathway
create_treatment_protocol
```

#### Analysis Functions

```@docs
find_drug_target_paths
analyze_drug_connectivity
find_metabolic_pathway
optimize_treatment_sequence
```

## Generic Graph Utilities

### Path Operations

```@docs
find_shortest_path
reconstruct_path
shortest_path_tree
path_length
```

### Connectivity Analysis

```@docs
analyze_connectivity
find_reachable_vertices
graph_reachability
is_connected
```

### Distance Metrics

```@docs
calculate_distance_ratio
calculate_path_preference
compare_sources
```

### Graph Properties

```@docs
vertex_count
edge_count
out_degree
outgoing_edges
graph_density
graph_statistics
has_self_loops
get_vertices_by_out_degree
```

### Edge Operations

```@docs
get_edge
get_edge_weight
get_edge_weight_between
find_edge
iterate_edges
get_all_targets
```

### Graph Construction

```@docs
create_simple_graph
```

### Validation & Verification

```@docs
validate_graph
validate_vertex
verify_shortest_path
format_distance_results
```

### Comparison & Benchmarking

```@docs
compare_with_dijkstra
simple_dijkstra
```

## Advanced Functions

### Pivot Selection

```@docs
calculate_pivot_threshold
calculate_partition_parameter
pivot_selection_statistics
validate_pivot_selection
```

## Index

```@index
```

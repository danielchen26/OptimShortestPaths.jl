# Getting Started

This guide will help you get started with OptimShortestPaths.

## Installation

```julia
using Pkg
Pkg.add("OptimShortestPaths")
```

## Your First Shortest Path

```julia
using OptimShortestPaths

# Create a simple graph: 1 → 2 → 3
#                        └─────→ 3
edges = [
    Edge(1, 2, 1),  # Edge from vertex 1 to 2 (id=1)
    Edge(2, 3, 2),  # Edge from vertex 2 to 3 (id=2)
    Edge(1, 3, 3)   # Direct edge from 1 to 3 (id=3)
]
weights = [1.0, 2.0, 4.0]  # Edge weights (costs)

graph = DMYGraph(3, edges, weights)

# Run DMY algorithm from source vertex 1
distances = dmy_sssp!(graph, 1)

println("Shortest distances from vertex 1:")
println("  to vertex 1: ", distances[1])  # 0.0
println("  to vertex 2: ", distances[2])  # 1.0
println("  to vertex 3: ", distances[3])  # 3.0 (via 1→2→3, not direct 1→3)
```

## Path Reconstruction

To get the actual path, not just distances:

```julia
# Use variant that returns parent tree
distances, parent = dmy_sssp_with_parents!(graph, 1)

# Reconstruct path from source to target
path = reconstruct_path(parent, 1, 3)
println("Path from 1 to 3: ", path)  # [1, 2, 3]
```

## Using High-Level Interface

```julia
# Even simpler - one function call
distance, path = find_shortest_path(graph, 1, 3)
println("Distance: ", distance)  # 3.0
println("Path: ", path)          # [1, 2, 3]
```

## Next Steps

- Learn about [Problem Transformation](transformation.md)
- Explore [Multi-Objective Optimization](multiobjective.md)
- See [Domain Applications](domains.md) for real-world examples
- Check [API Reference](../api.md) for all functions

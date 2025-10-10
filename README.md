# OptimShortestPaths.jl

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://danielchen26.github.io/OptimShortestPaths.jl/stable)
[![Dev Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://danielchen26.github.io/OptimShortestPaths.jl/dev)
[![CI Status](https://github.com/danielchen26/OptimShortestPaths.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/danielchen26/OptimShortestPaths.jl/actions/workflows/ci.yml)
[![Codecov](https://codecov.io/gh/danielchen26/OptimShortestPaths.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/danielchen26/OptimShortestPaths.jl)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Julia framework for solving optimization problems via shortest path algorithms, featuring an implementation of the DMY algorithm (STOC 2025) [1].

## Features

- Implementation of the DMY algorithm with O(m log^(2/3) n) complexity [1]
- Generic graph utilities for single-source shortest paths
- Multi-objective optimization with Pareto front computation
- Domain application templates (pharmaceutical, metabolic, clinical)

## Installation

```julia
using Pkg
Pkg.add("OptimShortestPaths")
```

Or for development:
```julia
Pkg.develop(url="https://github.com/danielchen26/OptimShortestPaths.jl")
```

## Quick Start

```julia
using OptimShortestPaths

# Create a directed graph with non-negative weights
edges = [Edge(1, 2, 1), Edge(1, 3, 2), Edge(2, 4, 3), Edge(3, 4, 4)]
weights = [1.0, 2.0, 1.5, 0.5]
graph = DMYGraph(4, edges, weights)

# Compute shortest paths from source vertex 1
distances = dmy_sssp!(graph, 1)
# Output: [0.0, 1.0, 2.0, 2.5]
```

## Algorithm

The package implements the DMY (Duan-Mao-Yin) algorithm from STOC 2025 [1], which achieves O(m log^(2/3) n) time complexity for directed single-source shortest paths with non-negative weights. Key components:

- **FindPivots**: Frontier sparsification using pivot threshold
- **BMSSP**: Bounded multi-source shortest path subroutine
- **Recursive decomposition**: Divide-and-conquer on large frontiers

**Requirements**: Non-negative edge weights, directed graphs

**Performance**: Theoretical speedup over Dijkstra's O(m log n) is most pronounced on large sparse graphs. Practical crossover point depends on graph structure and implementation constants.

## Multi-Objective Optimization

```julia
using OptimShortestPaths.MultiObjective

# Create multi-objective graph
edges = [MultiObjectiveEdge(1, 2, [1.0, 2.0], 1), ...]
graph = MultiObjectiveGraph(n, edges, 2, adjacency,
                           ["Cost", "Time"],
                           objective_sense=[:min, :min])

# Compute Pareto front
pareto_front = compute_pareto_front(graph, source, target, max_solutions=100)
```

Supports weighted sum, ε-constraint, and lexicographic approaches.

## Examples

See [`examples/`](examples/) for complete applications:

- **Drug-Target Networks**: Pharmaceutical optimization with COX selectivity analysis
- **Metabolic Pathways**: Glycolysis and biochemical pathway optimization
- **Treatment Protocols**: Clinical decision sequencing
- **Supply Chain**: Logistics network optimization

Each example includes detailed documentation and figure generation scripts.

## Testing

```julia
using Pkg
Pkg.test("OptimShortestPaths")
```

The test suite includes 1,600+ assertions validating algorithm correctness, multi-objective optimization, and domain applications.

## Documentation

Complete documentation with examples and API reference:
https://danielchen26.github.io/OptimShortestPaths.jl/stable/

## References

[1] Duan, R., Mao, J., Yin, H., & Zhou, T. (2025). "Breaking the Dijkstra Barrier for Directed Single-Source Shortest-Paths via Structured Distances". *STOC 2025*.

## License

MIT License - see [LICENSE](LICENSE) for details.

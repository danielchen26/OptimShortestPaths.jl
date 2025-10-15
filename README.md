```
   ___        _   _           ____  _                _            _   ____       _   _
  / _ \ _ __ | |_(_)_ __ ___ / ___|| |__   ___  _ __| |_ ___  ___| |_|  _ \ __ _| |_| |__  ___
 | | | | '_ \| __| | '_ ` _ \\___ \| '_ \ / _ \| '__| __/ _ \/ __| __| |_) / _` | __| '_ \/ __|
 | |_| | |_) | |_| | | | | | |___) | | | | (_) | |  | ||  __/\__ \ |_|  __/ (_| | |_| | | \__ \
  \___/| .__/ \__|_|_| |_| |_|____/|_| |_|\___/|_|   \__\___||___/\__|_|   \__,_|\__|_| |_|___/
       |_|

  OptimShortestPaths.jl — Optimization via Shortest Paths
```

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

This minimal example builds a four-vertex directed graph, runs the DMY single-source shortest-path solver from vertex `1`, and shows the distance to every node. Use it as a template: replace the edges/weights with your own data and pick the source you care about.

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

The result vector lists the shortest-path cost from the source to each vertex. Here vertex `4` ends up at `2.5` because both routes `1 → 2 → 4` and `1 → 3 → 4` cost `1.0 + 1.5` and `2.0 + 0.5`, respectively; the algorithm keeps the minimum.

## Algorithm

The package implements the DMY (Duan-Mao-Yin) algorithm from STOC 2025 [1], which achieves O(m log^(2/3) n) time complexity for directed single-source shortest paths with non-negative weights. Key components:

- **FindPivots**: Frontier sparsification using pivot threshold
- **BMSSP**: Bounded multi-source shortest path subroutine
- **Recursive decomposition**: Divide-and-conquer on large frontiers

## Model Assumptions & Scope

### Algorithm Requirements
- **Non-negative edge weights**: Required by DMY algorithm (cannot handle negative weights)
- **Directed graphs**: Algorithm designed for directed edges
- **Comparison-addition model**: Theoretical complexity bounds apply in this model

### Performance Characteristics
- **Theoretical**: O(m log^(2/3) n) vs Dijkstra's O(m log n)
- **Practical crossover**: Around n ≈ 1,800 vertices for sparse graphs (m ≈ 2n)
- **Best case**: Large sparse graphs (m = O(n) to O(n log n))
- **Competitive case**: Small graphs (n < 1,000) or dense graphs where Dijkstra may be faster

### Multi-Objective Limitations
- Pareto set can grow exponentially in worst case
- Practical bounds via `max_solutions` parameter
- ε-dominance pruning for computational tractability
- Does not guarantee complete Pareto front for large multi-objective problems

## Multi-Objective Optimization

This self-contained example constructs a tiny two-objective graph (cost and time) and prints the Pareto-optimal paths from vertex `1` to `4`.

```julia
using OptimShortestPaths
using OptimShortestPaths.MultiObjective

edges = [
    MultiObjectiveEdge(1, 2, [1.0, 5.0], 1),
    MultiObjectiveEdge(1, 3, [2.0, 3.0], 2),
    MultiObjectiveEdge(2, 4, [1.0, 2.0], 3),
    MultiObjectiveEdge(3, 4, [0.5, 4.0], 4),
]

adjacency = [Int[] for _ in 1:4]
for (i, edge) in enumerate(edges)
    push!(adjacency[edge.source], i)
end

graph = MultiObjectiveGraph(4, edges, 2, adjacency,
                            ["Cost", "Time"],
                            objective_sense=[:min, :min])

pareto_front = compute_pareto_front(graph, 1, 4)
for solution in pareto_front
    println("Objectives: $(round.(solution.objectives, digits=2))  Path: $(solution.path)")
end
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

The test suite includes comprehensive assertions (over 1,800 passing tests) validating algorithm correctness, multi-objective optimization, and domain applications.

## Documentation

Complete documentation with examples and API reference:
https://danielchen26.github.io/OptimShortestPaths.jl/stable/

## References

[1] Duan, R., Mao, J., Yin, H., & Zhou, H. (2025). "Breaking the Dijkstra Barrier for Directed Single-Source Shortest-Paths via Structured Distances". *Proceedings of the 57th Annual ACM Symposium on Theory of Computing (STOC 2025)*.

## License

MIT License - see [LICENSE](LICENSE) for details.

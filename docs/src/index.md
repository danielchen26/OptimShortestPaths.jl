# OptimShortestPaths.jl

*Transform optimization problems into graph shortest paths using the efficient DMY algorithm*

## Overview

OptimShortestPaths is a Julia package that provides a unified framework for solving optimization problems by transforming them into shortest-path problems on directed graphs. The package implements the state-of-the-art DMY (Duan-Mao-Yin) algorithm from STOC 2025, achieving O(m log^(2/3) n) time complexity for single-source shortest paths.

### Key Features

- **Efficient Algorithm**: DMY algorithm with O(m log^(2/3) n) complexity
- **Multi-Objective**: Pareto front computation with bounded solutions
- **Domain-Agnostic**: Transform ANY optimization problem to shortest paths
- **Domain-Specific**: Built-in support for drug discovery, metabolic networks, treatment protocols
- **Well-Tested**: Over 1,900 passing tests with 100% pass rate
- **Publication-Quality**: Professional figures and comprehensive benchmarks

## Quick Start

```julia
using Pkg
Pkg.add("OptimShortestPaths")
using OptimShortestPaths

# Create a graph
edges = [Edge(1, 2, 1), Edge(2, 3, 2), Edge(1, 3, 3)]
weights = [1.0, 2.0, 4.0]
graph = DMYGraph(3, edges, weights)

# Run DMY algorithm
distances = dmy_sssp!(graph, 1)  # Source vertex 1
println("Distances: ", distances)  # [0.0, 1.0, 3.0]
```

### Cheat Sheet

- For a comprehensive, example-driven overview, see the [Cheat Sheet](cheatsheet.md) page. It includes:
  - Core shortest-path usage with line-by-line annotations
  - Utilities, validations, and analysis helpers
  - Multi-objective strategies and topology diagrams
  - A categorized function reference and detailed output-key tables

## Installation

The package requires Julia 1.9 or later:

```julia
using Pkg
Pkg.add("OptimShortestPaths")
```

For development version:

```julia
using Pkg
Pkg.develop("OptimShortestPaths")
```

## Core Concepts

### Problem Transformation Philosophy

OptimShortestPaths transforms optimization problems into shortest-path problems:

1. **Entities → Vertices**: Map domain objects to graph vertices
2. **Relationships → Edges**: Convert interactions/transitions to directed edges
3. **Objectives → Weights**: Transform costs to non-negative edge weights
4. **Solutions → Paths**: Shortest paths = optimal solutions

### Why This Approach?

- **Unified Framework**: One algorithm solves many problems
- **Efficient**: O(m log^(2/3) n) complexity beats many domain-specific methods
- **Flexible**: Generic graph utilities work for any domain
- **Proven**: Based on award-winning STOC 2025 algorithm

## Main Components

### Core Algorithm
- `dmy_sssp!` - Main DMY shortest path algorithm
- `DMYGraph` - Graph data structure
- `bmssp!` - Bounded Multi-Source Shortest Path subroutine

### Multi-Objective Optimization
- `compute_pareto_front` - Pareto front computation
- `weighted_sum_approach` - Scalarization method
- `epsilon_constraint_approach` - ε-constraint method

### Domain Applications
- Drug-target network analysis
- Metabolic pathway optimization
- Treatment protocol sequencing
- Supply chain optimization

## Performance

Benchmarks on sparse random graphs (m ≈ 2n):

| Graph Size | DMY Time | Dijkstra Time | Speedup |
|------------|----------|---------------|---------|
| 200        | 0.08 ms  | 0.02 ms       | 0.31×   |
| 500        | 0.43 ms  | 0.17 ms       | 0.39×   |
| 1,000      | 1.46 ms  | 0.64 ms       | 0.44×   |
| 2,000      | 1.42 ms  | 2.51 ms       | 1.77×   |
| **5,000**  | **3.35 ms** | **16.03 ms** | **4.79×** |

DMY becomes faster than Dijkstra at approximately n ≈ 1,800 vertices.

## Citation

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
  author = {Duan, Ran and Mao, Jiawei and Yin, Hao and Zhou, Hengming},
  booktitle = {Proceedings of the 57th Annual ACM Symposium on Theory of Computing (STOC 2025)},
  year = {2025},
  note = {Best Paper Award}
}
```

## Contributing

Contributions are welcome! Please:
- Add tests for new features
- Update benchmarks with your hardware specs
- Cite relevant papers for algorithmic contributions
- Follow Julia style guidelines

## License

MIT License - see LICENSE file for details.

## Acknowledgments

The DMY algorithm implementation is based on the STOC 2025 Best Paper by Duan, Mao, Yin, and Zhou.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ RED LINE RULES

**SOLE AUTHORSHIP REQUIREMENT**:
- **NEVER** add "Co-Authored-By: Claude" to git commits
- **NEVER** add "Generated with Claude Code" attribution to git commits
- ALL commits must show **ONLY** the repository owner (Tianchi Chen) as the author
- This is a strict requirement for academic publication and professional work
- Claude Code is a tool; the intellectual work belongs solely to the user

**NO HARD-CODED FAKE DATA**:
- **NEVER** use hard-coded numbers in example outputs, summaries, or "KEY FINDINGS" sections
- **ALWAYS** print values from actual computations and simulations
- **NEVER** fabricate plausible-sounding results - all numbers must be traceable to code execution
- **ALWAYS** use string interpolation with computed variables: `$(round(computed_value, digits=2))`
- **ALWAYS** check feasibility before printing results (e.g., `isfinite()` checks for -Inf/Inf)
- This prevents the critical "LLM-generated without oversight" artifacts that would cause registry rejection
- Examples: If code computes cost=12.7, print statement MUST print 12.7, NOT a different hard-coded value like 6.2
- Cross-reference: Every number in summary sections must match the actual computation earlier in the script

## Commands

### Testing
```bash
# Run all tests
julia --project=. test/runtests.jl

# Run a single test file
julia --project=. test/run_single_test.jl test_core_types.jl

# Run specific test set
julia --project=. -e "using Test; include(\"test/test_dmy_algorithm.jl\")"
```

### Development Setup
```bash
# Install dependencies and develop package
julia --project=. -e "using Pkg; Pkg.develop(path=\".\"); Pkg.instantiate()"

# Interactive REPL with project
julia --project=.
```

### Running Examples
```bash
# Run comprehensive demo
julia --project=. examples/comprehensive_demo/comprehensive_demo.jl

# Generate visualizations
julia --project=. examples/comprehensive_demo/generate_figures.jl
```

## Architecture

### Core Graph Algorithm Framework
The codebase implements the DMY (Duan-Mao-Yin) algorithm from STOC 2025, which achieves O(m log^(2/3) n) time complexity for directed single-source shortest paths with non-negative weights.

**Key Components:**
1. **DMYGraph** (`src/core_types.jl`): Central graph representation using adjacency lists
2. **DMY Algorithm** (`src/dmy_algorithm.jl`): Main recursive algorithm with three phases:
   - FindPivots: Frontier sparsification
   - BMSSP: Bounded multi-source shortest path subroutine  
   - Recursive decomposition for large frontiers
3. **Multi-objective Extensions** (`src/multi_objective.jl`): Pareto front computation with bounded solutions

### Problem Casting Paradigm
OptimShortestPaths transforms domain problems into shortest-path problems:
- **Entities → Vertices**: Map domain objects (drugs, metabolites, treatments) to graph vertices
- **Relationships → Edges**: Convert interactions/transitions to directed edges
- **Objectives → Weights**: Transform costs/affinities to non-negative edge weights (required by DMY)
- **Solutions → Paths**: Shortest paths correspond to optimal domain solutions

### Domain Applications
The framework provides both generic graph functions and domain-specific convenience wrappers:

**Generic Functions** (work with any graph):
- `dmy_sssp!(graph, source)`: Core shortest path
- `find_shortest_path(graph, start, goal)`: Path finding with reconstruction
- `analyze_connectivity(graph, vertex)`: Connectivity analysis
- `calculate_distance_ratio(graph, src, target1, target2)`: Selectivity analysis

**Domain Wrappers** (`src/pharma_networks.jl`):
- Drug-target networks: Binding affinity → distance via thermodynamic transformation
- Metabolic pathways: Bipartite enzyme-metabolite graphs
- Treatment protocols: Clinical decision graphs with cost-efficacy tradeoffs

### Critical Constraints
- **Non-negative weights only**: DMY algorithm requirement, enforced in DMYGraph constructor
- **Directed graphs**: Algorithm designed for directed edges
- **Pareto set bounds**: Multi-objective solutions limited to prevent exponential growth
- **Tie-breaking**: Consistent total ordering for deterministic results
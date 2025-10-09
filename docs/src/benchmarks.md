# Performance Benchmarks

Comprehensive performance analysis of the DMY algorithm implementation.

## Experimental Setup

- **Hardware**: Julia 1.9+ on modern CPU
- **Graph Types**: Sparse random graphs (m ≈ 2n edges)
- **Baseline**: Simple Dijkstra implementation
- **Methodology**: 40 warm-up trials per solver, 95% confidence intervals
- **Source**: `benchmark_results.txt` and `test/benchmark_performance.jl`

## Results

### DMY vs Dijkstra

| Graph Size | Edges | DMY (ms) ±95% CI | Dijkstra (ms) ±95% CI | Speedup |
|------------|-------|------------------|-----------------------|---------|
| 200        |   400 | 0.081 ± 0.002    | 0.025 ± 0.001         | 0.31×   |
| 500        | 1,000 | 0.426 ± 0.197    | 0.167 ± 0.004         | 0.39×   |
| 1,000      | 2,000 | 1.458 ± 1.659    | 0.641 ± 0.008         | 0.44×   |
| 2,000      | 4,000 | 1.415 ± 0.094    | 2.510 ± 0.038         | 1.77×   |
| **5,000**  | **10,000** | **3.346 ± 0.105** | **16.028 ± 0.241** | **4.79×** |

### Key Findings

- **Crossover point**: DMY becomes faster than Dijkstra at approximately **n ≈ 1,800 vertices**
- **Scaling**: DMY shows better asymptotic scaling as predicted by theory
- **Best case**: 4.79× speedup observed at n=5,000 vertices
- **Sparse graphs**: Results are for graphs with m ≈ 2n (realistic for many applications)

## Complexity Analysis

### Theoretical Complexity

| Algorithm | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| DMY | O(m log^(2/3) n) | O(n + m) |
| Dijkstra | O((m+n) log n) | O(n + m) |
| Bellman-Ford | O(mn) | O(n + m) |

### Asymptotic Comparison

For sparse graphs where m = O(n):

- **Dijkstra**: O(n log n)
- **DMY**: O(n log^(2/3) n)
- **Ratio**: log^(1/3) n advantage for DMY

At n = 10,000:
- log^(1/3)(10,000) ≈ 4.64× theoretical speedup

## Practical Considerations

### When DMY is Faster

✅ **Large sparse graphs** (n > 2,000, m ≈ 2n)
✅ **Many shortest-path queries** (amortize initialization cost)
✅ **Academic/research** applications

### When Dijkstra is Faster

✅ **Small graphs** (n < 1,000)
✅ **Dense graphs** (m ≈ n²)
✅ **Single query** on simple graph

### Recommendations

- **n < 1,000**: Use Dijkstra (built-in or LightGraphs.jl)
- **1,000 < n < 2,000**: Either algorithm works
- **n > 2,000**: Use DMY for better performance
- **Multi-objective**: Use OptimShortestPaths regardless of size (no simple alternative)

## Running Your Own Benchmarks

### Quick Benchmark

```julia
using OptimShortestPaths
using BenchmarkTools

# Create test graph
n = 5000
edges = Edge[]
weights = Float64[]
for i in 1:n-1
    push!(edges, Edge(i, i+1, length(edges)+1))
    push!(weights, rand())
    if rand() < 0.5  # Add some shortcuts
        j = min(i + rand(2:100), n)
        push!(edges, Edge(i, j, length(edges)+1))
        push!(weights, rand(1.0:10.0))
    end
end

graph = DMYGraph(n, edges, weights)

# Benchmark DMY
@btime dmy_sssp!($graph, 1)
```

### Comprehensive Benchmark Suite

Run the full benchmark suite:

```bash
julia --project=. test/benchmark_performance.jl
```

This generates `benchmark_results.txt` with detailed timing data for various graph sizes.

## Multi-Objective Performance

Multi-objective optimization is inherently more expensive:

| Operation | Complexity | Notes |
|-----------|------------|-------|
| Single objective | O(m log^(2/3) n) | Standard DMY |
| Weighted sum | O(m log^(2/3) n) | Same as single |
| Pareto front | O(k · m log^(2/3) n) | k = Pareto set size |
| ε-constraint | O(d · m log^(2/3) n) | d = discretization steps |

### Pareto Front Size

The Pareto set can grow exponentially with:
- Number of objectives (2-3 manageable, 4+ slow)
- Graph structure (more paths = larger Pareto set)
- Objective correlation (conflicting objectives = more solutions)

**Recommendation**: Use `max_solutions` parameter to bound computation:

```julia
pareto_front = compute_pareto_front(graph, source, target; max_solutions=1000)
```

## Memory Usage

### Single-Objective DMY

- **Graph storage**: O(n + m)
- **Distance array**: O(n)
- **Frontier sets**: O(n) worst case
- **Total**: O(n + m)

### Multi-Objective Pareto

- **Graph storage**: O(d · (n + m)) where d = number of objectives
- **Solution storage**: O(k · p) where k = Pareto size, p = path length
- **Total**: O(d·(n+m) + k·p)

For n=1000, d=3, k=100, p=10: ≈ 10 KB (very efficient)

## Algorithm Details

The DMY algorithm uses:
- **FindPivots**: O(|U|) frontier sparsification
- **BMSSP**: O(k·B·m) bounded multi-source shortest path
- **Recursive decomposition**: O(log n) layers

These combine to achieve the O(m log^(2/3) n) bound.

## Reproducibility

All benchmark data is canonical and version-controlled:
- **Data file**: `benchmark_results.txt`
- **Generation script**: `test/benchmark_performance.jl`
- **Figures**: Generated from canonical data via `examples/comprehensive_demo/generate_figures.jl`

To reproduce benchmarks on your hardware:

```bash
julia --project=. test/benchmark_performance.jl > benchmark_results.txt
cd examples/comprehensive_demo
julia --project=. generate_figures.jl  # Regenerate with your data
```

## See Also

- [API Reference](api.md) for function signatures
- [Examples](examples.md) for usage patterns
- [GitHub Benchmarks](https://github.com/danielchen26/OptimShortestPaths.jl/blob/main/benchmark_results.txt) for raw data

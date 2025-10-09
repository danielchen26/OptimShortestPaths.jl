# Test Suite for DMY Shortest Path Algorithm

## Quick Start

Run all tests:
```bash
julia --project=. test/runtests.jl
```

Run specific test:
```bash
julia --project=. test/test_dmy_algorithm.jl
```

## Test Categories

### Core Algorithm Tests
- `test_core_types.jl` - Data structures (Edge, DMYGraph, Block)
- `test_graph_utils.jl` - Graph utilities and helpers
- `test_dmy_algorithm.jl` - Main DMY algorithm
- `test_bmssp.jl` - Bounded Multi-Source Shortest Path
- `test_pivot_selection.jl` - Frontier sparsification

### Application Tests
- `test_pharma_networks.jl` - Drug discovery and healthcare applications
- `test_multi_objective.jl` - Multi-objective Pareto optimization
- `test_pareto_simple.jl` - Simple Pareto front tests

### Validation Tests
- `test_correctness.jl` - Comparison with Dijkstra's algorithm
- `test_equal_paths.jl` - Path equivalence testing
- `test_utilities.jl` - Utility function validation

### Performance Tests
- `benchmark_performance.jl` - Comprehensive performance benchmarks
- `benchmark_simple.jl` - Quick performance validation

## Test Coverage

- **1,600+ assertions** exercising 100+ focused test sets (randomized sizes mean totals can vary)
- **100% coverage** of core algorithm components
- Multi-objective engines participate in the default test run
- All results validated against Dijkstra's algorithm
- Comprehensive edge case testing

## Documentation

For detailed test documentation, see [TEST_DOCUMENTATION.md](TEST_DOCUMENTATION.md)

## Running Individual Tests

Use the helper script:
```bash
julia --project=. test/run_single_test.jl test_name.jl
```

Or for minimal testing:
```bash
julia --project=. test/minimal_test.jl
```

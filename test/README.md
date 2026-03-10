# Test Suite for DMY Shortest Path Algorithm

## Quick Start

Run all tests:
```bash
julia --project=. test/runtests.jl
```

Run specific test:
```bash
julia --project=. test/run_single_test.jl test_dmy_algorithm.jl
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
- `test_documentation_examples.jl` - Executable documentation and example snippets

### Validation Tests
- `test_correctness.jl` - Comparison with Dijkstra's algorithm
- `test_utilities.jl` - Utility function validation

### Performance Tests
- `../dev/benchmark_performance.jl` - Benchmark generator used for published numbers

## Test Coverage

- **1,700+ assertions** covering core algorithms, domain wrappers, and documentation examples
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

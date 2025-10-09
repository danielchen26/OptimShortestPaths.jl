# Multi-Objective Optimization

OptimShortestPaths provides comprehensive support for multi-objective optimization through Pareto front computation.

## Overview

When you have multiple conflicting objectives (e.g., minimize cost AND minimize time), there's no single "best" solution. Instead, you need to find the **Pareto front** - the set of solutions where improving one objective requires sacrificing another.

## Computing the Pareto Front

### Basic Usage

```julia
using OptimShortestPaths

# Create multi-objective graph
edges = [MultiObjectiveEdge(1, 2, 1), MultiObjectiveEdge(2, 3, 2)]
objectives = [[1.0, 5.0], [2.0, 1.0]]  # [cost, time] for each edge

graph = MultiObjectiveGraph(3, edges, objectives)

# Compute Pareto front
pareto_solutions = compute_pareto_front(graph, 1, 3; max_solutions=1000)

# Each solution has:
for sol in pareto_solutions
    println("Objectives: ", sol.objectives)  # [total_cost, total_time]
    println("Path: ", sol.path)              # Vertex sequence
    println("Edges: ", sol.edges)            # Edge IDs
end
```

### Bounded Pareto Computation

To prevent exponential growth of the Pareto set:

```julia
pareto_solutions = compute_pareto_front(
    graph, source, target;
    max_solutions=1000  # Stop after 1000 solutions
)
```

## Scalarization Methods

### Weighted Sum Approach

Convert multiple objectives into a single weighted sum:

```julia
weights = [0.7, 0.3]  # 70% cost, 30% time
distance, path = weighted_sum_approach(graph, source, target, weights)
```

!!! warning "Minimization Only"
    `weighted_sum_approach` currently requires all objectives to be minimization (`:min`). Transform maximization objectives first.

### Epsilon-Constraint Method

Optimize one objective while constraining others:

```julia
# Minimize cost subject to: time ≤ 10.0
distance, path = epsilon_constraint_approach(
    graph, source, target,
    1,              # Objective index to minimize (cost)
    [Inf, 10.0]     # Constraints on objectives [cost, time]
)
```

### Lexicographic Optimization

Optimize objectives in priority order:

```julia
priorities = [1, 2]  # First minimize obj 1 (cost), then obj 2 (time)
distance, path = lexicographic_approach(graph, source, target, priorities)
```

## Decision Support

### Finding the Knee Point

The "knee point" offers the best trade-off between objectives:

```julia
pareto_solutions = compute_pareto_front(graph, source, target)

# Find solution with best trade-off
best_solution = get_knee_point(pareto_solutions)

println("Best trade-off: ", best_solution.objectives)
println("Path: ", best_solution.path)
```

The knee point maximizes the angle between solutions, representing the steepest change in the Pareto curve.

## Working with Objective Senses

### Minimization and Maximization

```julia
# Define mixed objectives
edges = [MultiObjectiveEdge(1, 2, 1)]
objectives = [[5.0, 8.0]]  # [cost_to_minimize, profit_to_maximize]

# Specify senses
graph = MultiObjectiveGraph(
    2, edges, objectives;
    objective_sense = [:min, :max]  # Minimize cost, maximize profit
)

# Pareto front respects both senses
pareto_front = compute_pareto_front(graph, 1, 2)
```

### Converting Maximization to Minimization

For scalarization methods that require `:min`:

```julia
# Original: maximize profit
# Transform: minimize negative profit

original_profit = 100.0
minimization_objective = -original_profit

# Or subtract from baseline
baseline = 1000.0
minimization_objective = baseline - original_profit
```

## Example: Cost-Time Trade-off

```julia
using OptimShortestPaths

# Supply chain network: minimize cost AND time
edges = [
    MultiObjectiveEdge(1, 2, 1),
    MultiObjectiveEdge(1, 3, 2),
    MultiObjectiveEdge(2, 4, 3),
    MultiObjectiveEdge(3, 4, 4)
]

# [cost, time] for each edge
objectives = [
    [10.0, 1.0],  # Cheap but slow
    [30.0, 0.5],  # Expensive but fast
    [5.0, 2.0],   # Cheap and slow
    [15.0, 1.0]   # Moderate
]

graph = MultiObjectiveGraph(4, edges, objectives)

# Find all Pareto-optimal paths
pareto_front = compute_pareto_front(graph, 1, 4)

println("Found ", length(pareto_front), " Pareto-optimal solutions:")
for (i, sol) in enumerate(pareto_front)
    println("  $i. Cost: $(sol.objectives[1]), Time: $(sol.objectives[2])")
end

# Select best trade-off
best = get_knee_point(pareto_front)
println("\nBest trade-off: Cost=$(best.objectives[1]), Time=$(best.objectives[2])")
```

## Performance Considerations

- **Pareto set size**: Can grow exponentially; use `max_solutions` to bound it
- **Number of objectives**: 2-3 objectives typical; 4+ can be slow
- **Graph size**: Pareto computation is slower than single-objective
- **Dominated solutions**: Automatically filtered during computation

## See Also

- [API Reference - Multi-Objective](../api.md#Multi-Objective-Optimization)
- [Examples](../examples.md) for more complex scenarios

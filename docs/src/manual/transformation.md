# Problem Transformation

The core innovation of OptimShortestPaths is transforming arbitrary optimization problems into shortest-path problems.

## The Transformation Framework

### Step 1: Identify States

Map your problem's **decision points** or **configurations** to graph **vertices**.

**Examples**:
- Scheduling: Time slots × resources × task states
- Portfolio: Asset allocation configurations
- Treatment: Patient health states

### Step 2: Define Transitions

Map **valid actions** or **state changes** to directed **edges**.

**Examples**:
- Scheduling: Assigning a task to a resource
- Portfolio: Buying/selling an asset
- Treatment: Applying a specific treatment

### Step 3: Quantify Costs

Transform **objectives** into non-negative edge **weights**.

**Examples**:
- Time to complete
- Financial cost
- Risk score (must be ≥ 0)

### Step 4: Solve as Shortest Path

Run the DMY algorithm to find optimal solutions.

## Using the Transformation API

### High-Level Interface

```julia
# Define your problem
problem = OptimizationProblem(
    :drug_discovery,           # Problem type
    (drugs, targets, affinities),  # Problem data
    1                          # Source vertex
)

# Solve automatically
distances = optimize_to_graph(problem; solver=:dmy)
```

### Manual Casting

```julia
# For custom problems
function my_custom_cast(data)
    # Extract problem-specific data
    entities, transitions, costs = data

    # Build edges
    edges = Edge[]
    weights = Float64[]
    for (i, (from, to, cost)) in enumerate(transitions)
        push!(edges, Edge(from, to, i))
        push!(weights, cost)
    end

    # Create graph
    n_vertices = length(entities)
    return DMYGraph(n_vertices, edges, weights)
end

# Use it
graph = my_custom_cast(my_data)
distances = dmy_sssp!(graph, source)
```

## Domain-Agnostic Examples

### Resource Scheduling

```julia
# States: Time slots (1-24) × Resources (A, B, C)
# Edges: Task assignments
# Weights: Completion time + setup cost

n_time_slots = 24
n_resources = 3
n_vertices = n_time_slots * n_resources

# Create edges for valid task assignments
edges = Edge[]
weights = Float64[]

for t in 1:(n_time_slots-1)
    for r1 in 1:n_resources
        for r2 in 1:n_resources
            from_vertex = (t-1)*n_resources + r1
            to_vertex = t*n_resources + r2

            completion_time = 1.0
            setup_cost = r1 == r2 ? 0.0 : 2.0  # Penalty for resource change

            push!(edges, Edge(from_vertex, to_vertex, length(edges)+1))
            push!(weights, completion_time + setup_cost)
        end
    end
end

graph = DMYGraph(n_vertices, edges, weights)
```

### Network Flow

```julia
# States: Network nodes
# Edges: Links with capacity constraints
# Weights: Latency + congestion cost

# Transform max-flow to shortest path by:
# 1. Invert capacity: weight = 1/capacity
# 2. Add congestion penalty
# 3. Find min-cost path

function capacity_to_weight(capacity, current_flow)
    congestion = current_flow / capacity
    return 1/capacity + 10.0 * congestion^2
end
```

## Key Constraints

!!! warning "Non-Negative Weights Required"
    The DMY algorithm requires **all edge weights ≥ 0**. Transform maximization objectives:
    - Revenue → Cost: `weight = -revenue + baseline`
    - Probability → Distance: `weight = -log(probability)`
    - Similarity → Distance: `weight = 1 - similarity`

!!! info "Directed Graphs Only"
    All graphs must be directed. For undirected graphs, add edges in both directions.

## See Also

- [Multi-Objective Optimization](multiobjective.md) for handling multiple objectives
- [Domain Applications](domains.md) for pre-built transformation helpers
- [API Reference](../api.md) for complete function documentation

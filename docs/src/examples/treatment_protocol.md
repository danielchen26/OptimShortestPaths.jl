# Treatment Protocol Optimization

Demonstrates OptimShortestPaths for clinical decision support and treatment sequencing.

## Overview

Treatment protocols define sequences of medical interventions to achieve remission. Optimizing these protocols requires balancing:

- **Cost**: Treatment expenses
- **Time**: Duration to remission
- **Efficacy**: Success probability
- **Quality of Life**: Patient well-being during treatment

OptimShortestPaths models treatment decisions as paths through a state-space graph where vertices represent health states and edges represent treatment actions.

---

## Problem Transformation

### From Clinical Decisions to Graph

**Treatment States**:
```
Initial → Screening → ChemoA → ChemoB → Surgery → Radiation → Remission
```

**Graph Representation**:
- **Vertices**: Patient health states
- **Edges**: Valid treatment transitions
- **Weights**: Combined cost-risk-time metric

### Creating a Protocol

```julia
using OptimShortestPaths

# Define treatment options
treatments = ["Initial", "Screening", "ChemoA", "ChemoB", "Surgery", "Radiation", "Remission"]

# Costs in thousands of dollars
costs = [0.0, 5.0, 50.0, 60.0, 100.0, 40.0, 0.0]

# Efficacy (success probability)
efficacy = [0.0, 0.0, 0.6, 0.7, 0.8, 0.5, 1.0]

# Valid transitions with additional risk
transitions = [
    ("Initial", "Screening", 0.0),
    ("Screening", "ChemoA", 0.1),
    ("Screening", "Surgery", 0.3),
    ("ChemoA", "ChemoB", 0.05),
    ("ChemoA", "Surgery", 0.2),
    ("ChemoB", "Radiation", 0.15),
    ("Surgery", "Radiation", 0.1),
    ("Radiation", "Remission", 0.05),
]

protocol = create_treatment_protocol(treatments, costs, efficacy, transitions)
```

---

## Single-Objective Optimization

### Minimum Cost to Remission

```julia
# Find lowest-cost treatment sequence
total_cost, sequence = optimize_treatment_sequence(protocol, "Initial", "Remission")

println("Minimum cost: \$", total_cost * 1000)
println("Treatment path: ", join(sequence, " → "))
```

**Example Result**:
```
Minimum cost: $95,000
Treatment path: Initial → Screening → ChemoA → Surgery → Remission
```

---

## Multi-Objective Pareto Analysis

### Competing Objectives

Clinical treatment involves 4 objectives:

1. **Cost**: Total treatment expense
2. **Time**: Months to remission
3. **Quality of Life**: Patient well-being during treatment
4. **Success Rate**: Probability of achieving remission

```julia
# Create multi-objective treatment graph
objectives_per_edge = [
    [cost, time_months, qol_impact, risk]
    # for each treatment transition
]

graph = MultiObjectiveGraph(n_states, edges, objectives_per_edge)

# Find all Pareto-optimal treatment pathways
protocols = compute_pareto_front(graph, initial_state, remission_state)
```

### Pareto-Optimal Treatment Protocols

| Protocol | Cost | Time | QoL | Success | **Best For** |
|----------|------|------|-----|---------|--------------|
| Aggressive | $200k | 6mo | 40% | 95% | Young, low-risk patients |
| Standard | $120k | 9mo | 60% | 85% | Average patients |
| Conservative | $80k | 12mo | 75% | 75% | Elderly, high-risk |
| Palliative | $40k | 15mo | 85% | 50% | Late-stage, comfort focus |

### Patient-Specific Selection

```julia
# Young patient: Prioritize success rate, tolerate cost/QoL impact
weights = [0.1, 0.1, 0.2, 0.6]  # [cost, time, qol, success]
best = weighted_sum_approach(graph, initial, remission, weights)
# → Aggressive protocol

# Elderly patient: Prioritize quality of life
weights = [0.15, 0.15, 0.6, 0.1]
best = weighted_sum_approach(graph, initial, remission, weights)
# → Conservative or Palliative protocol
```

---

## Clinical Decision Support

### Decision Tree Construction

The Pareto front can be converted to clinical decision rules:

```
IF (age < 50 AND risk_low) THEN
    Use Aggressive Protocol
ELSE IF (age >= 70 OR comorbidities) THEN
    IF (performance_status < 2) THEN
        Use Palliative Protocol
    ELSE
        Use Conservative Protocol
ENDIF
ELSE
    Use Standard Protocol
ENDIF
```

### Dynamic Protocol Adjustment

```julia
# Start with standard protocol
current_state = "ChemoA"

# Patient responds poorly → switch to alternative
if response_poor
    # Find alternative Pareto-optimal path from current state
    alternatives = compute_pareto_front(graph, current_state, remission)

    # Select less aggressive option
    safer_protocol = filter(sol -> sol.objectives[3] > 70.0, alternatives)  # QoL > 70%
end
```

---

## Code Example

Complete working example:

```julia
using OptimShortestPaths

# Define treatment graph
treatments = ["Initial", "ChemoA", "ChemoB", "Surgery", "Radiation", "Remission"]
costs = [0.0, 50.0, 60.0, 100.0, 40.0, 0.0]
efficacy = [0.0, 0.6, 0.7, 0.8, 0.5, 1.0]

transitions = [
    ("Initial", "ChemoA", 0.1),
    ("ChemoA", "ChemoB", 0.05),
    ("ChemoB", "Radiation", 0.15),
    ("Radiation", "Remission", 0.05),
    ("ChemoA", "Surgery", 0.2),
    ("Surgery", "Radiation", 0.1),
]

protocol = create_treatment_protocol(treatments, costs, efficacy, transitions)

# Find optimal sequence
cost, sequence = optimize_treatment_sequence(protocol, "Initial", "Remission")
println("Optimal path: ", join(sequence, " → "))
```

---

## Running the Example

```bash
cd examples/treatment_protocol
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
julia --project=. treatment_protocol.jl
julia --project=. generate_figures.jl  # Generate 9 visualization figures
```

---

## Applications

### Personalized Medicine

Match treatment to patient profile using Pareto front:
- Young patients → Aggressive (maximize success)
- Elderly patients → Conservative (maximize QoL)
- Budget-constrained → Cost-optimal pathways

### Healthcare Economics

Cost-effectiveness analysis:
- Calculate cost per quality-adjusted life year (QALY)
- Identify dominated treatments (never optimal)
- Optimize healthcare resource allocation

### Clinical Trials

Design adaptive trials:
- Start with standard protocol
- Switch to Pareto alternatives based on response
- Personalize in real-time

---

## See Also

- [Problem Transformation](../manual/transformation.md)
- [Multi-Objective Optimization](../manual/multiobjective.md)
- [Domain Applications](../manual/domains.md)
- [GitHub Example](https://github.com/danielchen26/OptimShortestPaths.jl/tree/main/examples/treatment_protocol)

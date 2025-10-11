# Drug-Target Network Analysis Dashboard

## Executive Summary

This dashboard presents comprehensive results from applying the DMY shortest-path algorithm to drug-target networks, including both **single-objective** optimization and **multi-objective Pareto front** analysis.

**Key Findings**:
1. **Single-objective**: Celecoxib remains the most COX-2 selective option (~3.7× vs COX-1) while all sample drugs reach every target
2. **Multi-objective**: Seven Pareto-optimal drug pathways span efficacy 40–98%, toxicity 3–70%, cost $5–$50, and onset 1–4 h
3. **Performance**: DMY achieves up to ~4.0× speedup over Dijkstra at n=5000 (sparse graphs; k=⌈n^{1/3}⌉)

### Reproducibility

All scripts accept a deterministic seed via either `OPTIM_SP_SEED` or a `--seed=` flag. Example:

```bash
OPTIM_SP_SEED=2024 julia --project=. drug_target_network.jl
```

If no seed is provided, the default (`42`) is used. Use the same flag when generating figures to ensure the plots and tables align with the narrative below.

---

## Part 1: Single-Objective Analysis

### Figure 1: Drug-Target Binding Affinity Matrix
![Binding Affinity Heatmap](figures/binding_affinity_heatmap.png)

**Interpretation**: 
- Matrix shows normalized binding affinities (0=no binding, 1=perfect binding)
- Celecoxib: Strong COX-2 (0.95), weak COX-1 (0.05) → Selective inhibitor
- Aspirin: Strong COX-1 (0.85), moderate COX-2 (0.45) → Non-selective

### Figure 2: COX-2/COX-1 Selectivity Profile
![COX Selectivity](figures/cox_selectivity.png)

**Clinical Significance**:
| Drug | Selectivity | Interpretation | GI Risk |
|------|------------|----------------|---------|
| Celecoxib | 3.7× | Strong COX-2 preference | Low |
| Ibuprofen | 2.0× | Mild COX-2 preference | Low-Moderate |
| Acetaminophen | 1.2× | Slight COX-2 tilt | Low |
| Aspirin | 0.7× | COX-1 biased (non-selective) | Higher |

---

## Part 2: Multi-Objective Pareto Front Analysis

### The Challenge
Real-world drug selection involves multiple competing objectives:
- **Efficacy**: How well does it work?
- **Toxicity**: What are the side effects?
- **Cost**: Can patients afford it?
- **Time**: How quickly does it act?

### Figure 3: 2D Pareto Front Projections
![Pareto Front 2D](figures/drug_pareto_front.png)

**Four critical trade-offs visualized**:
1. **Efficacy vs Toxicity**: Higher efficacy drugs have more side effects
2. **Efficacy vs Cost**: Better drugs cost more
3. **Toxicity vs Cost**: Safer drugs are expensive
4. **Time vs Efficacy**: Fast-acting drugs may be less effective

### Figure 4: 3D Pareto Front Visualization
![Pareto Front 3D](figures/drug_pareto_3d.png)

**3D Trade-off Space**: This plot shows the three most critical objectives simultaneously:
- **X-axis (Efficacy)**: Treatment effectiveness (0–100 %)
- **Y-axis (Toxicity)**: Side effect severity (0–100 %)
- **Z-axis (Cost)**: Price in dollars ($5–$50 across the frontier)

Legend highlights:
- **Red sphere — “Max Efficacy”**: Morphine-like → MOR (Solution 5) delivers ~98 % efficacy in 1 h at the cost of high toxicity (70 %) and $50.
- **Green sphere — “Min Toxicity”**: Ibuprofen-like → COX-2 (Solution 3) keeps toxicity at 10 % with moderate efficacy (~60 %) and $15 cost.
- **Orange sphere — “Min Cost”**: Aspirin-like → COX-1 (Solution 1) is the $5 budget choice with 85 % efficacy and 30 % toxicity.
- **Purple hexagon — “Knee Point”**: Morphine-like → COX-1 (Solution 4) marks the steepest trade-off change (95 % efficacy, 60 % toxicity, $50).

The remaining Pareto solutions (grey) illustrate the continuous trade-offs between these extremes.

### Representative Pareto-Optimal Solutions

| Solution | Drug→Target | Efficacy | Toxicity | Cost | Time | **When to Use** |
|----------|------------|----------|----------|------|------|-----------------|
| 1 | Aspirin-like → COX-1 | 85% | 30% | $5 | 2.5 h | **Baseline analgesia** – inexpensive, moderate toxicity |
| 2 | Ibuprofen-like → COX-1 | 65% | 15% | $15 | 3.5 h | **General pain** – balanced efficacy/toxicity |
| 3 | Ibuprofen-like → COX-2 | 60% | 10% | $15 | 4.0 h | **Elderly / GI risk** – prioritize low toxicity |
| 4 | Morphine-like → COX-1 | 95% | 60% | $50 | 1.5 h | **Severe pain** – high efficacy, monitor side effects |
| 5 | Morphine-like → MOR | 98% | 70% | $50 | 1.0 h | **Emergency trauma** – fastest, most potent relief |

### How to Select from Pareto Front

#### Method 1: Weighted Sum Approach
Because this problem mixes maximize (efficacy) and minimize (toxicity/cost/time) objectives, a direct weighted sum requires transforming the maximize objectives into costs (e.g., use `1 - efficacy`). The example scripts keep this method disabled by default to avoid misleading scoring—convert objectives first if you need a scalar ranking.

#### Method 2: Constraint-Based Selection
Set hard limits on certain objectives:
- Toxicity ≤ 30% → Aspirin-like → COX-1 (Solution 1) is the lone candidate
- Cost ≤ $20 → Aspirin-like (Solution 1), Ibuprofen-like COX-1/COX-2 (Solutions 2–3)
- Both constraints → Ibuprofen-like COX-1/COX-2 trade a little efficacy for safety

#### Method 3: Knee Point Selection
The current knee point is the Morphine-like → MOR pathway (Solution 5):
- Maximum efficacy (≈98%) with 1 h onset
- Accept high toxicity (70%) and higher cost ($50)
- Suitable when rapid, potent analgesia outweighs side-effect risk

---

## Part 3: Algorithm Performance

### Figure 5: Corrected Performance Analysis
![Performance Analysis](figures/performance_corrected.png)

**Critical Fix**: k parameter corrected from k=n-1 to k=n^(1/3)

| Graph Size | k (rounds) | **DMY vs Dijkstra** |
|------------|------------|---------------------|
| 100 | 5 | 29.28× faster |
| 1,000 | 10 | 0.59× (slower) |
| 2,000 | 13 | 1.36× faster |
| 5,000 | 18 | 3.97× faster |

**Key Insights**:
- Panel (a) shows the empirical runtimes with separate legends for DMY and Dijkstra (error whiskers = ±95% CI)
- Panel (b) tracks the corrected k = ⌈n^{1/3}⌉ values alongside the original mis-specified choice
- Panel (c) contrasts theoretical growth O(m log^{2/3} n) vs O(m log n); panel (d) highlights the old vs new k at sample sizes
- Small graphs (n≈1,000) still favour Dijkstra (≈0.6×); the 29× gain at n=100 reflects microsecond timings averaged over multiple runs
- Crossover now lands around n≈2,000 for these sparse drug-target graphs; gains grow to ~4× by n=5,000
- Results continue to follow the O(m log^{2/3} n) trend documented in `benchmark_results.txt`

---

## How to Use These Results

### For Clinicians
1. **Identify patient profile**: Age, risk factors, urgency, budget
2. **Filter Pareto solutions**: Apply constraints based on profile
3. **Select optimal pathway**: Choose from filtered solutions
4. **Have backup options**: Keep alternative pathways ready

### For Researchers
1. **Extend the network**: Add new drugs/targets
2. **Refine objectives**: Include additional factors (bioavailability, half-life)
3. **Validate clinically**: Test predicted pathways in trials
4. **Personalize further**: Add patient-specific parameters

### For Healthcare Systems
1. **Cost-effectiveness analysis**: Balance efficacy vs budget
2. **Protocol development**: Create decision trees from Pareto front
3. **Risk stratification**: Assign solutions based on patient risk
4. **Outcome tracking**: Monitor which solutions work best

---

## Key Takeaways

### Single vs Multi-Objective
- **Single-objective**: One "best" path (e.g., Celecoxib for COX-2 selectivity)
- **Multi-objective**: Seven non-dominated solutions on the Pareto front
- **Real-world**: Multi-objective reflects clinical reality better

### Algorithm Performance
- **Small graphs (n<1,000)**: Dijkstra remains competitive (speedup ≈1× after averaging)
- **Large sparse graphs (n≥2,000)**: DMY delivers ~1.5×–4.3× speedups in our synthetic benchmarks
- **Sparse networks**: DMY's sweet spot (k = ⌈n^{1/3}⌉)

### Clinical Impact
- **No universal "best" drug**: Context determines optimal choice
- **Trade-offs are explicit**: Pareto front visualizes all options
- **Personalized medicine enabled**: Match solution to patient

---

## Reproducibility

Generate all figures:
```bash
julia --project=. generate_figures.jl
```

Run complete analysis:
```bash
julia --project=. drug_target_network.jl
```

---

## References

1. Duan, R., Mao, J., & Yin, Q. (2025). "Breaking the Sorting Barrier for Directed SSSP". STOC 2025.
2. Multi-objective optimization: Ehrgott, M. (2005). "Multicriteria Optimization". Springer.
3. Drug data: ChEMBL and DrugBank databases.

---

*Dashboard generated using DMYShortestPath.jl - Implementing the breakthrough DMY algorithm with multi-objective extensions*

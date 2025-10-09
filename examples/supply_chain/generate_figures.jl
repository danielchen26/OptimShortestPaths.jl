# Supply Chain Figures Generator
#
# Generates the figures described in examples/supply_chain/README.md:
# 1) figures/network_topology.png
# 2) figures/optimal_flows.png
# 3) figures/cost_analysis.png
#
# This script constructs a layered supply chain network (Factories → Warehouses →
# Distribution Centers → Customers), assigns transport costs based on Euclidean
# distance with noise, adds per-unit production costs via a super-source, and
# then uses OptimSPath DMY shortest paths to compute optimal paths for each customer.
#
# Requirements: using the supply_chain Project.toml (Plots, Colors) and OptimSPath.

using Random
using Plots
using Colors
using OptimSPath
using Statistics

# Palette (10 colors)
const COLORS = [
    RGB(0.20,0.40,0.80), RGB(0.90,0.50,0.20), RGB(0.20,0.70,0.30), RGB(0.80,0.20,0.50),
    RGB(0.20,0.70,0.70), RGB(0.60,0.30,0.80), RGB(0.85,0.40,0.30), RGB(0.35,0.60,0.90),
    RGB(0.60,0.60,0.20), RGB(0.30,0.30,0.30)
]

# Ensure output directory exists (relative to this example directory)
const FIG_DIR = joinpath(@__DIR__, "figures")
mkpath(FIG_DIR)

# Seed for reproducibility
Random.seed!(42)

# -----------------------------
# Network construction
# -----------------------------
# Index map:
# 1: super source
# 2..4: factories (3)
# 5..8: warehouses (4)
# 9..13: distribution centers (5)
# 14..23: customers (10)

const SUPER_SRC = 1
const FACTORIES = 2:4
const WAREHOUSES = 5:8
const DCS = 9:13
const CUSTOMERS = 14:23

# Coordinates for plotting (simple grid layout)
coords = Dict{Int,Tuple{Float64,Float64}}()
# Factories (left)
for (i,y) in zip(FACTORIES, (8.0, 5.0, 2.0))
    coords[i] = (1.0, y)
end
# Warehouses (center-left)
for (i,y) in zip(WAREHOUSES, (9.0, 7.0, 5.0, 3.0))
    coords[i] = (4.0, y)
end
# Distribution centers (center-right)
for (i,y) in zip(DCS, (9.0, 7.0, 5.0, 3.0, 1.0))
    coords[i] = (7.0, y)
end
# Customers (right) - spread vertically
ys = range(9.5, 0.5, length=length(CUSTOMERS))
for (i,y) in zip(CUSTOMERS, ys)
    coords[i] = (10.0, y)
end
# Super source (off to the left, not drawn)
coords[SUPER_SRC] = (0.0, 5.0)

# Per-unit production costs for factories (used as super-source edges)
production_cost = Dict(FACTORIES[1] => 50.0, FACTORIES[2] => 45.0, FACTORIES[3] => 55.0)

# Helper: Euclidean distance
_euclid(a::Tuple{Float64,Float64}, b::Tuple{Float64,Float64}) = sqrt((a[1]-b[1])^2 + (a[2]-b[2])^2)

# Transport cost model: base + distance factor + small noise
function transport_cost(i::Int, j::Int)
    dij = _euclid(coords[i], coords[j])
    base = 3.0
    factor = 2.0
    noise = 0.5 * rand()
    return base + factor * dij + noise
end

# Build graph edges and weights
edges = OptimSPath.Edge[]
weights = Float64[]

# Super source → Factories (production cost)
for f in FACTORIES
    push!(edges, OptimSPath.Edge(SUPER_SRC, f, length(edges)+1))
    push!(weights, production_cost[f])
end

# Factories → Warehouses
for f in FACTORIES, w in WAREHOUSES
    push!(edges, OptimSPath.Edge(f, w, length(edges)+1))
    push!(weights, transport_cost(f, w))
end

# Warehouses → DCs
for w in WAREHOUSES, d in DCS
    push!(edges, OptimSPath.Edge(w, d, length(edges)+1))
    push!(weights, transport_cost(w, d))
end

# DCs → Customers
for d in DCS, c in CUSTOMERS
    push!(edges, OptimSPath.Edge(d, c, length(edges)+1))
    push!(weights, transport_cost(d, c))
end

n_vertices = maximum(keys(coords))
G = OptimSPath.DMYGraph(n_vertices, edges, weights)

# -----------------------------
# Shortest paths from super source
# -----------------------------
# Use parents to reconstruct optimal paths to each customer
D, parent = OptimSPath.dmy_sssp_with_parents!(G, SUPER_SRC)

# Reconstruct path from source to a target node
function reconstruct_path(parent::Vector{Int}, target::Int)
    path = Int[]
    v = target
    while v != 0 && v != SUPER_SRC
        push!(path, v)
        v = parent[v]
    end
    if v == SUPER_SRC
        push!(path, SUPER_SRC)
        reverse!(path)
        return path
    else
        return Int[]  # no path
    end
end

# Determine assigned factory for each customer (first hop after super source)
customer_paths = Dict{Int,Vector{Int}}()
assigned_factory = Dict{Int,Int}()
for c in CUSTOMERS
    p = reconstruct_path(parent, c)
    if !isempty(p)
        customer_paths[c] = p
        # p looks like [SUPER_SRC, F, W, D, C]
        f = length(p) >= 2 ? p[2] : 0
        assigned_factory[c] = f
    end
end

# Aggregate edge usage counts for visualization thickness
edge_use = Dict{Tuple{Int,Int}, Int}()
global transport_cost_total = 0.0
global production_cost_total = 0.0
for c in keys(customer_paths)
    p = customer_paths[c]
    # Sum costs along path and split production vs transport
    cost_prod = 0.0
    cost_trans = 0.0
    for k in 1:length(p)-1
        u, v = p[k], p[k+1]
        # Find the edge index (graph is small; linear search acceptable here)
        idx = findfirst(e -> e.source == u && e.target == v, edges)
        if idx === nothing
            continue
        end
        w = weights[idx]
        if u == SUPER_SRC
            cost_prod += w
        else
            cost_trans += w
        end
        edge_use[(u,v)] = get(edge_use, (u,v), 0) + 1
    end
    global production_cost_total += cost_prod
    global transport_cost_total += cost_trans
end

# Customers per factory assignment count
factory_assign_counts = [count(v -> v == f, values(assigned_factory)) for f in FACTORIES]

# -----------------------------
# Figure 1: Network Topology
# -----------------------------
p1 = plot(size=(1200, 800), dpi=300, title="Supply Chain Network Topology",
          xlabel="", ylabel="", legend=false)
# Draw all layer edges lightly (exclude super source)
for e in edges
    (e.source == SUPER_SRC) && continue
    x1, y1 = coords[e.source]
    x2, y2 = coords[e.target]
    plot!(p1, [x1, x2], [y1, y2], color=:gray80, alpha=0.6, lw=1.2)
end

# Draw nodes with different colors by type
scatter!(p1, [coords[i][1] for i in FACTORIES], [coords[i][2] for i in FACTORIES],
         ms=14, color=COLORS[1], markerstrokewidth=2, markerstrokecolor=:white, label="")
annotate!(p1, mean([coords[i][1] for i in FACTORIES]), 9.7, text("Factories", 10, COLORS[1]))

scatter!(p1, [coords[i][1] for i in WAREHOUSES], [coords[i][2] for i in WAREHOUSES],
         ms=12, color=COLORS[2], markerstrokewidth=2, markerstrokecolor=:white, label="")
annotate!(p1, 4.0, 10.2, text("Warehouses", 10, COLORS[2]))

scatter!(p1, [coords[i][1] for i in DCS], [coords[i][2] for i in DCS],
         ms=12, color=COLORS[3], markerstrokewidth=2, markerstrokecolor=:white, label="")
annotate!(p1, 7.0, 10.2, text("Distribution Centers", 10, COLORS[3]))

scatter!(p1, [coords[i][1] for i in CUSTOMERS], [coords[i][2] for i in CUSTOMERS],
         ms=10, color=COLORS[4], markerstrokewidth=2, markerstrokecolor=:white, label="")
annotate!(p1, 10.0, 10.2, text("Customers", 10, COLORS[4]))

# Optional labels on nodes
for i in FACTORIES
    annotate!(p1, coords[i][1], coords[i][2]+0.35, text("F$(i-1)", 9, :white))
end
for (k,i) in enumerate(WAREHOUSES)
    annotate!(p1, coords[i][1], coords[i][2]+0.35, text("W$k", 9, :white))
end
for (k,i) in enumerate(DCS)
    annotate!(p1, coords[i][1], coords[i][2]+0.35, text("D$k", 9, :white))
end
for (k,i) in enumerate(CUSTOMERS)
    annotate!(p1, coords[i][1], coords[i][2]+0.35, text("C$k", 8))
end

savefig(p1, joinpath(FIG_DIR, "network_topology.png"))
println("✓ Saved: $(joinpath(FIG_DIR, "network_topology.png"))")

# -----------------------------
# Figure 2: Optimal Flows (highlight selected paths)
# -----------------------------
p2 = plot(size=(1200, 800), dpi=300, title="Optimal Flows to Customers",
          xlabel="", ylabel="", legend=false)
# Draw faint edges (exclude super source)
for e in edges
    (e.source == SUPER_SRC) && continue
    x1, y1 = coords[e.source]
    x2, y2 = coords[e.target]
    plot!(p2, [x1, x2], [y1, y2], color=:gray85, alpha=0.5, lw=1.0)
end

# Highlight used edges proportional to usage
for ((u,v), cnt) in edge_use
    (u == SUPER_SRC) && continue
    x1, y1 = coords[u]
    x2, y2 = coords[v]
    lw = 1.5 + 0.8 * cnt
    plot!(p2, [x1, x2], [y1, y2], color=COLORS[5], alpha=0.8, lw=lw)
end

# Draw nodes, color factories distinct by assignment
factory_colors = Dict(FACTORIES[1]=>COLORS[1], FACTORIES[2]=>COLORS[2], FACTORIES[3]=>COLORS[3])

# Customers colored by their assigned factory
cust_colors = [factory_colors[get(assigned_factory, c, FACTORIES[1])] for c in CUSTOMERS]

scatter!(p2, [coords[i][1] for i in FACTORIES], [coords[i][2] for i in FACTORIES],
         ms=14, color=[factory_colors[i] for i in FACTORIES], markerstrokewidth=2, markerstrokecolor=:white)
scatter!(p2, [coords[i][1] for i in WAREHOUSES], [coords[i][2] for i in WAREHOUSES],
         ms=10, color=:white, markerstrokewidth=2, markerstrokecolor=:gray50)
scatter!(p2, [coords[i][1] for i in DCS], [coords[i][2] for i in DCS],
         ms=10, color=:white, markerstrokewidth=2, markerstrokecolor=:gray50)
scatter!(p2, [coords[i][1] for i in CUSTOMERS], [coords[i][2] for i in CUSTOMERS],
         ms=9, color=cust_colors, markerstrokewidth=1.5, markerstrokecolor=:white)

# Legend-like annotations
annotate!(p2, 2.2, 10.2, text("Factories", 10, :left))
annotate!(p2, 2.0, 9.7, text("F1, F2, F3", 9, :left))
annotate!(p2, 9.4, 10.2, text("Customers colored by assigned Factory", 10, :right))

savefig(p2, joinpath(FIG_DIR, "optimal_flows.png"))
println("✓ Saved: $(joinpath(FIG_DIR, "optimal_flows.png"))")

# -----------------------------
# Figure 3: Cost Analysis
# -----------------------------
# Derive totals and summaries
n_cust = length(CUSTOMERS)
assigned = [get(assigned_factory, c, FACTORIES[1]) for c in CUSTOMERS]

p3 = plot(layout=(2,2), size=(1300, 900), dpi=300)

# Subplot 1: Customers per Factory
bar!(p3, 1:3, factory_assign_counts, subplot=1, color=[COLORS[1], COLORS[2], COLORS[3]],
     xlabel="Factory", ylabel="# Customers", xticks=(1:3, ["F1","F2","F3"]),
     title="Customer Allocation by Factory")

# Subplot 2: Cost breakdown (Production vs Transport)
bar!(p3, ["Production","Transport"], [production_cost_total, transport_cost_total], subplot=2,
     color=[COLORS[6], COLORS[7]], title="Total Cost Breakdown", legend=false)

# Subplot 3: Histogram of per-customer total path costs
cust_total_costs = Float64[]
for c in CUSTOMERS
    p = get(customer_paths, c, Int[])
    if isempty(p)
        push!(cust_total_costs, NaN)
        continue
    end
    # sum along path
    ct = 0.0
    for k in 1:length(p)-1
        u, v = p[k], p[k+1]
        idx = findfirst(e -> e.source == u && e.target == v, edges)
        if idx !== nothing
            ct += weights[idx]
        end
    end
    push!(cust_total_costs, ct)
end
cust_total_costs = filter(!isnan, cust_total_costs)

histogram!(p3, cust_total_costs, bins=10, color=COLORS[8], alpha=0.8, subplot=3,
           xlabel="Total Cost per Customer", ylabel="Count", title="Path Cost Distribution")

# Subplot 4: Summary text (fixed to avoid overlap)
plot!(p3, subplot=4, showaxis=false, grid=false, xlims=(0,1), ylims=(0,1), framestyle=:none)

# Add summary statistics as individual annotations
annotate!(p3, 0.5, 0.95, text("Supply Chain Cost Summary", 12, :bold, :center), subplot=4)
annotate!(p3, 0.05, 0.80, text("Customers served: $(length(cust_total_costs)) / $(n_cust)", 10, :left), subplot=4)
annotate!(p3, 0.05, 0.70, text("Avg path cost: \$$(round(mean(cust_total_costs), digits=2))", 10, :left), subplot=4)
annotate!(p3, 0.05, 0.60, text("Production cost: \$$(round(production_cost_total, digits=2))", 10, :left), subplot=4)
annotate!(p3, 0.05, 0.50, text("Transport cost: \$$(round(transport_cost_total, digits=2))", 10, :left), subplot=4)
prod_pct = round(100*production_cost_total/(production_cost_total+transport_cost_total),digits=1)
trans_pct = round(100*transport_cost_total/(production_cost_total+transport_cost_total),digits=1)
annotate!(p3, 0.05, 0.40, text("Cost split: $(prod_pct)% production / $(trans_pct)% transport", 10, :left), subplot=4)
annotate!(p3, 0.05, 0.25, text("Algorithm: OptimSPath DMY", 10, :italic, :left), subplot=4)

savefig(p3, joinpath(FIG_DIR, "cost_analysis.png"))
println("✓ Saved: $(joinpath(FIG_DIR, "cost_analysis.png"))")

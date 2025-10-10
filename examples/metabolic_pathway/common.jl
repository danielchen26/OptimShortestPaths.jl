# Shared data and helper functions for the metabolic pathway example and figures

using OptimShortestPaths
using OptimShortestPaths.MultiObjective

const METABOLITES = [
    "Glucose",           # Starting sugar
    "Glucose-6-P",       # G6P
    "Fructose-6-P",      # F6P
    "Fructose-1,6-BP",   # F1,6BP
    "DHAP",              # Dihydroxyacetone phosphate
    "G3P",               # Glyceraldehyde-3-phosphate
    "1,3-BPG",           # 1,3-bisphosphoglycerate
    "3-PG",              # 3-phosphoglycerate
    "2-PG",              # 2-phosphoglycerate
    "PEP",               # Phosphoenolpyruvate
    "Pyruvate",          # End product of glycolysis
    "Lactate",           # Anaerobic product
    "Acetyl-CoA",        # TCA cycle entry
    "Citrate",           # TCA cycle
    "α-Ketoglutarate",   # TCA cycle
    "Succinate",         # TCA cycle
    "Oxaloacetate"       # TCA cycle
]

const REACTIONS = [
    "Hexokinase",        # Glucose → G6P
    "G6P_Isomerase",     # G6P → F6P
    "PFK1",              # F6P → F1,6BP
    "Aldolase",          # F1,6BP → DHAP + G3P
    "TPI",               # DHAP ⇌ G3P
    "GAPDH",             # G3P → 1,3-BPG
    "PGK",               # 1,3-BPG → 3-PG
    "PGM",               # 3-PG → 2-PG
    "Enolase",           # 2-PG → PEP
    "Pyruvate_Kinase",   # PEP → Pyruvate
    "LDH",               # Pyruvate → Lactate
    "PDH",               # Pyruvate → Acetyl-CoA
    "Citrate_Synthase",  # Acetyl-CoA → Citrate
    "Isocitrate_DH",     # Citrate → α-KG
    "αKG_DH",            # α-KG → Succinate
    "Succinate_DH",      # Succinate → Oxaloacetate
    "Malate_DH"          # Oxaloacetate → (recycle)
]

# Reaction costs (ATP equivalents, negative indicates production)
const REACTION_COSTS = [
    1.0,    # Hexokinase (consumes ATP)
    0.5,    # G6P Isomerase
    1.0,    # PFK1 (consumes ATP)
    0.8,    # Aldolase
    0.3,    # TPI
    1.2,    # GAPDH (requires NAD+)
    -1.0,   # PGK (produces ATP)
    0.4,    # PGM
    0.6,    # Enolase
    -1.0,   # Pyruvate Kinase (produces ATP)
    0.8,    # LDH
    2.0,    # PDH (complex)
    1.5,    # Citrate Synthase
    0.9,    # Isocitrate DH
    0.4,    # α-KG DH
    0.3,    # Succinate DH
    0.2     # Malate DH
]

# Reaction network represented as (substrate, reaction, product)
const REACTION_NETWORK = [
    ("Glucose", "Hexokinase", "Glucose-6-P"),
    ("Glucose-6-P", "G6P_Isomerase", "Fructose-6-P"),
    ("Fructose-6-P", "PFK1", "Fructose-1,6-BP"),
    ("Fructose-1,6-BP", "Aldolase", "DHAP"),
    ("Fructose-1,6-BP", "Aldolase", "G3P"),
    ("DHAP", "TPI", "G3P"),
    ("G3P", "TPI", "DHAP"),
    ("G3P", "GAPDH", "1,3-BPG"),
    ("1,3-BPG", "PGK", "3-PG"),
    ("3-PG", "PGM", "2-PG"),
    ("2-PG", "Enolase", "PEP"),
    ("PEP", "Pyruvate_Kinase", "Pyruvate"),
    ("Pyruvate", "LDH", "Lactate"),
    ("Pyruvate", "PDH", "Acetyl-CoA"),
    ("Acetyl-CoA", "Citrate_Synthase", "Citrate"),
    ("Citrate", "Isocitrate_DH", "α-Ketoglutarate"),
    ("α-Ketoglutarate", "αKG_DH", "Succinate"),
    ("Succinate", "Succinate_DH", "Oxaloacetate"),
    ("Oxaloacetate", "Malate_DH", "Glucose-6-P")  # recycling step
]

const DEFAULT_MAX_REACH_COST = 5.0

const REACTION_METADATA = Dict(
    "Hexokinase" => (cost = 1.0, enzyme_load = 2.0),
    "G6P_Isomerase" => (cost = 0.5, enzyme_load = 1.0),
    "PFK1" => (cost = 1.0, enzyme_load = 2.5),
    "Aldolase" => (cost = 0.8, enzyme_load = 1.5),
    "TPI" => (cost = 0.3, enzyme_load = 0.5),
    "GAPDH" => (cost = 1.2, enzyme_load = 3.0),
    "PGK" => (cost = -1.0, enzyme_load = 2.0),
    "PGM" => (cost = 0.4, enzyme_load = 1.0),
    "Enolase" => (cost = 0.6, enzyme_load = 1.5),
    "Pyruvate_Kinase" => (cost = -1.0, enzyme_load = 2.0),
    "LDH" => (cost = 0.8, enzyme_load = 1.0),
    "PDH" => (cost = 2.0, enzyme_load = 4.0),
    "Citrate_Synthase" => (cost = 1.5, enzyme_load = 3.0),
    "Isocitrate_DH" => (cost = 0.9, enzyme_load = 2.5),
    "αKG_DH" => (cost = 0.4, enzyme_load = 2.0),
    "Succinate_DH" => (cost = 0.3, enzyme_load = 1.8),
    "Malate_DH" => (cost = 0.2, enzyme_load = 1.2)
)

function metabolite_indices()
    return Dict(m => i for (i, m) in enumerate(METABOLITES))
end

function build_metabolic_graph()
    indices = metabolite_indices()
    edges = OptimShortestPaths.Edge[]
    weights = Float64[]

    for (substrate, reaction, product) in REACTION_NETWORK
        haskey(indices, substrate) || continue
        haskey(indices, product) || continue

        src = indices[substrate]
        dst = indices[product]
        reaction_idx = findfirst(==(reaction), REACTIONS)
        cost = reaction_idx === nothing ? 1.0 : REACTION_COSTS[reaction_idx]

        push!(edges, OptimShortestPaths.Edge(src, dst, length(edges) + 1))
        push!(weights, max(0.1, cost + 1.0))  # ensure positive weights
    end

    return OptimShortestPaths.DMYGraph(length(METABOLITES), edges, weights)
end

function default_metabolic_pathways()
    return [
        ("Glucose", "Pyruvate", "Glycolysis"),
        ("Glucose", "Lactate", "Anaerobic"),
        ("Glucose", "Citrate", "Aerobic"),
        ("G3P", "Pyruvate", "Lower glycolysis")
    ]
end

function create_mo_metabolic_network()
    edges = MultiObjective.MultiObjectiveEdge[]
    atp_adjustments = Dict{Int, Float64}()

    # Start node
    push!(edges, MultiObjective.MultiObjectiveEdge(1, 2, [0.0, 0.0, 0.0, 0.0], 1))

    # Glycolysis pathway (fast, moderate ATP)
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 3, [1.0, 0.5, 2.0, 0.1], 2))
    push!(edges, MultiObjective.MultiObjectiveEdge(3, 4, [0.5, 0.3, 1.0, 0.05], 3))
    push!(edges, MultiObjective.MultiObjectiveEdge(4, 5, [1.0, 0.5, 2.5, 0.2], 4))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 6, [0.8, 0.4, 1.5, 0.1], 5))
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 7, [0.0, 1.0, 3.0, 0.3], 6))
    atp_adjustments[6] = -2.0

    # Pentose phosphate pathway
    push!(edges, MultiObjective.MultiObjectiveEdge(3, 8, [0.0, 2.0, 3.0, 0.5], 7))
    push!(edges, MultiObjective.MultiObjectiveEdge(8, 7, [0.5, 1.5, 2.0, 0.4], 8))

    # Fermentation
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 9, [0.0, 0.5, 1.0, 1.0], 9))

    # Aerobic respiration
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 10, [2.0, 3.0, 4.0, 0.1], 10))
    push!(edges, MultiObjective.MultiObjectiveEdge(10, 11, [0.0, 5.0, 10.0, 0.2], 11))
    atp_adjustments[11] = -30.0

    # Alternative pathways
    push!(edges, MultiObjective.MultiObjectiveEdge(4, 12, [0.5, 1.0, 1.5, 0.3], 12))
    push!(edges, MultiObjective.MultiObjectiveEdge(12, 11, [0.0, 4.0, 8.0, 0.4], 13))
    atp_adjustments[13] = -25.0

    # Stress response (clean but slower, moderate ATP)
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 11, [1.5, 4.5, 6.0, 0.15], 14))
    atp_adjustments[14] = -18.0

    # Overflow metabolism
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 11, [4.5, 1.8, 4.0, 0.9], 15))
    atp_adjustments[15] = -8.0

    # Redox balancing branch
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 12, [2.0, 2.5, 4.5, 0.25], 16))

    # High-flux shunt
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 7, [1.2, 0.8, 5.5, 0.45], 17))
    atp_adjustments[17] = -5.0

    # Oxygen-limited branch
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 11, [3.5, 6.0, 6.5, 0.05], 18))
    atp_adjustments[18] = -12.0

    adjacency = [Int[] for _ in 1:12]
    for (i, edge) in enumerate(edges)
        push!(adjacency[edge.source], i)
    end

    graph = MultiObjective.MultiObjectiveGraph(
        12,
        edges,
        4,
        adjacency,
        ["ATP Cost", "Time(min)", "Enzyme Load", "Byproducts"],
        objective_sense = fill(:min, 4)
    )

    return graph, atp_adjustments
end

function apply_atp_adjustment!(graph::MultiObjective.MultiObjectiveGraph,
                               solutions::Vector{MultiObjective.ParetoSolution},
                               adjustments::Dict{Int, Float64})
    isempty(adjustments) && return solutions
    for sol in solutions
        path = sol.path
        total_adjustment = 0.0
        if length(path) > 1
            for i in 1:(length(path) - 1)
                u, v = path[i], path[i + 1]
                edge_id = nothing
                for idx in graph.adjacency_list[u]
                    edge = graph.edges[idx]
                    if edge.target == v
                        edge_id = edge.edge_id
                        break
                    end
                end
                if edge_id !== nothing && haskey(adjustments, edge_id)
                    total_adjustment += adjustments[edge_id]
                end
            end
        end
        sol.objectives[1] += total_adjustment
    end
    return solutions
end

function enzyme_cost_dataframe()
    costs = Float64[]
    loads = Float64[]
    names = String[]
    for reaction in REACTIONS
        metadata = get(REACTION_METADATA, reaction, nothing)
        metadata === nothing && continue
        push!(names, reaction)
        push!(costs, metadata.cost)
        push!(loads, metadata.enzyme_load)
    end
    return (names = names, costs = costs, loads = loads)
end


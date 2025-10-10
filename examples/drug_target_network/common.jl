# Shared data and helper routines for the drug-target example and figure generation

using OptimShortestPaths
using OptimShortestPaths.MultiObjective

const DRUGS = [
    "Aspirin",           # Classic NSAID
    "Ibuprofen",         # COX-2 leaning
    "Acetaminophen",     # Paracetamol
    "Celecoxib",         # COX-2 selective
    "Morphine",          # Opioid
    "Gabapentin",        # Anticonvulsant/neuropathic pain
    "Lidocaine",         # Local anesthetic
    "Capsaicin"          # TRPV1 agonist
]

const TARGETS = [
    "COX1",
    "COX2",
    "TRPV1",
    "Nav1.7",
    "MOR",
    "GABA_A",
    "CB1",
    "5HT2A"
]

# Binding affinity matrix (0-1 scale, higher = stronger binding)
const INTERACTION_MATRIX = Float64[
    # COX1  COX2  TRPV1 Nav1.7 MOR  GABA_A CB1  5HT2A
    0.85  0.45  0.00  0.00   0.00  0.00  0.00  0.00;  # Aspirin
    0.30  0.90  0.00  0.00   0.00  0.00  0.00  0.00;  # Ibuprofen
    0.10  0.15  0.20  0.00   0.00  0.00  0.00  0.05;  # Acetaminophen
    0.05  0.95  0.00  0.00   0.00  0.00  0.00  0.00;  # Celecoxib
    0.00  0.00  0.00  0.00   0.95  0.00  0.10  0.20;  # Morphine
    0.00  0.00  0.00  0.30   0.00  0.60  0.00  0.00;  # Gabapentin
    0.00  0.00  0.00  0.85   0.00  0.00  0.00  0.00;  # Lidocaine
    0.00  0.00  0.90  0.00   0.00  0.00  0.00  0.00   # Capsaicin
]

function build_drug_target_network()
    return create_drug_target_network(DRUGS, TARGETS, INTERACTION_MATRIX)
end

# Convenience subset for figures that only plot NSAIDs
const FIGURE_DRUGS = ["Aspirin", "Ibuprofen", "Celecoxib", "Naproxen"]
const FIGURE_INTERACTIONS = [
    0.85 0.45 0.20 0.10;
    0.30 0.90 0.15 0.05;
    0.05 0.95 0.10 0.02;
    0.40 0.80 0.25 0.08
]
const FIGURE_TARGETS = ["COX-1", "COX-2", "PGE2", "TRPV1"]

function build_figure_network()
    return create_drug_target_network(FIGURE_DRUGS, FIGURE_TARGETS, FIGURE_INTERACTIONS)
end

# Multi-objective graph used in example and figures
function create_mo_drug_network()
    edges = MultiObjective.MultiObjectiveEdge[]

    # Start to drugs (no cost)
    for i in 1:4
        push!(edges, MultiObjective.MultiObjectiveEdge(1, i + 1, [0.0, 0.0, 0.0, 0.0], length(edges) + 1))
    end

    # Drug properties: [Efficacy, Toxicity, Cost, Time]
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 6, [0.85, 0.3, 5.0, 2.0], length(edges)+1))
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 7, [0.70, 0.4, 5.0, 2.5], length(edges)+1))

    push!(edges, MultiObjective.MultiObjectiveEdge(3, 6, [0.65, 0.15, 15.0, 3.0], length(edges)+1))
    push!(edges, MultiObjective.MultiObjectiveEdge(3, 7, [0.60, 0.10, 15.0, 3.5], length(edges)+1))
    push!(edges, MultiObjective.MultiObjectiveEdge(3, 8, [0.55, 0.10, 15.0, 4.0], length(edges)+1))

    push!(edges, MultiObjective.MultiObjectiveEdge(4, 6, [0.95, 0.60, 50.0, 1.0], length(edges)+1))
    push!(edges, MultiObjective.MultiObjectiveEdge(4, 8, [0.98, 0.70, 50.0, 0.5], length(edges)+1))

    push!(edges, MultiObjective.MultiObjectiveEdge(5, 7, [0.45, 0.05, 200.0, 6.0], length(edges)+1))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 8, [0.40, 0.03, 200.0, 7.0], length(edges)+1))

    for i in 6:8
        push!(edges, MultiObjective.MultiObjectiveEdge(i, 9, [0.0, 0.0, 0.0, 0.5], length(edges)+1))
    end

    adjacency = [Int[] for _ in 1:9]
    for (i, edge) in enumerate(edges)
        push!(adjacency[edge.source], i)
    end

    graph = MultiObjective.MultiObjectiveGraph(
        9,
        edges,
        4,
        adjacency,
        ["Efficacy", "Toxicity", "Cost", "Time"],
        objective_sense = [:max, :min, :min, :min]
    )

    return graph
end


# Shared data and helper functions for the treatment protocol example and figures.

using OptimShortestPaths
using OptimShortestPaths.MultiObjective

const TREATMENTS = [
    "Initial_Screening",
    "Diagnostic_Imaging",
    "Biopsy",
    "Staging",
    "Multidisciplinary_Review",
    "Surgery_Consultation",
    "Medical_Oncology",
    "Radiation_Oncology",
    "Surgery_Minor",
    "Surgery_Major",
    "Chemotherapy_Neoadjuvant",
    "Chemotherapy_Adjuvant",
    "Radiation_Therapy",
    "Immunotherapy",
    "Targeted_Therapy",
    "Palliative_Care",
    "Follow_up_Monitoring",
    "Remission",
    "Recurrence_Detection",
    "Second_Line_Treatment"
]

const TREATMENT_COSTS = [
    0.5,
    2.0,
    1.5,
    1.0,
    0.8,
    0.5,
    1.0,
    1.0,
    15.0,
    35.0,
    25.0,
    20.0,
    30.0,
    40.0,
    45.0,
    10.0,
    2.0,
    0.0,
    3.0,
    50.0
]

const EFFICACY_WEIGHTS = [
    1.0,
    0.95,
    0.98,
    0.90,
    0.85,
    0.80,
    0.85,
    0.85,
    0.85,
    0.90,
    0.75,
    0.80,
    0.85,
    0.70,
    0.75,
    0.60,
    0.95,
    1.0,
    0.90,
    0.60
]

const TREATMENT_TRANSITIONS = [
    ("Initial_Screening", "Diagnostic_Imaging", 0.2),
    ("Diagnostic_Imaging", "Biopsy", 0.5),
    ("Biopsy", "Staging", 0.3),
    ("Staging", "Multidisciplinary_Review", 0.2),
    ("Multidisciplinary_Review", "Surgery_Consultation", 0.1),
    ("Multidisciplinary_Review", "Medical_Oncology", 0.1),
    ("Multidisciplinary_Review", "Radiation_Oncology", 0.1),
    ("Multidisciplinary_Review", "Palliative_Care", 0.5),
    ("Surgery_Consultation", "Surgery_Minor", 0.5),
    ("Surgery_Consultation", "Surgery_Major", 1.0),
    ("Surgery_Consultation", "Chemotherapy_Neoadjuvant", 0.3),
    ("Chemotherapy_Neoadjuvant", "Surgery_Minor", 0.8),
    ("Chemotherapy_Neoadjuvant", "Surgery_Major", 1.2),
    ("Surgery_Minor", "Chemotherapy_Adjuvant", 0.5),
    ("Surgery_Minor", "Radiation_Therapy", 0.4),
    ("Surgery_Minor", "Follow_up_Monitoring", 0.2),
    ("Surgery_Major", "Chemotherapy_Adjuvant", 0.6),
    ("Surgery_Major", "Radiation_Therapy", 0.5),
    ("Surgery_Major", "Follow_up_Monitoring", 0.3),
    ("Medical_Oncology", "Immunotherapy", 0.4),
    ("Medical_Oncology", "Targeted_Therapy", 0.3),
    ("Medical_Oncology", "Chemotherapy_Adjuvant", 0.2),
    ("Radiation_Oncology", "Radiation_Therapy", 0.3),
    ("Radiation_Oncology", "Follow_up_Monitoring", 0.4),
    ("Radiation_Therapy", "Follow_up_Monitoring", 0.2),
    ("Chemotherapy_Adjuvant", "Follow_up_Monitoring", 0.3),
    ("Immunotherapy", "Follow_up_Monitoring", 0.4),
    ("Targeted_Therapy", "Follow_up_Monitoring", 0.3),
    ("Palliative_Care", "Follow_up_Monitoring", 0.2),
    ("Follow_up_Monitoring", "Remission", 0.1),
    ("Follow_up_Monitoring", "Recurrence_Detection", 0.8),
    ("Recurrence_Detection", "Second_Line_Treatment", 0.5),
    ("Recurrence_Detection", "Palliative_Care", 1.0),
    ("Second_Line_Treatment", "Follow_up_Monitoring", 0.4),
    ("Second_Line_Treatment", "Palliative_Care", 0.8)
]

function treatment_index_map()
    return Dict(name => idx for (idx, name) in enumerate(TREATMENTS))
end

function build_treatment_graph()
    index_map = treatment_index_map()
    edges = OptimShortestPaths.Edge[]
    weights = Float64[]

    for (src_name, dst_name, transition_cost) in TREATMENT_TRANSITIONS
        haskey(index_map, src_name) || continue
        haskey(index_map, dst_name) || continue
        src = index_map[src_name]
        dst = index_map[dst_name]
        combined_cost = transition_cost + TREATMENT_COSTS[src]
        push!(edges, OptimShortestPaths.Edge(src, dst, length(edges) + 1))
        push!(weights, max(0.1, combined_cost))
    end

    return OptimShortestPaths.DMYGraph(length(TREATMENTS), edges, weights), index_map
end

function create_mo_treatment_network()
    edges = MultiObjective.MultiObjectiveEdge[]

    # Objectives: [Cost($k), Time(weeks), QoL Impact, Success Rate]
    push!(edges, MultiObjective.MultiObjectiveEdge(1, 2, [0.0, 0.0, 0.0, 0.0], 1))
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 3, [3.5, 1.0, -5.0, 0.95], 2))
    push!(edges, MultiObjective.MultiObjectiveEdge(2, 4, [8.0, 0.5, -10.0, 0.98], 3))
    push!(edges, MultiObjective.MultiObjectiveEdge(3, 5, [2.0, 1.0, -8.0, 0.90], 4))
    push!(edges, MultiObjective.MultiObjectiveEdge(4, 5, [1.0, 0.5, -5.0, 0.95], 5))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 6, [35.0, 2.0, -30.0, 0.85], 6))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 7, [15.0, 1.0, -15.0, 0.90], 7))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 8, [25.0, 12.0, -40.0, 0.75], 8))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 9, [40.0, 16.0, -20.0, 0.70], 9))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 10, [45.0, 8.0, -15.0, 0.80], 10))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 11, [30.0, 6.0, -25.0, 0.85], 11))
    push!(edges, MultiObjective.MultiObjectiveEdge(5, 12, [10.0, 52.0, -10.0, 0.60], 12))
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 8, [25.0, 12.0, -35.0, 0.80], 13))
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 11, [30.0, 6.0, -20.0, 0.88], 14))
    push!(edges, MultiObjective.MultiObjectiveEdge(6, 13, [2.0, 52.0, 60.0, 0.85], 15))
    push!(edges, MultiObjective.MultiObjectiveEdge(7, 13, [2.0, 52.0, 70.0, 0.90], 16))
    push!(edges, MultiObjective.MultiObjectiveEdge(8, 13, [2.0, 52.0, 40.0, 0.75], 17))
    push!(edges, MultiObjective.MultiObjectiveEdge(9, 13, [2.0, 52.0, 50.0, 0.70], 18))
    push!(edges, MultiObjective.MultiObjectiveEdge(10, 13, [2.0, 52.0, 65.0, 0.80], 19))
    push!(edges, MultiObjective.MultiObjectiveEdge(11, 13, [2.0, 52.0, 55.0, 0.85], 20))
    push!(edges, MultiObjective.MultiObjectiveEdge(12, 13, [2.0, 104.0, 75.0, 0.60], 21))

    adjacency = [Int[] for _ in 1:13]
    for (i, edge) in enumerate(edges)
        push!(adjacency[edge.source], i)
    end

    graph = MultiObjective.MultiObjectiveGraph(
        13,
        edges,
        4,
        adjacency,
        ["Cost(\$k)", "Time(weeks)", "QoL", "Success"],
        objective_sense = [:min, :min, :max, :max]
    )

    return graph
end

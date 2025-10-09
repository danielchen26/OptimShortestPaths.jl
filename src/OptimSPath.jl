"""
OptimSPath.jl - Optimization via Shortest Paths

A unified framework for solving multi-objective optimization problems by transforming them
into graph shortest-path problems. OptimSPath leverages the efficient DMY (Duan-Mao-Yin) algorithm
while extending it with Pareto optimization and domain-specific applications.

Key Innovation: OptimSPath casts complex optimization problems as shortest-path problems,
enabling efficient solution of pharmaceutical, metabolic, and healthcare optimization challenges.
"""
module OptimSPath

using DataStructures: OrderedSet

# Core algorithm exports (DMY foundation)
export dmy_sssp!, DMYGraph, Edge, Block
export recursive_layer!, bmssp!, select_pivots, partition_blocks
export bmssp_single_round!, count_relaxations, validate_bmssp_input, bmssp_with_statistics!

# Multi-objective optimization exports
export MultiObjectiveEdge, MultiObjectiveGraph, ParetoSolution
export compute_pareto_front, weighted_sum_approach, epsilon_constraint_approach
export lexicographic_approach, get_knee_point, compute_path_objectives

# OptimSPath transformation exports
export OptimizationProblem, optimize_to_graph, objectives_to_weights, cast_problem

# Pharmaceutical network exports
export PharmaNetwork, DrugTargetNetwork, MetabolicPathway, TreatmentProtocol
export create_drug_target_network, create_metabolic_pathway, create_treatment_protocol

# Utility exports
export validate_graph, shortest_path_tree, reconstruct_path
export compare_with_dijkstra, simple_dijkstra, path_length
export graph_reachability, format_distance_results, verify_shortest_path
# Generic analysis functions
export calculate_distance_ratio, calculate_path_preference
export find_reachable_vertices, analyze_connectivity
export compare_sources, find_shortest_path
export vertex_count, edge_count, out_degree, outgoing_edges
export get_edge_weight, get_edge, is_connected, create_simple_graph
export graph_density, has_self_loops, get_vertices_by_out_degree
export iterate_edges, find_edge, get_edge_weight_between, validate_vertex
export get_all_targets, graph_statistics
export calculate_pivot_threshold, calculate_partition_parameter
export pivot_selection_statistics, validate_pivot_selection, partition_blocks_adaptive
export dmy_sssp_with_parents!, dmy_sssp_bounded!, validate_dmy_input
export dmy_algorithm_statistics
export find_drug_target_paths, analyze_drug_connectivity
export find_metabolic_pathway, optimize_treatment_sequence

# Constants
const INF = typemax(Float64)

# Include core components
include("core_types.jl")
include("graph_utils.jl")
include("bmssp.jl")
include("pivot_selection.jl")
include("dmy_algorithm.jl")
include("utilities.jl")
include("pharma_networks.jl")
include("multi_objective.jl")
# Bring MultiObjective symbols into OptimSPath scope
import .MultiObjective: MultiObjectiveEdge, MultiObjectiveGraph, ParetoSolution,
    compute_pareto_front, weighted_sum_approach, epsilon_constraint_approach,
    lexicographic_approach, get_knee_point, compute_path_objectives

"""
    OptimizationProblem(::Symbol, data, source)

Container for problem instances that can be transformed into a graph using
the OptimSPath casting helpers. `data` is the argument tuple that will be splatted
into the corresponding constructor (e.g. `create_drug_target_network`).
"""
struct OptimizationProblem{T}
    type::Symbol
    data::T
    source::Int
end

function OptimizationProblem(problem_type::Symbol, data, source::Integer)
    converted_source = Int(source)
    converted_source > 0 || throw(ArgumentError("Source vertex must be positive"))
    return OptimizationProblem{typeof(data)}(problem_type, data, converted_source)
end

# OptimSPath-specific transformation functions
"""
Cast an optimization problem to a graph representation.
This is the core innovation of OptimSPath: transforming optimization into shortest paths.
"""
function cast_problem(problem_type::Symbol, data)
    args = data isa Tuple ? data : (data,)
    if problem_type == :drug_discovery
        return create_drug_target_network(args...)
    elseif problem_type == :metabolic
        return create_metabolic_pathway(args...)
    elseif problem_type == :treatment
        return create_treatment_protocol(args...)
    else
        error("Unknown problem type: $problem_type")
    end
end

"""
Transform optimization objectives into edge weights.
"""
function objectives_to_weights(objectives::Vector{Function}, edge_data::Any)
    # Transform multiple objectives into weights for shortest path
    weights = Float64[]
    for obj in objectives
        push!(weights, obj(edge_data))
    end
    return weights
end

"""
Main OptimSPath interface: optimize by casting to shortest path.
"""
function optimize_to_graph(problem::OptimizationProblem; solver=:dmy)
    # Cast the optimization problem to a graph
    graph = cast_problem(problem.type, problem.data)
    
    # Solve using appropriate algorithm
    if solver == :dmy
        return dmy_sssp!(graph, problem.source)
    else
        error("Unknown solver: $solver")
    end
end

# Backward compatible fallback for custom problem containers that expose
# the expected fields. This keeps existing notebooks working while nudging
# users toward `OptimizationProblem`.
function optimize_to_graph(problem; solver = :dmy)
    hasproperty(problem, :type) || throw(ArgumentError("Problem must define a `type` field"))
    hasproperty(problem, :data) || throw(ArgumentError("Problem must define a `data` field"))
    hasproperty(problem, :source) || throw(ArgumentError("Problem must define a `source` field"))
    return optimize_to_graph(
        OptimizationProblem(problem.type, problem.data, problem.source);
        solver = solver,
    )
end

# Bring Pharma (pharmaceutical networks) symbols into OptimSPath scope
import .Pharma: create_drug_target_network, find_drug_target_paths, analyze_drug_connectivity,
                 create_metabolic_pathway, find_metabolic_pathway, create_treatment_protocol,
                 optimize_treatment_sequence
end # module OptimSPath

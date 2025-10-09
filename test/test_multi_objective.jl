"""
Multi-objective shortest-path regression tests.
"""

using Test

const MO = OptimSPath.MultiObjective
const MultiObjectiveEdge = MO.MultiObjectiveEdge
const MultiObjectiveGraph = MO.MultiObjectiveGraph
const ParetoSolution = MO.ParetoSolution
const compute_pareto_front = MO.compute_pareto_front
const weighted_sum_approach = MO.weighted_sum_approach
const epsilon_constraint_approach = MO.epsilon_constraint_approach
const lexicographic_approach = MO.lexicographic_approach
const get_knee_point = MO.get_knee_point

@testset "Multi-Objective Shortest Path Analysis" begin
    @testset "Drug-Target Network Pareto Front" begin
        edges = [
            MultiObjectiveEdge(1, 2, [0.0, 0.0, 0.0, 0.0], 1),
            MultiObjectiveEdge(2, 3, [0.85, 0.3, 1000.0, 2.0], 2),
            MultiObjectiveEdge(2, 4, [0.6, 0.1, 500.0, 4.0], 3),
            MultiObjectiveEdge(2, 5, [0.95, 0.5, 2000.0, 1.0], 4),
            MultiObjectiveEdge(3, 6, [0.9, 0.4, 1200.0, 2.5], 5),
            MultiObjectiveEdge(4, 6, [0.7, 0.15, 600.0, 4.5], 6),
            MultiObjectiveEdge(5, 6, [0.98, 0.6, 2200.0, 1.5], 7),
            MultiObjectiveEdge(3, 7, [0.85, 0.3, 1000.0, 2.0], 8),
            MultiObjectiveEdge(4, 7, [0.6, 0.1, 500.0, 4.0], 9),
            MultiObjectiveEdge(5, 7, [0.95, 0.5, 2000.0, 1.0], 10),
            MultiObjectiveEdge(6, 7, [0.0, 0.0, 0.0, 0.0], 11),
        ]

        adjacency = [Int[] for _ in 1:7]
        for (i, edge) in enumerate(edges)
            push!(adjacency[edge.source], i)
        end

        graph = MultiObjectiveGraph(
            7,
            edges,
            4,
            adjacency,
            ["Efficacy", "Toxicity", "Cost", "Time"],
            objective_sense = [:max, :min, :min, :min],
        )

        pareto_front = compute_pareto_front(graph, 1, 7, max_solutions = 20)

        @test length(pareto_front) == 6
        unique_paths = Set(Tuple(sol.path) for sol in pareto_front)
        @test length(unique_paths) == length(pareto_front)
        @test maximum(sol -> sol.objectives[1], pareto_front) ≈ 1.93 atol = 1e-8
        @test minimum(sol -> sol.objectives[2], pareto_front) ≈ 0.2 atol = 1e-8

        knee = get_knee_point(pareto_front)
        @test knee !== nothing
        @test Tuple(knee.path) in unique_paths
    end

    @testset "Strategy Helpers" begin
        edges = [
            MultiObjectiveEdge(1, 2, [0.0, 0.0, 0.0, 0.0], 1),
            MultiObjectiveEdge(2, 3, [3.0, 0.5, 2.0, 0.1], 2),
            MultiObjectiveEdge(3, 5, [2.0, 0.3, 1.5, 0.2], 3),
            MultiObjectiveEdge(2, 4, [1.0, 1.5, 1.0, 0.05], 4),
            MultiObjectiveEdge(4, 5, [0.5, 1.2, 0.8, 0.03], 5),
            MultiObjectiveEdge(2, 5, [2.5, 0.8, 1.8, 0.08], 6),
            MultiObjectiveEdge(5, 6, [1.0, 0.2, 0.5, 0.0], 7),
        ]

        adjacency = [Int[] for _ in 1:6]
        for (i, edge) in enumerate(edges)
            push!(adjacency[edge.source], i)
        end

        graph = MultiObjectiveGraph(
            6,
            edges,
            4,
            adjacency,
            ["ATP Cost", "Time", "Enzyme Load", "Byproducts"],
            objective_sense = fill(:min, 4),
        )

        weights = [0.3, 0.3, 0.2, 0.2]
        sol_weighted = weighted_sum_approach(graph, 1, 6, weights)
        @test sol_weighted.path == [1, 2, 5, 6]
        @test sol_weighted.objectives ≈ [3.5, 1.0, 2.3, 0.08]

        constraints = [Inf, 2.0, 2.5, Inf]
        sol_constrained = epsilon_constraint_approach(graph, 1, 6, 1, constraints)
        @test sol_constrained.path == [1, 2, 5, 6]

        tight_constraints = [Inf, 0.9, 2.5, Inf]
        infeasible = epsilon_constraint_approach(graph, 1, 6, 1, tight_constraints)
        @test all(isinf, infeasible.objectives)

        priorities = [2, 1, 3, 4]
        sol_lex = lexicographic_approach(graph, 1, 6, priorities)
        @test sol_lex.path == [1, 2, 5, 6]
    end

    @testset "Dominance and Senses" begin
        edges = [
            MultiObjectiveEdge(1, 2, [0.9, 5.0], 1),
            MultiObjectiveEdge(1, 3, [0.6, 1.0], 2),
        ]
        adjacency = [Int[] for _ in 1:3]
        for (i, edge) in enumerate(edges)
            push!(adjacency[edge.source], i)
        end

        graph = MultiObjectiveGraph(
            3,
            edges,
            2,
            adjacency,
            ["efficacy", "cost"],
            objective_sense = [:max, :min],
        )

        pareto_1 = compute_pareto_front(graph, 1, 2)
        pareto_2 = compute_pareto_front(graph, 1, 3)
        @test length(pareto_1) == 1 == length(pareto_2)
        @test pareto_1[1].objectives[1] > pareto_2[1].objectives[1]

        constraints = [0.7, 10.0]
        sol = epsilon_constraint_approach(graph, 1, 2, 1, constraints)
        @test sol.objectives[1] ≈ pareto_1[1].objectives[1]

        infeasible = epsilon_constraint_approach(graph, 1, 3, 2, constraints)
        @test all(isinf, infeasible.objectives)

        @test_throws ArgumentError weighted_sum_approach(graph, 1, 2, [0.5, 0.5])
        @test_throws ArgumentError lexicographic_approach(graph, 1, 2, [1, 2])
    end

    @testset "Weighted Sum Parallel Edge Handling" begin
        edges = [
            MultiObjectiveEdge(1, 2, [10.0, 10.0], 1),
            MultiObjectiveEdge(1, 2, [1.0, 2.0], 2),
        ]
        adjacency = [Int[] for _ in 1:2]
        for (i, edge) in enumerate(edges)
            push!(adjacency[edge.source], i)
        end

        graph = MultiObjectiveGraph(
            2,
            edges,
            2,
            adjacency,
            ["a", "b"],
            objective_sense = fill(:min, 2),
        )

        sol = weighted_sum_approach(graph, 1, 2, [0.5, 0.5])
        @test sol.path == [1, 2]
        @test sol.objectives ≈ [1.0, 2.0]
    end
end

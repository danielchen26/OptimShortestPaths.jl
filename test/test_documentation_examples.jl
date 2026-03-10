using Test

if !isdefined(Main, :OptimShortestPaths)
    push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
    include("../src/OptimShortestPaths.jl")
end

const OSP = Main.OptimShortestPaths
const MO = OSP.MultiObjective

function run_documentation_examples_tests()
    @testset "Documentation Example Tests" begin
        @testset "Basic Usage Example" begin
            edges = [
                MO.MultiObjectiveEdge(1, 2, [1.0, 5.0], 1),
                MO.MultiObjectiveEdge(2, 3, [2.0, 1.0], 2),
            ]

            graph = MO.MultiObjectiveGraph(
                3,
                edges,
                2,
                ["Cost", "Time"],
            )

            pareto_solutions = MO.compute_pareto_front(graph, 1, 3; max_solutions = 1000)

            @test length(pareto_solutions) == 1
            @test pareto_solutions[1].objectives ≈ [3.0, 6.0]
            @test pareto_solutions[1].path == [1, 2, 3]
        end

        @testset "Mixed Objective Senses" begin
            edges = [MO.MultiObjectiveEdge(1, 2, [5.0, 8.0], 1)]
            graph = MO.MultiObjectiveGraph(
                2,
                edges,
                2,
                ["Cost", "Profit"];
                objective_sense = [:min, :max],
            )

            pareto_front = MO.compute_pareto_front(graph, 1, 2)

            @test length(pareto_front) == 1
            @test pareto_front[1].objectives ≈ [5.0, 8.0]
            @test pareto_front[1].path == [1, 2]
        end

        @testset "Cost-Time Trade-off Example" begin
            edges = [
                MO.MultiObjectiveEdge(1, 2, [10.0, 1.0], 1),
                MO.MultiObjectiveEdge(1, 3, [30.0, 0.5], 2),
                MO.MultiObjectiveEdge(2, 4, [5.0, 2.0], 3),
                MO.MultiObjectiveEdge(3, 4, [15.0, 1.0], 4),
            ]

            graph = MO.MultiObjectiveGraph(
                4,
                edges,
                2,
                ["Cost", "Time"],
            )

            pareto_front = MO.compute_pareto_front(graph, 1, 4)
            best = MO.get_knee_point(pareto_front)

            @test length(pareto_front) == 2
            @test Set(Tuple(sol.objectives) for sol in pareto_front) ==
                  Set([(15.0, 3.0), (45.0, 1.5)])
            @test best !== nothing
            @test best.objectives ≈ [15.0, 3.0]
        end

        @testset "Examples.md Multi-Objective Example" begin
            edges = [
                MO.MultiObjectiveEdge(1, 2, [1.0, 10.0], 1),
                MO.MultiObjectiveEdge(2, 3, [2.0, 5.0], 2),
                MO.MultiObjectiveEdge(1, 3, [5.0, 3.0], 3),
            ]

            graph = MO.MultiObjectiveGraph(
                3,
                edges,
                2,
                ["Cost", "Time"],
            )

            solutions = MO.compute_pareto_front(graph, 1, 3)
            best = MO.get_knee_point(solutions)

            @test length(solutions) == 2
            @test best !== nothing
            @test Tuple(best.objectives) in Set(Tuple(sol.objectives) for sol in solutions)
        end
    end
end

run_documentation_examples_tests()

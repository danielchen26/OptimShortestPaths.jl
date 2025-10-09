#!/usr/bin/env julia

"""
Comprehensive performance benchmark comparing DMY vs Dijkstra.

The script measures multiple graph families, computes 95% confidence
intervals from repeated trials, saves a summary table to
`benchmark_results.txt`, and (optionally) regenerates illustrative plots
if the plotting stack is available.
"""

using BenchmarkTools
using Dates
using OptimSPath
using Printf
using Random
using Statistics

const RESULT_PATH = joinpath(@__DIR__, "..", "benchmark_results.txt")
const TRIALS = 40

Random.seed!(42)

println("="^72)
println("DMY vs Dijkstra Performance Benchmark")
println("="^72, "\n")

struct BenchmarkResult
    size::Int
    edges::Int
    dmy_ms::Float64
    dmy_ci::Float64
    dijkstra_ms::Float64
    dijkstra_ci::Float64
end

function run_trials(f::Function; trials::Int = TRIALS)
    samples = Vector{Float64}(undef, trials)
    for i in 1:trials
        start = time_ns()
        f()
        samples[i] = (time_ns() - start) / 1_000_000.0 # milliseconds
    end
    μ = mean(samples)
    σ = std(samples)
    ci = 1.96 * σ / sqrt(trials)
    return μ, ci
end

function benchmark_graph(graph::OptimSPath.DMYGraph, source::Int; trials::Int = TRIALS)
    # Warm-up to make sure compilation cost is excluded.
    OptimSPath.dmy_sssp!(graph, source)
    OptimSPath.simple_dijkstra(graph, source)

    dmy_mean, dmy_ci = run_trials(() -> OptimSPath.dmy_sssp!(graph, source); trials = trials)
    dijkstra_mean, dijkstra_ci = run_trials(() -> OptimSPath.simple_dijkstra(graph, source); trials = trials)

    return dmy_mean, dmy_ci, dijkstra_mean, dijkstra_ci
end

function sparse_random_graph(n::Int, edge_factor::Float64 = 2.0)
    edges = OptimSPath.Edge[]
    weights = Float64[]
    m = max(n - 1, round(Int, edge_factor * n))

    # Ensure connectivity with a random spanning tree
    for i in 2:n
        parent = rand(1:(i - 1))
        push!(edges, OptimSPath.Edge(parent, i, length(edges) + 1))
        push!(weights, rand() * 9 + 1) # [1,10]
    end

    # Add additional random edges
    while length(edges) < m
        u = rand(1:n)
        v = rand(1:n)
        u == v && continue
        push!(edges, OptimSPath.Edge(u, v, length(edges) + 1))
        push!(weights, rand() * 9 + 1)
    end

    return OptimSPath.DMYGraph(n, edges, weights)
end

function grid_graph(size::Int)
    n = size * size
    edges = OptimSPath.Edge[]
    weights = Float64[]

    for i in 1:size
        for j in 1:size
            v = (i - 1) * size + j
            if j < size
                push!(edges, OptimSPath.Edge(v, v + 1, length(edges) + 1))
                push!(weights, rand() * 2 + 1)
            end
            if i < size
                push!(edges, OptimSPath.Edge(v, v + size, length(edges) + 1))
                push!(weights, rand() * 2 + 1)
            end
        end
    end

    return OptimSPath.DMYGraph(n, edges, weights)
end

function layered_graph(layers::Int, layer_size::Int)
    n = layers * layer_size
    edges = OptimSPath.Edge[]
    weights = Float64[]

    for layer in 1:(layers - 1)
        for i in 1:layer_size
            for j in 1:layer_size
                u = (layer - 1) * layer_size + i
                v = layer * layer_size + j
                if rand() < 0.35
                    push!(edges, OptimSPath.Edge(u, v, length(edges) + 1))
                    push!(weights, rand() * 5 + 1)
                end
            end
        end
    end

    # Guarantee at least one chain through the layers
    for layer in 1:(layers - 1)
        u = (layer - 1) * layer_size + 1
        v = layer * layer_size + 1
        push!(edges, OptimSPath.Edge(u, v, length(edges) + 1))
        push!(weights, 1.0)
    end

    return OptimSPath.DMYGraph(n, edges, weights)
end

function pretty(ci)
    return ci == 0 ? "±0.00" : "±$(round(ci, digits = 2))"
end

results = BenchmarkResult[]

println("Sparse random graphs (m ≈ 2n)")
println("-"^72)
for n in (200, 500, 1000, 2000, 5000)
    graph = sparse_random_graph(n, 2.0)
    dmy_mean, dmy_ci, dijkstra_mean, dijkstra_ci = benchmark_graph(graph, 1)
    push!(
        results,
        BenchmarkResult(
            n,
            length(graph.edges),
            dmy_mean,
            dmy_ci,
            dijkstra_mean,
            dijkstra_ci,
        ),
    )
    speedup = dijkstra_mean / dmy_mean
    println(
        @sprintf(
            "n=%4d, edges=%6d | DMY %.3f ms (%s) | Dijkstra %.3f ms (%s) | Speedup %.2fx",
            n,
            length(graph.edges),
            dmy_mean,
            pretty(dmy_ci),
            dijkstra_mean,
            pretty(dijkstra_ci),
            speedup,
        ),
    )
end
println()

println("Grid graphs")
println("-"^72)
for size in (20, 30, 40, 50)
    graph = grid_graph(size)
    dmy_mean, dmy_ci, dijkstra_mean, dijkstra_ci = benchmark_graph(graph, 1)
    speedup = dijkstra_mean / dmy_mean
    println(
        @sprintf(
            "%2dx%-2d grid (n=%4d) | DMY %.3f ms (%s) | Dijkstra %.3f ms (%s) | Speedup %.2fx",
            size,
            size,
            graph.n_vertices,
            dmy_mean,
            pretty(dmy_ci),
            dijkstra_mean,
            pretty(dijkstra_ci),
            speedup,
        ),
    )
end
println()

println("Layered graphs")
println("-"^72)
for (layers, layer_size) in ((10, 12), (15, 15), (20, 20), (25, 25))
    graph = layered_graph(layers, layer_size)
    dmy_mean, dmy_ci, dijkstra_mean, dijkstra_ci = benchmark_graph(graph, 1)
    speedup = dijkstra_mean / dmy_mean
    println(
        @sprintf(
            "%2d layers × %-2d (n=%4d) | DMY %.3f ms (%s) | Dijkstra %.3f ms (%s) | Speedup %.2fx",
            layers,
            layer_size,
            graph.n_vertices,
            dmy_mean,
            pretty(dmy_ci),
            dijkstra_mean,
            pretty(dijkstra_ci),
            speedup,
        ),
    )
end
println()

open(RESULT_PATH, "w") do io
    timestamp = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ")
    println(io, "# DMY Algorithm Benchmark Results")
    println(io, "# Generated: $timestamp")
    println(io, "# Fields: Size,Edges,DMY_ms,DMY_CI_ms,Dijkstra_ms,Dijkstra_CI_ms,Speedup")
    for r in results
        speedup = r.dijkstra_ms / r.dmy_ms
        println(
            io,
            @sprintf(
                "%d,%d,%.6f,%.6f,%.6f,%.6f,%.4f",
                r.size,
                r.edges,
                r.dmy_ms,
                r.dmy_ci,
                r.dijkstra_ms,
                r.dijkstra_ci,
                speedup,
            ),
        )
    end
end
println("Saved tabulated sparse-random results to $(abspath(RESULT_PATH)).")

try
    @eval begin
        using Plots
        function plot_results(results)
            sizes = [r.size for r in results]
            dmy = [r.dmy_ms for r in results]
            dijkstra = [r.dijkstra_ms for r in results]
            plot(
                sizes,
                [dmy dijkstra],
                xlabel = "Number of vertices (n)",
                ylabel = "Runtime (ms)",
                label = ["DMY" "Dijkstra"],
                marker = [:circle :square],
                linewidth = 2,
                markersize = 5,
                yscale = :log10,
                xticks = sizes,
                title = "Sparse random graphs (m ≈ 2n)",
                legend = :topleft,
                size = (1400, 900),
            )
        end

        fig = plot_results(results)
        savefig(fig, joinpath(@__DIR__, "benchmark_results.png"))
        println("Saved plot to ", abspath(joinpath(@__DIR__, "benchmark_results.png")))
    end
catch err
    @warn "Skipping plot generation — plotting stack not available" exception=err
end

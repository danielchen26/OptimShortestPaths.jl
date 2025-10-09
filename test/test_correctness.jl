"""
Comprehensive correctness validation tests comparing DMY with Dijkstra's algorithm.
"""

const INF = OptimShortestPaths.INF

@testset "Correctness Validation Tests" begin
    
    @testset "Small Graph Correctness" begin
        # Test on various small graphs
        test_graphs = [
            # Simple chain
            (4, [(1,2,1.0), (2,3,2.0), (3,4,1.5)]),
            # Tree structure
            (5, [(1,2,1.0), (1,3,2.0), (2,4,1.5), (2,5,2.5)]),
            # Graph with cycles
            (4, [(1,2,1.0), (2,3,2.0), (3,4,1.0), (1,4,5.0), (2,4,3.0)]),
            # Dense graph
            (4, [(1,2,1.0), (1,3,2.0), (1,4,4.0), (2,3,1.5), (2,4,2.5), (3,4,1.0)]),
            # Star graph
            (5, [(1,2,1.0), (1,3,1.0), (1,4,1.0), (1,5,1.0)]),
            # Disconnected components
            (6, [(1,2,1.0), (2,3,1.0), (4,5,2.0), (5,6,1.5)])
        ]
        
        for (n_vertices, edge_list) in test_graphs
            graph = create_simple_graph(n_vertices, edge_list)
            
            for source in 1:n_vertices
                dmy_dist = dmy_sssp!(graph, source)
                dijkstra_dist = simple_dijkstra(graph, source)
                
                # Check that distances match exactly
                for i in 1:n_vertices
                    # Handle Inf values specially to avoid NaN from Inf - Inf
                    if isinf(dmy_dist[i]) && isinf(dijkstra_dist[i])
                        @test true  # Both are Inf, which is correct
                    elseif isnan(dmy_dist[i]) || isnan(dijkstra_dist[i])
                        @test false  # NaN values indicate an error
                    else
                        # Handle INF - INF = NaN case
                if dmy_dist[i] == INF && dijkstra_dist[i] == INF
                    @test true  # Both unreachable
                else
                    @test abs(dmy_dist[i] - dijkstra_dist[i]) < 1e-10
                end
                    end
                end
                
                # Test with parents
                dmy_dist_p, dmy_parent = dmy_sssp_with_parents!(graph, source)
                @test dmy_dist_p == dmy_dist
                
                # Verify path reconstruction gives correct distances
                for target in 1:n_vertices
                    if dmy_dist[target] < INF
                        path = reconstruct_path(dmy_parent, source, target)
                        @test !isempty(path)
                        @test path[1] == source
                        @test path[end] == target
                        @test abs(path_length(path, graph) - dmy_dist[target]) < 1e-10
                    end
                end
            end
        end
    end
    
    @testset "Random Graph Correctness" begin
        # Test on randomly generated graphs
        for trial in 1:10
            n = rand(5:20)
            
            # Generate random edges
            edges = Edge[]
            weights = Float64[]
            
            # Ensure connectivity by creating a spanning tree first
            for i in 2:n
                parent = rand(1:(i-1))
                push!(edges, OptimShortestPaths.Edge(parent, i, length(edges)+1))
                push!(weights, rand() * 5.0 + 0.1)
            end
            
            # Add additional random edges
            num_extra_edges = rand(0:(n÷2))
            for _ in 1:num_extra_edges
                u = rand(1:n)
                v = rand(1:n)
                if u != v
                    push!(edges, OptimShortestPaths.Edge(u, v, length(edges)+1))
                    push!(weights, rand() * 5.0 + 0.1)
                end
            end
            
            graph = OptimShortestPaths.DMYGraph(n, edges, weights)
            
            # Test from multiple sources
            test_sources = unique([1, rand(1:n), rand(1:n)])
            for source in test_sources
                dmy_dist = dmy_sssp!(graph, source)
                dijkstra_dist = simple_dijkstra(graph, source)
                
                for i in 1:n
                    # Handle INF - INF = NaN case
                if dmy_dist[i] == INF && dijkstra_dist[i] == INF
                    @test true  # Both unreachable
                else
                    @test abs(dmy_dist[i] - dijkstra_dist[i]) < 1e-10
                end
                end
                
                # Test bounded version
                if any(d < INF for d in dmy_dist)
                    max_finite_dist = maximum(d for d in dmy_dist if d < INF)
                    bound = max_finite_dist / 2
                    
                    bounded_dist = dmy_sssp_bounded!(graph, source, bound)
                    for i in 1:n
                        if dmy_dist[i] <= bound
                            @test abs(bounded_dist[i] - dmy_dist[i]) < 1e-10
                        else
                            @test bounded_dist[i] == INF
                        end
                    end
                end
            end
        end
    end
    
    @testset "Edge Case Correctness" begin
        # Single vertex
        single_graph = OptimShortestPaths.DMYGraph(1, Edge[], Float64[])
        dmy_single = dmy_sssp!(single_graph, 1)
        dijkstra_single = simple_dijkstra(single_graph, 1)
        @test dmy_single == dijkstra_single == [0.0]
        
        # Two vertices, no edges
        two_graph = OptimShortestPaths.DMYGraph(2, Edge[], Float64[])
        dmy_two = dmy_sssp!(two_graph, 1)
        dijkstra_two = simple_dijkstra(two_graph, 1)
        @test dmy_two == dijkstra_two == [0.0, INF]
        
        # Disconnected graph
        edges_disconnected = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(3, 4, 2)]
        weights_disconnected = [1.0, 2.0]
        disconnected_graph = OptimShortestPaths.DMYGraph(4, edges_disconnected, weights_disconnected)
        
        for source in 1:4
            dmy_disc = dmy_sssp!(disconnected_graph, source)
            dijkstra_disc = simple_dijkstra(disconnected_graph, source)
            
            for i in 1:4
                if isnan(dmy_disc[i]) || isnan(dijkstra_disc[i]) || 
                   isinf(dmy_disc[i]) || isinf(dijkstra_disc[i])
                    # For disconnected vertices, both should be either Inf or NaN
                    @test (isnan(dmy_disc[i]) || isinf(dmy_disc[i])) && 
                          (isnan(dijkstra_disc[i]) || isinf(dijkstra_disc[i]))
                else
                    @test abs(dmy_disc[i] - dijkstra_disc[i]) < 1e-10
                end
            end
        end
        
        # Graph with zero weights
        zero_edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2)]
        zero_weights = [0.0, 1.0]
        zero_graph = OptimShortestPaths.DMYGraph(3, zero_edges, zero_weights)
        
        dmy_zero = dmy_sssp!(zero_graph, 1)
        dijkstra_zero = simple_dijkstra(zero_graph, 1)
        
        for i in 1:3
            @test abs(dmy_zero[i] - dijkstra_zero[i]) < 1e-10
        end
        
        # Graph with self-loops
        self_edges = [OptimShortestPaths.Edge(1, 1, 1), OptimShortestPaths.Edge(1, 2, 2), OptimShortestPaths.Edge(2, 2, 3)]
        self_weights = [0.5, 1.0, 0.3]
        self_graph = OptimShortestPaths.DMYGraph(2, self_edges, self_weights)
        
        dmy_self = dmy_sssp!(self_graph, 1)
        dijkstra_self = simple_dijkstra(self_graph, 1)
        
        for i in 1:2
            @test abs(dmy_self[i] - dijkstra_self[i]) < 1e-10
        end
    end
    
    @testset "Path Reconstruction Correctness" begin
        # Test that reconstructed paths have correct lengths
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2), OptimShortestPaths.Edge(2, 4, 3), OptimShortestPaths.Edge(3, 4, 4)]
        weights = [1.0, 3.0, 2.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        dist, parent = dmy_sssp_with_parents!(graph, 1)
        
        for target in 2:4
            if dist[target] < INF
                path = reconstruct_path(parent, 1, target)
                @test !isempty(path)
                @test path[1] == 1
                @test path[end] == target
                
                # Verify path length matches distance
                computed_length = path_length(path, graph)
                @test abs(computed_length - dist[target]) < 1e-10
                
                # Verify path is valid (all consecutive vertices are connected)
                for i in 1:(length(path)-1)
                    @test is_connected(graph, path[i], path[i+1])
                end
            end
        end
        
        # Test shortest path tree
        tree = shortest_path_tree(parent, 1)
        for (vertex, path) in tree
            @test path[1] == 1
            @test path[end] == vertex
            @test abs(path_length(path, graph) - dist[vertex]) < 1e-10
        end
    end
    
    @testset "Pharmaceutical Network Correctness" begin
        # Test drug-target network
        drugs = ["D1", "D2"]
        targets = ["T1", "T2"]
        interactions = [0.8 0.2; 0.3 0.9]
        
        network = create_drug_target_network(drugs, targets, interactions)
        
        # Verify DMY gives same results as Dijkstra on underlying graph
        for source in 1:network.graph.n_vertices
            dmy_dist = dmy_sssp!(network.graph, source)
            dijkstra_dist = simple_dijkstra(network.graph, source)
            
            for i in 1:network.graph.n_vertices
                # Handle INF - INF = NaN case
                if dmy_dist[i] == INF && dijkstra_dist[i] == INF
                    @test true  # Both unreachable
                else
                    @test abs(dmy_dist[i] - dijkstra_dist[i]) < 1e-10
                end
            end
        end
        
        # Test metabolic pathway
        metabolites = ["M1", "M2", "M3"]
        reactions = ["R1", "R2"]
        costs = [1.0, 2.0]
        reaction_network = [("M1", "R1", "M2"), ("M2", "R2", "M3")]
        
        pathway = create_metabolic_pathway(metabolites, reactions, costs, reaction_network)
        
        for source in 1:pathway.graph.n_vertices
            dmy_dist = dmy_sssp!(pathway.graph, source)
            dijkstra_dist = simple_dijkstra(pathway.graph, source)
            
            for i in 1:pathway.graph.n_vertices
                # Handle INF - INF = NaN case
                if dmy_dist[i] == INF && dijkstra_dist[i] == INF
                    @test true  # Both unreachable
                else
                    @test abs(dmy_dist[i] - dijkstra_dist[i]) < 1e-10
                end
            end
        end
        
        # Test treatment protocol
        treatments = ["T1", "T2", "T3"]
        costs = [100.0, 200.0, 150.0]
        efficacy = [1.0, 0.9, 0.8]
        transitions = [("T1", "T2", 50.0), ("T2", "T3", 30.0)]
        
        protocol = create_treatment_protocol(treatments, costs, efficacy, transitions)
        
        for source in 1:protocol.graph.n_vertices
            dmy_dist = dmy_sssp!(protocol.graph, source)
            dijkstra_dist = simple_dijkstra(protocol.graph, source)
            
            for i in 1:protocol.graph.n_vertices
                # Handle INF - INF = NaN case
                if dmy_dist[i] == INF && dijkstra_dist[i] == INF
                    @test true  # Both unreachable
                else
                    @test abs(dmy_dist[i] - dijkstra_dist[i]) < 1e-10
                end
            end
        end
    end
    
    @testset "Bounded Algorithm Correctness" begin
        # Test bounded version gives correct results within bound
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(3, 4, 3)]
        weights = [1.0, 2.0, 3.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        # Test with various bounds
        bounds = [1.5, 3.5, 6.5, 10.0]
        
        for bound in bounds
            bounded_dist = dmy_sssp_bounded!(graph, 1, bound)
            unbounded_dist = dmy_sssp!(graph, 1)
            
            for i in 1:4
                if unbounded_dist[i] <= bound
                    @test abs(bounded_dist[i] - unbounded_dist[i]) < 1e-10
                else
                    @test bounded_dist[i] == INF
                end
            end
        end
        
        # Test with bound of 0 (only source reachable)
        zero_bound_dist = dmy_sssp_bounded!(graph, 1, 0.0)
        @test zero_bound_dist[1] == 0.0
        @test all(zero_bound_dist[2:end] .== INF)
    end
    
    @testset "Comparison Function Correctness" begin
        # Test the compare_with_dijkstra function
        test_cases = [
            # Simple cases
            (3, [(1,2,1.0), (2,3,1.0)]),
            (4, [(1,2,1.0), (1,3,2.0), (2,4,1.0), (3,4,1.0)]),
            # Complex case
            (5, [(1,2,1.0), (1,3,4.0), (2,3,2.0), (2,4,5.0), (3,4,1.0), (4,5,1.0)])
        ]
        
        for (n, edge_list) in test_cases
            graph = create_simple_graph(n, edge_list)
            
            for source in 1:min(n, 3)  # Test first few sources
                comparison = compare_with_dijkstra(graph, source)
                
                @test haskey(comparison, "dmy_time")
                @test haskey(comparison, "dijkstra_time")
                @test haskey(comparison, "speedup")
                @test haskey(comparison, "results_match")
                @test haskey(comparison, "discrepancies")
                @test haskey(comparison, "max_difference")
                
                @test comparison["results_match"] == true
                @test isempty(comparison["discrepancies"])
                @test comparison["max_difference"] < 1e-10
                @test comparison["dmy_time"] >= 0
                @test comparison["dijkstra_time"] >= 0
                @test comparison["speedup"] > 0
            end
        end
    end
    
    @testset "Large Scale Correctness" begin
        # Test correctness on larger graphs
        n = 50
        edges = Edge[]
        weights = Float64[]
        
        # Create a more complex graph structure
        # Chain backbone
        for i in 1:(n-1)
            push!(edges, OptimShortestPaths.Edge(i, i+1, length(edges)+1))
            push!(weights, rand() * 2.0 + 0.5)
        end
        
        # Add cross connections
        for i in 1:5:n-10
            for j in 1:2
                target = min(i + 5 + j, n)
                if target > i
                    push!(edges, OptimShortestPaths.Edge(i, target, length(edges)+1))
                    push!(weights, rand() * 3.0 + 1.0)
                end
            end
        end
        
        # Add some backward edges
        for i in 10:10:n-5
            source = i
            target = max(1, i - 5)
            push!(edges, OptimShortestPaths.Edge(source, target, length(edges)+1))
            push!(weights, rand() * 4.0 + 2.0)
        end
        
        large_graph = OptimShortestPaths.DMYGraph(n, edges, weights)
        
        # Test on multiple sources
        test_sources = [1, n÷4, n÷2, 3*n÷4, n]
        for source in test_sources
            if source <= n
                comparison = compare_with_dijkstra(large_graph, source)
                @test comparison["results_match"] == true
                @test comparison["max_difference"] < 1e-10
            end
        end
    end
    
    @testset "Stress Testing" begin
        # Test with various challenging graph structures
        
        # Dense graph
        n_dense = 15
        dense_edges = Edge[]
        dense_weights = Float64[]
        
        for i in 1:n_dense
            for j in 1:n_dense
                if i != j && rand() < 0.3  # 30% edge probability
                    push!(dense_edges, OptimShortestPaths.Edge(i, j, length(dense_edges)+1))
                    push!(dense_weights, rand() * 5.0 + 0.1)
                end
            end
        end
        
        if !isempty(dense_edges)
            dense_graph = OptimShortestPaths.DMYGraph(n_dense, dense_edges, dense_weights)
            comparison_dense = compare_with_dijkstra(dense_graph, 1)
            @test comparison_dense["results_match"] == true
        end
        
        # Graph with many zero weights
        zero_edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(3, 4, 3), OptimShortestPaths.Edge(1, 4, 4)]
        zero_weights = [0.0, 0.0, 1.0, 0.0]
        zero_graph = OptimShortestPaths.DMYGraph(4, zero_edges, zero_weights)
        
        comparison_zero = compare_with_dijkstra(zero_graph, 1)
        @test comparison_zero["results_match"] == true
        
        # Graph with uniform weights
        uniform_edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(3, 4, 3), OptimShortestPaths.Edge(1, 3, 4), OptimShortestPaths.Edge(2, 4, 5)]
        uniform_weights = [1.0, 1.0, 1.0, 1.0, 1.0]
        uniform_graph = OptimShortestPaths.DMYGraph(4, uniform_edges, uniform_weights)
        
        comparison_uniform = compare_with_dijkstra(uniform_graph, 1)
        @test comparison_uniform["results_match"] == true
    end
    
end
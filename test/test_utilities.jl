"""
Comprehensive tests for utility functions including path reconstruction.
"""

const INF = OptimShortestPaths.INF

@testset "Utility Functions Tests" begin
    
    @testset "Path Reconstruction" begin
        # Create test graph and run DMY to get parent array
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(1, 3, 3), OptimShortestPaths.Edge(3, 4, 4)]
        weights = [1.0, 1.0, 3.0, 2.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        dist, parent = dmy_sssp_with_parents!(graph, 1)
        
        # Test path reconstruction
        path_1_to_4 = reconstruct_path(parent, 1, 4)
        @test !isempty(path_1_to_4)
        @test path_1_to_4[1] == 1
        @test path_1_to_4[end] == 4
        
        # Verify path length matches computed distance
        path_length_computed = path_length(path_1_to_4, graph)
        @test abs(path_length_computed - dist[4]) < 1e-10
        
        # Test path to unreachable vertex
        unreachable_parent = [0, 1, 0, 0]  # Only vertex 2 reachable from 1
        empty_path = reconstruct_path(unreachable_parent, 1, 3)
        @test isempty(empty_path)
        
        # Test path to source itself
        self_path = reconstruct_path(parent, 1, 1)
        @test self_path == [1]
        
        # Test path reconstruction for all vertices
        for target in 1:4
            if dist[target] < INF
                path = reconstruct_path(parent, 1, target)
                @test !isempty(path)
                @test path[1] == 1
                @test path[end] == target
            end
        end
    end
    
    @testset "Shortest Path Tree" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2), OptimShortestPaths.Edge(2, 4, 3)]
        weights = [2.0, 3.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        dist, parent = dmy_sssp_with_parents!(graph, 1)
        tree = shortest_path_tree(parent, 1)
        
        @test haskey(tree, 1)  # Source
        @test haskey(tree, 2)  # Reachable
        @test haskey(tree, 3)  # Reachable
        @test haskey(tree, 4)  # Reachable
        
        @test tree[1] == [1]
        @test tree[2] == [1, 2]
        @test tree[3] == [1, 3]
        @test tree[4] == [1, 2, 4]
        
        # Test with disconnected graph
        edges_disc = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(3, 4, 2)]
        weights_disc = [1.0, 2.0]
        graph_disc = OptimShortestPaths.DMYGraph(4, edges_disc, weights_disc)
        
        dist_disc, parent_disc = dmy_sssp_with_parents!(graph_disc, 1)
        tree_disc = shortest_path_tree(parent_disc, 1)
        
        @test haskey(tree_disc, 1)
        @test haskey(tree_disc, 2)
        @test !haskey(tree_disc, 3)  # Unreachable
        @test !haskey(tree_disc, 4)  # Unreachable
    end
    
    @testset "Path Length Calculation" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(3, 4, 3)]
        weights = [1.5, 2.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        # Valid path
        path = [1, 2, 3, 4]
        length_computed = path_length(path, graph)
        @test length_computed == 4.5  # 1.5 + 2.0 + 1.0
        
        # Single vertex path
        single_path = [2]
        @test path_length(single_path, graph) == 0.0
        
        # Empty path
        @test path_length(Int[], graph) == 0.0
        
        # Two vertex path
        two_path = [1, 2]
        @test path_length(two_path, graph) == 1.5
        
        # Invalid path (non-existent edge)
        invalid_path = [1, 4]  # No direct edge from 1 to 4
        @test path_length(invalid_path, graph) == INF
        
        # Path with invalid vertex
        invalid_vertex_path = [1, 5]  # Vertex 5 doesn't exist
        @test path_length(invalid_vertex_path, graph) == INF
    end
    
    @testset "Shortest Path Verification" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(1, 3, 3)]
        weights = [1.0, 1.0, 3.0]
        graph = OptimShortestPaths.DMYGraph(3, edges, weights)
        
        dist = dmy_sssp!(graph, 1)
        
        # Verify correct distances
        @test verify_shortest_path(graph, dist, 1, 1) == true  # Source to itself
        @test verify_shortest_path(graph, dist, 1, 2) == true
        @test verify_shortest_path(graph, dist, 1, 3) == true
        
        # Test with incorrect distance (longer than actual)
        wrong_dist = copy(dist)
        wrong_dist[3] = 2.5  # Should be 2.0
        @test verify_shortest_path(graph, wrong_dist, 1, 3) == false
        
        # Test with unreachable vertex
        unreachable_dist = [0.0, INF, INF]
        @test verify_shortest_path(graph, unreachable_dist, 1, 2) == true  # INF is valid for unreachable
        
        # Test invalid source/target
        @test verify_shortest_path(graph, dist, 0, 1) == false
        @test verify_shortest_path(graph, dist, 1, 4) == false
    end
    
    @testset "Dijkstra Comparison" begin
        # Create test graph
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2), OptimShortestPaths.Edge(2, 4, 3), OptimShortestPaths.Edge(3, 4, 4), OptimShortestPaths.Edge(2, 3, 5)]
        weights = [1.0, 4.0, 2.0, 1.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        comparison = compare_with_dijkstra(graph, 1)
        
        @test haskey(comparison, "dmy_time")
        @test haskey(comparison, "dijkstra_time")
        @test haskey(comparison, "speedup")
        @test haskey(comparison, "results_match")
        @test haskey(comparison, "discrepancies")
        @test haskey(comparison, "max_difference")
        
        # Results should match
        @test comparison["results_match"] == true
        @test isempty(comparison["discrepancies"])
        @test comparison["max_difference"] < 1e-10
        
        # Times should be non-negative
        @test comparison["dmy_time"] >= 0
        @test comparison["dijkstra_time"] >= 0
        @test comparison["speedup"] > 0
        
        # Test on different sources
        comparison2 = compare_with_dijkstra(graph, 2)
        @test comparison2["results_match"] == true
    end
    
    @testset "Simple Dijkstra Implementation" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(1, 3, 3)]
        weights = [1.0, 1.0, 3.0]
        graph = OptimShortestPaths.DMYGraph(3, edges, weights)
        
        dijkstra_dist = simple_dijkstra(graph, 1)
        
        @test dijkstra_dist[1] == 0.0
        @test dijkstra_dist[2] == 1.0
        @test dijkstra_dist[3] == 2.0  # Via path 1->2->3, not direct 1->3
        
        # Test with unreachable vertices
        disconnected_edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(3, 4, 2)]
        disconnected_weights = [1.0, 1.0]
        disconnected_graph = OptimShortestPaths.DMYGraph(4, disconnected_edges, disconnected_weights)
        
        dijkstra_disconnected = simple_dijkstra(disconnected_graph, 1)
        @test dijkstra_disconnected[1] == 0.0
        @test dijkstra_disconnected[2] == 1.0
        @test dijkstra_disconnected[3] == INF
        @test dijkstra_disconnected[4] == INF
        
        # Test single vertex graph
        single_graph = OptimShortestPaths.DMYGraph(1, Edge[], Float64[])
        dijkstra_single = simple_dijkstra(single_graph, 1)
        @test dijkstra_single == [0.0]
    end
    
    @testset "Graph Reachability" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(4, 5, 3)]
        weights = [1.0, 1.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(5, edges, weights)
        
        reachable_from_1 = graph_reachability(graph, 1)
        @test 1 in reachable_from_1
        @test 2 in reachable_from_1
        @test 3 in reachable_from_1
        @test !(4 in reachable_from_1)
        @test !(5 in reachable_from_1)
        
        reachable_from_4 = graph_reachability(graph, 4)
        @test 4 in reachable_from_4
        @test 5 in reachable_from_4
        @test !(1 in reachable_from_4)
        @test !(2 in reachable_from_4)
        @test !(3 in reachable_from_4)
        
        # Test single vertex
        reachable_from_2 = graph_reachability(graph, 2)
        @test 2 in reachable_from_2
        @test 3 in reachable_from_2
        @test !(1 in reachable_from_2)
        
        # Test invalid source
        @test_throws BoundsError graph_reachability(graph, 0)
        @test_throws BoundsError graph_reachability(graph, 6)
    end
    
    @testset "Distance Results Formatting" begin
        dist = [0.0, 1.5, INF, 3.0]
        formatted = format_distance_results(dist, 1)
        
        @test occursin("Shortest distances from vertex 1", formatted)
        @test occursin("Vertex 1: 0.0", formatted)
        @test occursin("Vertex 2: 1.5", formatted)
        @test occursin("Vertex 3: unreachable", formatted)
        @test occursin("Vertex 4: 3.0", formatted)
        @test occursin("Reachable vertices: 3 / 4", formatted)
        
        # Test with all reachable
        all_reachable = [0.0, 1.0, 2.0]
        formatted_all = format_distance_results(all_reachable, 1)
        @test occursin("Reachable vertices: 3 / 3", formatted_all)
        
        # Test with all unreachable except source
        mostly_unreachable = [0.0, INF, INF, INF]
        formatted_unreachable = format_distance_results(mostly_unreachable, 1)
        @test occursin("Reachable vertices: 1 / 4", formatted_unreachable)
    end
    
    @testset "Path Reconstruction Edge Cases" begin
        # Test cycle detection (shouldn't happen with correct algorithm)
        cyclic_parent = [2, 3, 1, 0]  # Creates cycle 1->2->3->1
        # Path from 1 to 3 stops early due to source detection, not triggering cycle check
        # Test with a path that would go through the full cycle
        cyclic_parent2 = [2, 3, 1, 1]  # Creates cycle 1->2->3->1, vertex 4 points to 1
        @test_throws ErrorException reconstruct_path(cyclic_parent2, 4, 2)
        
        # Test invalid vertex indices
        parent = [0, 1, 2]
        @test_throws BoundsError reconstruct_path(parent, 0, 2)
        @test_throws BoundsError reconstruct_path(parent, 1, 4)
        
        # Test path that doesn't reach source
        invalid_parent = [0, 3, 0]  # Vertex 2 has parent 3, but 3 has no parent
        invalid_path = reconstruct_path(invalid_parent, 1, 2)
        @test isempty(invalid_path)
        
        # Test very long path (should not cause cycle detection)
        long_parent = [0, 1, 2, 3, 4]  # Chain 1->2->3->4->5
        long_path = reconstruct_path(long_parent, 1, 5)
        @test long_path == [1, 2, 3, 4, 5]
        
        # Test path reconstruction with gaps
        gap_parent = [0, 1, 0, 2]  # 1->2, 3 isolated, 2->4
        gap_path = reconstruct_path(gap_parent, 1, 4)
        @test gap_path == [1, 2, 4]
        
        gap_path_isolated = reconstruct_path(gap_parent, 1, 3)
        @test isempty(gap_path_isolated)  # 3 is not reachable from 1
    end
    
    @testset "Utility Function Integration" begin
        # Test that all utility functions work together
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(1, 4, 3), OptimShortestPaths.Edge(4, 3, 4)]
        weights = [1.0, 2.0, 4.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        # Run DMY algorithm
        dist, parent = dmy_sssp_with_parents!(graph, 1)
        
        # Build shortest path tree
        tree = shortest_path_tree(parent, 1)
        
        # Verify all paths in tree
        for (vertex, path) in tree
            @test path[1] == 1
            @test path[end] == vertex
            @test path_length(path, graph) ≈ dist[vertex]
        end
        
        # Verify shortest path verification
        for vertex in 1:4
            @test verify_shortest_path(graph, dist, 1, vertex) == true
        end
        
        # Check reachability matches tree
        reachable = graph_reachability(graph, 1)
        for vertex in keys(tree)
            @test vertex in reachable
        end
        
        # Compare with Dijkstra
        comparison = compare_with_dijkstra(graph, 1)
        @test comparison["results_match"] == true
    end
    
end
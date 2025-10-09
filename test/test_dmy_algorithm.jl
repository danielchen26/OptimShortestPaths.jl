using Test

const INF = OptimShortestPaths.INF

@testset "DMY Algorithm Tests" begin
    
    @testset "Basic DMY Algorithm" begin
        # Create a simple test graph: 1 -> 2 -> 3 -> 4
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(3, 4, 3), OptimShortestPaths.Edge(1, 4, 4)]
        weights = [1.0, 2.0, 1.5, 5.0]  # Path 1->2->3->4 costs 4.5, direct 1->4 costs 5.0
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        # Test DMY algorithm
        dist = dmy_sssp!(graph, 1)
        
        @test dist[1] == 0.0
        @test dist[2] == 1.0
        @test dist[3] == 3.0
        @test dist[4] == 4.5  # Should take shorter path 1->2->3->4
        
        # Test with different source
        dist2 = dmy_sssp!(graph, 2)
        @test dist2[2] == 0.0
        @test dist2[3] == 2.0
        @test dist2[4] == 3.5
        @test dist2[1] == INF  # Unreachable from 2
    end

    @testset "Deterministic Frontier Ordering" begin
        edges = [
            OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2),
            OptimShortestPaths.Edge(2, 4, 3), OptimShortestPaths.Edge(3, 4, 4)
        ]
        weights = [1.0, 1.0, 1.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)

        dist_ref, parent_ref = dmy_sssp_with_parents!(graph, 1)
        for _ in 1:5
            dist, parent = dmy_sssp_with_parents!(graph, 1)
            @test dist == dist_ref
            @test parent == parent_ref
        end
    end
    
    @testset "DMY with Parents" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2), OptimShortestPaths.Edge(2, 4, 3), OptimShortestPaths.Edge(3, 4, 4)]
        weights = [2.0, 3.0, 1.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        dist, parent = dmy_sssp_with_parents!(graph, 1)
        
        @test dist[1] == 0.0
        @test dist[2] == 2.0
        @test dist[3] == 3.0
        @test dist[4] == 3.0  # min(2+1, 3+1) = 3 via path 1->2->4
        
        @test parent[1] == 0  # Source has no parent
        @test parent[2] == 1
        @test parent[3] == 1
        @test parent[4] == 2  # Shortest path to 4 is via 2
    end
    
    @testset "Bounded DMY Algorithm" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(3, 4, 3)]
        weights = [1.0, 2.0, 3.0]  # Total path length is 6.0
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        # Test with bound that allows all paths
        dist_unbounded = dmy_sssp_bounded!(graph, 1, 10.0)
        @test dist_unbounded[4] == 6.0
        
        # Test with bound that cuts off some paths
        dist_bounded = dmy_sssp_bounded!(graph, 1, 4.0)
        @test dist_bounded[3] == 3.0  # Still reachable
        @test dist_bounded[4] == INF  # Beyond bound

        # Paths whose length equals the bound must remain reachable
        equal_bound_graph = OptimShortestPaths.DMYGraph(3,
            [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2)],
            [1.5, 2.5])
        equal_bound_dist = dmy_sssp_bounded!(equal_bound_graph, 1, 4.0)
        @test equal_bound_dist[3] == 4.0
    end
    
    @testset "Parameter Calculations" begin
        # Test pivot threshold calculation
        @test calculate_pivot_threshold(1) == 1
        @test calculate_pivot_threshold(8) == 2  # ⌈8^(1/3)⌉ = ⌈2⌉ = 2
        @test calculate_pivot_threshold(27) == 3  # ⌈27^(1/3)⌉ = ⌈3⌉ = 3
        @test calculate_pivot_threshold(64) == 4  # ⌈64^(1/3)⌉ = ⌈4⌉ = 4
        
        # Test partition parameter calculation
        @test calculate_partition_parameter(1) == 1  # max(1, ...)
        @test calculate_partition_parameter(8) >= 1
        @test calculate_partition_parameter(1000) >= 1
        
        # Test invalid inputs
        @test_throws ArgumentError calculate_pivot_threshold(0)
        @test_throws ArgumentError calculate_pivot_threshold(-1)
        @test_throws ArgumentError calculate_partition_parameter(0)
    end
    
    @testset "Algorithm Statistics" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(1, 3, 3)]
        weights = [1.0, 1.0, 3.0]
        graph = OptimShortestPaths.DMYGraph(3, edges, weights)
        
        stats = dmy_algorithm_statistics(graph, 1)
        
        @test stats["graph_vertices"] == 3
        @test stats["graph_edges"] == 3
        @test stats["source_vertex"] == 1
        @test stats["distances_computed"] == 3  # All vertices reachable
        @test stats["unreachable_vertices"] == 0
        @test haskey(stats, "runtime_seconds")
        @test haskey(stats, "max_distance")
        @test haskey(stats, "avg_distance")
        @test stats["max_distance"] == 2.0  # Distance to vertex 3
    end
    
    @testset "Input Validation" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1)]
        weights = [1.0]
        graph = OptimShortestPaths.DMYGraph(2, edges, weights)
        
        # Valid inputs
        @test validate_dmy_input(graph, 1) == true
        @test validate_dmy_input(graph, 2) == true
        
        # Invalid source vertex
        @test_throws BoundsError validate_dmy_input(graph, 0)
        @test_throws BoundsError validate_dmy_input(graph, 3)
        
        # Test with invalid graph (negative weights)
        # This should be caught by graph construction, but test validation
        @test_throws BoundsError dmy_sssp!(graph, 0)
        @test_throws BoundsError dmy_sssp!(graph, 3)
    end
    
    @testset "Edge Cases" begin
        # Single vertex graph
        single_graph = OptimShortestPaths.DMYGraph(1, OptimShortestPaths.Edge[], Float64[])
        dist_single = dmy_sssp!(single_graph, 1)
        @test dist_single == [0.0]
        
        # Disconnected graph
        edges_disconnected = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(3, 4, 2)]
        weights_disconnected = [1.0, 2.0]
        graph_disconnected = OptimShortestPaths.DMYGraph(4, edges_disconnected, weights_disconnected)
        
        dist_disconnected = dmy_sssp!(graph_disconnected, 1)
        @test dist_disconnected[1] == 0.0
        @test dist_disconnected[2] == 1.0
        @test dist_disconnected[3] == INF
        @test dist_disconnected[4] == INF
        
        # Graph with self-loops
        edges_self = [OptimShortestPaths.Edge(1, 1, 1), OptimShortestPaths.Edge(1, 2, 2)]
        weights_self = [0.5, 1.0]
        graph_self = OptimShortestPaths.DMYGraph(2, edges_self, weights_self)
        
        dist_self = dmy_sssp!(graph_self, 1)
        @test dist_self[1] == 0.0  # Self-loop doesn't improve distance
        @test dist_self[2] == 1.0
    end
    
    @testset "Large Graph Performance" begin
        # Create a larger test graph for performance validation
        n = 100
        edges = OptimShortestPaths.Edge[]
        weights = Float64[]
        
        # Create a chain graph: 1 -> 2 -> 3 -> ... -> n
        for i in 1:(n-1)
            push!(edges, OptimShortestPaths.Edge(i, i+1, i))
            push!(weights, 1.0)
        end
        
        # Add some cross edges
        for i in 1:10:n-10
            push!(edges, OptimShortestPaths.Edge(i, i+10, length(edges)+1))
            push!(weights, 5.0)
        end
        
        large_graph = OptimShortestPaths.DMYGraph(n, edges, weights)
        
        # Test that algorithm completes without error
        start_time = time()
        dist = dmy_sssp!(large_graph, 1)
        runtime = time() - start_time
        
        @test length(dist) == n
        @test dist[1] == 0.0
        # With cross edges every 10 vertices, the shortest path uses them
        # Path: 1->11->21->31->41->51->61->71->81->91->...->100
        # Cost: 9 cross edges (5.0 each) + 9 chain edges (1.0 each) = 54.0
        @test dist[n] == 54.0
        @test runtime < 1.0  # Should be fast for this size
        
        # Verify some distances
        @test dist[2] == 1.0
        @test dist[10] == 9.0  # Through chain (no cross edge to 10)
        @test dist[11] == 5.0  # Via cross edge from vertex 1
    end
    
end

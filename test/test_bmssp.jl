using Test
using DataStructures: OrderedSet

const INF = OptimShortestPaths.INF

@testset "BMSSP Tests" begin
    
    @testset "Basic BMSSP Functionality" begin
        # Create a simple test graph: 1 -> 2 -> 3 -> 4
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2), OptimShortestPaths.Edge(3, 4, 3)]
        weights = [1.0, 2.0, 1.5]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        # Initialize distance and parent arrays
        dist = fill(INF, 4)
        parent = fill(0, 4)
        dist[1] = 0.0
        
        # Test BMSSP from vertex 1
        frontier = OrderedSet([1])
        final_frontier = bmssp!(graph, dist, parent, frontier, INF, 3)
        
        @test dist[1] == 0.0
        @test dist[2] == 1.0
        @test dist[3] == 3.0
        @test dist[4] == 4.5
        @test parent[2] == 1
        @test parent[3] == 2
        @test parent[4] == 3
    end
    
    @testset "Bounded BMSSP" begin
        # Create test graph with bound
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2), OptimShortestPaths.Edge(2, 4, 3), OptimShortestPaths.Edge(3, 4, 4)]
        weights = [1.0, 5.0, 2.0, 1.0]  # Path 1->2->4 costs 3.0, path 1->3->4 costs 6.0
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        dist = fill(INF, 4)
        parent = fill(0, 4)
        dist[1] = 0.0
        
        # Test with bound that allows only shorter path
        frontier = OrderedSet([1])
        bound = 4.0  # Should allow 1->2->4 (cost 3.0) but not 1->3->4 (cost 6.0)
        final_frontier = bmssp!(graph, dist, parent, frontier, bound, 3)
        
        @test dist[1] == 0.0
        @test dist[2] == 1.0
        @test dist[3] == INF  # This should be rejected due to bound (5.0 > 4.0)
        @test dist[4] == 3.0  # Via path 1->2->4
    end
    
    @testset "Early Termination" begin
        # Create a graph where early termination should occur
        edges = [OptimShortestPaths.Edge(1, 2, 1)]
        weights = [1.0]
        graph = OptimShortestPaths.DMYGraph(2, edges, weights)
        
        dist = fill(INF, 2)
        parent = fill(0, 2)
        dist[1] = 0.0
        
        frontier = OrderedSet([1])
        # Should terminate after 1 round since no more updates possible
        stats = bmssp_with_statistics!(graph, dist, parent, frontier, INF, 10)
        
        @test stats["early_termination"] == true
        @test stats["rounds_performed"] < 10
        @test dist[2] == 1.0
    end
    
    @testset "Single Round BMSSP" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2)]
        weights = [2.0, 3.0]
        graph = OptimShortestPaths.DMYGraph(3, edges, weights)
        
        dist = fill(INF, 3)
        parent = fill(0, 3)
        dist[1] = 0.0
        
        frontier = OrderedSet([1])
        next_frontier, updated = bmssp_single_round!(graph, dist, parent, frontier, INF)
        
        @test updated == true
        @test 2 in next_frontier
        @test 3 in next_frontier
        @test dist[2] == 2.0
        @test dist[3] == 3.0
    end
    
    @testset "BMSSP Input Validation" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1)]
        weights = [1.0]
        graph = OptimShortestPaths.DMYGraph(2, edges, weights)
        
        dist = fill(INF, 2)
        parent = fill(0, 2)
        frontier = OrderedSet([1])
        
        # Test invalid k
        @test_throws ArgumentError bmssp!(graph, dist, parent, frontier, INF, 0)
        @test_throws ArgumentError bmssp!(graph, dist, parent, frontier, INF, -1)
        
        # Test invalid bound
        # bound = 0.0 is now allowed for source-only reachability
        @test_throws ArgumentError bmssp!(graph, dist, parent, frontier, -1.0, 1)
        
        # Test mismatched array sizes
        short_dist = [0.0]
        @test_throws ArgumentError bmssp!(graph, short_dist, parent, frontier, INF, 1)
        
        short_parent = [0]
        @test_throws ArgumentError bmssp!(graph, dist, short_parent, frontier, INF, 1)
        
        # Test invalid frontier vertex
        invalid_frontier = OrderedSet([3])  # Vertex 3 doesn't exist
        @test_throws ArgumentError validate_bmssp_input(graph, dist, parent, invalid_frontier, INF, 1)
    end
    
    @testset "BMSSP Statistics" begin
        # Create a more complex graph for statistics testing
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2), OptimShortestPaths.Edge(2, 4, 3), OptimShortestPaths.Edge(3, 4, 4), OptimShortestPaths.Edge(2, 3, 5)]
        weights = [1.0, 2.0, 1.0, 1.0, 0.5]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        dist = fill(INF, 4)
        parent = fill(0, 4)
        dist[1] = 0.0
        
        frontier = OrderedSet([1])
        stats = bmssp_with_statistics!(graph, dist, parent, frontier, INF, 5)
        
        @test stats["initial_frontier_size"] == 1
        @test stats["rounds_performed"] >= 1
        @test stats["total_relaxations"] >= 2  # At least the initial edges from vertex 1
        @test stats["vertices_updated"] >= 2   # At least vertices 2 and 3
        @test haskey(stats, "final_frontier_size")
        @test haskey(stats, "early_termination")
    end
    
    @testset "Count Relaxations" begin
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(1, 3, 2), OptimShortestPaths.Edge(2, 4, 3)]
        weights = [1.0, 2.0, 1.0]
        graph = OptimShortestPaths.DMYGraph(4, edges, weights)
        
        dist = fill(INF, 4)
        dist[1] = 0.0
        dist[2] = 1.0
        
        # Count relaxations from frontier containing vertices 1 and 2
        frontier = OrderedSet([1, 2])
        count = count_relaxations(graph, frontier, INF, dist)
        
        @test count == 3  # 2 edges from vertex 1, 1 edge from vertex 2
        
        # Test with bound that excludes some vertices
        count_bounded = count_relaxations(graph, frontier, 0.5, dist)
        @test count_bounded == 2  # Only vertex 1 (dist=0.0) is within bound, vertex 2 (dist=1.0) exceeds it
    end
    
end

using Test
using DataStructures: OrderedSet

@testset "Core Types Tests" begin
    
    @testset "Edge Construction" begin
        # Valid edge
        edge = OptimShortestPaths.Edge(1, 2, 1)
        @test edge.source == 1
        @test edge.target == 2
        @test edge.index == 1
        
        # Invalid edges
        @test_throws ArgumentError OptimShortestPaths.Edge(0, 2, 1)  # Invalid source
        @test_throws ArgumentError OptimShortestPaths.Edge(1, 0, 1)  # Invalid target
        @test_throws ArgumentError OptimShortestPaths.Edge(1, 2, 0)  # Invalid index
    end
    
    @testset "DMYGraph Construction" begin
        # Valid graph
        edges = [OptimShortestPaths.Edge(1, 2, 1), OptimShortestPaths.Edge(2, 3, 2)]
        weights = [1.0, 2.0]
        graph = OptimShortestPaths.DMYGraph(3, edges, weights)
        
        @test graph.n_vertices == 3
        @test length(graph.edges) == 2
        @test length(graph.weights) == 2
        @test length(graph.adjacency_list) == 3
        
        # Check adjacency list construction
        @test 1 in graph.adjacency_list[1]  # Edge 1 from vertex 1
        @test 2 in graph.adjacency_list[2]  # Edge 2 from vertex 2
        @test isempty(graph.adjacency_list[3])  # No outgoing edges from vertex 3
        
        # Invalid graphs
        @test_throws ArgumentError OptimShortestPaths.DMYGraph(0, edges, weights)  # Zero vertices
        @test_throws ArgumentError OptimShortestPaths.DMYGraph(3, edges, [1.0])    # Mismatched weights
        @test_throws ArgumentError OptimShortestPaths.DMYGraph(3, edges, [-1.0, 2.0])  # Negative weight
        
        # Invalid edge vertices
        invalid_edges = [OptimShortestPaths.Edge(1, 4, 1)]  # Vertex 4 doesn't exist
        @test_throws ArgumentError OptimShortestPaths.DMYGraph(3, invalid_edges, [1.0])
        
        # Invalid edge index
        wrong_index_edges = [OptimShortestPaths.Edge(1, 2, 2)]  # Index should be 1
        @test_throws ArgumentError OptimShortestPaths.DMYGraph(3, wrong_index_edges, [1.0])
    end
    
    @testset "Block Structure" begin
        vertices = [1, 2, 3]
        frontier = OrderedSet([1])
        bound = 5.0
        
        block = OptimShortestPaths.Block(vertices, frontier, bound)
        @test block.vertices == vertices
        @test block.frontier == frontier
        @test block.upper_bound == bound
    end
    
end

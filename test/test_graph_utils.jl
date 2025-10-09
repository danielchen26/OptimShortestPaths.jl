using Test

@testset "Graph Utils Tests" begin
    
    @testset "Graph Validation" begin
        # Valid graph
        edges = [OptimSPath.Edge(1, 2, 1), OptimSPath.Edge(2, 3, 2)]
        weights = [1.0, 2.0]
        graph = OptimSPath.DMYGraph(3, edges, weights)
        
        @test validate_graph(graph) == true
        
        # Test graph properties
        @test vertex_count(graph) == 3
        @test edge_count(graph) == 2
        @test out_degree(graph, 1) == 1
        @test out_degree(graph, 2) == 1
        @test out_degree(graph, 3) == 0
    end
    
    @testset "Edge Access Functions" begin
        edges = [OptimSPath.Edge(1, 2, 1), OptimSPath.Edge(1, 3, 2), OptimSPath.Edge(2, 3, 3)]
        weights = [1.0, 2.0, 1.5]
        graph = OptimSPath.DMYGraph(3, edges, weights)
        
        # Test outgoing edges
        outgoing_1 = outgoing_edges(graph, 1)
        @test length(outgoing_1) == 2
        @test 1 in outgoing_1
        @test 2 in outgoing_1
        
        # Test edge weight access
        @test get_edge_weight(graph, 1) == 1.0
        @test get_edge_weight(graph, 2) == 2.0
        @test get_edge_weight(graph, 3) == 1.5
        
        # Test edge access
        edge1 = get_edge(graph, 1)
        @test edge1.source == 1
        @test edge1.target == 2
        
        # Test connectivity
        @test is_connected(graph, 1, 2) == true
        @test is_connected(graph, 1, 3) == true
        @test is_connected(graph, 2, 1) == false
        @test is_connected(graph, 3, 1) == false
    end
    
    @testset "Graph Creation Utilities" begin
        edge_list = [(1, 2, 1.0), (2, 3, 2.0), (1, 3, 3.0)]
        graph = create_simple_graph(3, edge_list)
        
        @test vertex_count(graph) == 3
        @test edge_count(graph) == 3
        @test get_edge_weight(graph, 1) == 1.0
        @test get_edge_weight(graph, 2) == 2.0
        @test get_edge_weight(graph, 3) == 3.0
    end
    
    @testset "Graph Statistics" begin
        edges = [OptimSPath.Edge(1, 2, 1), OptimSPath.Edge(2, 3, 2)]
        weights = [1.0, 2.0]
        graph = OptimSPath.DMYGraph(3, edges, weights)
        
        # Test density
        density = graph_density(graph)
        expected_density = 2 / (3 * 2)  # 2 edges out of 6 possible
        @test density ≈ expected_density
        
        # Test self-loops detection
        @test has_self_loops(graph) == false
        
        # Graph with self-loop
        self_loop_edges = [OptimSPath.Edge(1, 1, 1), OptimSPath.Edge(1, 2, 2)]
        self_loop_weights = [0.5, 1.0]
        self_loop_graph = OptimSPath.DMYGraph(2, self_loop_edges, self_loop_weights)
        @test has_self_loops(self_loop_graph) == true
        
        # Test vertex degrees
        degree_info = get_vertices_by_out_degree(graph)
        @test length(degree_info) == 3
        @test degree_info[1][2] >= degree_info[2][2]  # Sorted by degree descending
    end
    
    @testset "Advanced Graph Functions" begin
        edges = [OptimSPath.Edge(1, 2, 1), OptimSPath.Edge(1, 3, 2), OptimSPath.Edge(2, 4, 3)]
        weights = [1.0, 2.0, 1.5]
        graph = OptimSPath.DMYGraph(4, edges, weights)
        
        # Test edge iteration
        edge_pairs = iterate_edges(graph, 1)
        @test length(edge_pairs) == 2
        
        # Test edge finding
        edge_idx = find_edge(graph, 1, 2)
        @test edge_idx == 1
        @test find_edge(graph, 2, 1) === nothing  # No reverse edge
        
        # Test weight lookup
        weight = get_edge_weight_between(graph, 1, 2)
        @test weight == 1.0
        @test get_edge_weight_between(graph, 2, 1) === nothing
        
        # Test target lookup
        targets = get_all_targets(graph, 1)
        @test 2 in targets
        @test 3 in targets
        @test length(targets) == 2
        
        # Test comprehensive statistics
        stats = graph_statistics(graph)
        @test stats["vertices"] == 4
        @test stats["edges"] == 3
        @test stats["max_out_degree"] == 2
        @test stats["min_out_degree"] == 0
        @test haskey(stats, "avg_out_degree")
        @test haskey(stats, "max_weight")
        @test haskey(stats, "min_weight")
        @test haskey(stats, "avg_weight")
    end
    
    @testset "Error Handling" begin
        edges = [OptimSPath.Edge(1, 2, 1)]
        weights = [1.0]
        graph = OptimSPath.DMYGraph(2, edges, weights)
        
        # Test bounds checking
        @test_throws BoundsError out_degree(graph, 0)
        @test_throws BoundsError out_degree(graph, 3)
        @test_throws BoundsError outgoing_edges(graph, 0)
        @test_throws BoundsError get_edge_weight(graph, 0)
        @test_throws BoundsError get_edge_weight(graph, 2)
        @test_throws BoundsError get_edge(graph, 0)
        @test_throws BoundsError get_all_targets(graph, 0)
        
        # Test vertex validation
        @test validate_vertex(graph, 1) == true
        @test validate_vertex(graph, 2) == true
        @test validate_vertex(graph, 0) == false
        @test validate_vertex(graph, 3) == false
    end
    
end
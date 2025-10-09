using Test
using DataStructures: OrderedSet

@testset "Pivot Selection Tests" begin
    
    @testset "Basic Pivot Selection" begin
        # Create test data
        U_tilde = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        S = OrderedSet([1])
        k = 3
        dist = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
        
        pivots = select_pivots(U_tilde, S, k, dist)
        
        # Check pivot count constraint: |P| ≤ |U_tilde| / k
        max_pivots = length(U_tilde) ÷ k
        @test length(pivots) <= max_pivots
        @test length(pivots) >= 1
        
        # Check all pivots are from U_tilde
        for pivot in pivots
            @test pivot in U_tilde
        end
        
        # Check no duplicates
        @test length(Set(pivots)) == length(pivots)
    end
    
    @testset "Edge Cases for Pivot Selection" begin
        dist = [0.0, 1.0, 2.0]
        
        # Empty U_tilde
        empty_pivots = select_pivots(Int[], OrderedSet([1]), 2, dist)
        @test isempty(empty_pivots)
        
        # Small U_tilde (smaller than k)
        small_U = [2, 3]
        small_pivots = select_pivots(small_U, OrderedSet([1]), 5, dist)
        @test length(small_pivots) == length(small_U)
        @test Set(small_pivots) == Set(small_U)
        
        # Single vertex
        single_pivots = select_pivots([2], OrderedSet([1]), 3, dist)
        @test single_pivots == [2]
    end
    
    @testset "Advanced Pivot Selection" begin
        # Create a test graph
        edges = [OPUS.Edge(1, 2, 1), OPUS.Edge(2, 3, 2), OPUS.Edge(3, 4, 3), OPUS.Edge(1, 4, 4)]
        weights = [1.0, 1.0, 1.0, 3.0]
        graph = OPUS.DMYGraph(4, edges, weights)
        
        U_tilde = [1, 2, 3, 4]
        S = OrderedSet{Int}()
        k = 2
        dist = [0.0, 1.0, 2.0, 3.0]
        
        # Use the standard select_pivots function
        pivots = select_pivots(U_tilde, S, k, dist)
        
        @test length(pivots) <= length(U_tilde) ÷ k + 1
        @test !isempty(pivots)
        
        # Validate pivot selection
        @test validate_pivot_selection(pivots, U_tilde, k)
    end
    
    @testset "Vertex Partitioning" begin
        # Test basic partitioning
        U = [1, 2, 3, 4, 5, 6, 7, 8]
        dist = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
        t = 2  # Should create 2^2 = 4 blocks
        
        blocks = partition_blocks(U, dist, t)
        
        # Check number of blocks
        @test length(blocks) <= 2^t
        @test length(blocks) >= 1
        
        # Check all vertices are included exactly once
        all_vertices = Int[]
        for block in blocks
            append!(all_vertices, block.vertices)
        end
        @test sort(all_vertices) == sort(U)
        
        # Check each block has valid frontier and bound
        for block in blocks
            @test !isempty(block.frontier)
            @test block.upper_bound > 0
            
            # Frontier should contain vertices from the block
            for v in block.frontier
                @test v in block.vertices
            end
            
            # Upper bound should be reasonable
            if !isempty(block.vertices)
                max_dist = maximum(dist[v] for v in block.vertices)
                @test block.upper_bound >= max_dist
            end
        end
    end
    
    @testset "Partitioning Edge Cases" begin
        dist = [0.0, 1.0, 2.0]
        
        # Empty vertex set
        empty_blocks = partition_blocks(Int[], dist, 2)
        @test isempty(empty_blocks)
        
        # Single vertex
        single_blocks = partition_blocks([1], dist, 2)
        @test length(single_blocks) == 1
        @test single_blocks[1].vertices == [1]
        @test 1 in single_blocks[1].frontier
        
        # More blocks requested than vertices
        U_small = [1, 2]
        many_blocks = partition_blocks(U_small, dist, 5)  # 2^5 = 32 blocks requested
        @test length(many_blocks) <= length(U_small)
    end
    
    @testset "Adaptive Partitioning" begin
        # Create test graph
        edges = [OPUS.Edge(1, 2, 1), OPUS.Edge(2, 3, 2), OPUS.Edge(3, 4, 3)]
        weights = [1.0, 1.0, 1.0]
        graph = OPUS.DMYGraph(4, edges, weights)
        
        U = [1, 2, 3, 4]
        dist = [0.0, 1.0, 2.0, 3.0]
        t = 1  # Should create 2 blocks
        
        blocks = partition_blocks_adaptive(U, dist, t, graph)
        
        @test length(blocks) <= 2^t
        @test length(blocks) >= 1
        
        # Verify all vertices included
        all_vertices = Int[]
        for block in blocks
            append!(all_vertices, block.vertices)
        end
        @test sort(all_vertices) == sort(U)
    end
    
    @testset "Pivot Selection Validation" begin
        U_tilde = [1, 2, 3, 4, 5, 6]
        k = 2
        
        # Valid pivot selection
        valid_pivots = [1, 3, 5]  # 3 pivots from 6 vertices with k=2 is valid (6/2 = 3)
        @test validate_pivot_selection(valid_pivots, U_tilde, k)
        
        # Too many pivots
        too_many_pivots = [1, 2, 3, 4]  # 4 > 6/2 = 3
        @test_throws ArgumentError validate_pivot_selection(too_many_pivots, U_tilde, k)
        
        # Pivot not in U_tilde
        invalid_pivot = [1, 7]  # 7 not in U_tilde
        @test_throws ArgumentError validate_pivot_selection(invalid_pivot, U_tilde, k)
        
        # Duplicate pivots
        duplicate_pivots = [1, 2, 1]
        @test_throws ArgumentError validate_pivot_selection(duplicate_pivots, U_tilde, k)
    end
    
    @testset "Pivot Selection Statistics" begin
        U_tilde = [1, 2, 3, 4, 5]
        S = OrderedSet([1])
        k = 2
        pivots = [1, 3]
        dist = [0.0, 1.0, 2.0, 3.0, 4.0]
        
        stats = pivot_selection_statistics(U_tilde, S, k, pivots, dist)
        
        @test stats["U_tilde_size"] == 5
        @test stats["frontier_size"] == 1
        @test stats["pivot_threshold"] == 2
        @test stats["pivots_selected"] == 2
        @test stats["reduction_ratio"] == 2/5
        
        @test haskey(stats, "min_pivot_distance")
        @test haskey(stats, "max_pivot_distance")
        @test haskey(stats, "avg_pivot_distance")
        @test stats["min_pivot_distance"] == 0.0  # dist[1]
        @test stats["max_pivot_distance"] == 2.0  # dist[3]
    end
    
    @testset "Parameter Validation" begin
        U_tilde = [1, 2, 3]
        S = OrderedSet([1])
        dist = [0.0, 1.0, 2.0]
        
        # Invalid k
        @test_throws ArgumentError select_pivots(U_tilde, S, 0, dist)
        @test_throws ArgumentError select_pivots(U_tilde, S, -1, dist)
        
        # Invalid t for partitioning
        @test_throws ArgumentError partition_blocks([1, 2], dist, 0)
        @test_throws ArgumentError partition_blocks([1, 2], dist, -1)
    end
    
end

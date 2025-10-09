#!/usr/bin/env julia

println("Minimal test starting...")

try
    # Test 1: Basic Julia functionality
    println("1. Testing basic Julia...")
    x = 1 + 1
    println("   Basic math works: $x")
    
    # Test 2: Test framework
    println("2. Loading Test framework...")
    using Test
    println("   Test framework loaded")
    
    # Test 3: Simple test
    println("3. Running simple test...")
    @test 1 + 1 == 2
    println("   Simple test passed")
    
    # Test 4: Load core types directly
    println("4. Loading core types...")
    include("../src/core_types.jl")
    println("   Core types loaded")
    
    # Test 5: Create Edge
    println("5. Creating Edge...")
    edge = Edge(1, 2, 1)
    println("   Edge created: $(edge.source) -> $(edge.target)")
    
    # Test 6: Create Graph
    println("6. Creating Graph...")
    edges = [Edge(1, 2, 1)]
    weights = [1.0]
    graph = DMYGraph(2, edges, weights)
    println("   Graph created with $(graph.n_vertices) vertices")
    
    println("\n✅ Minimal test completed successfully!")
    
catch e
    println("\n❌ Minimal test failed:")
    println("Error: $e")
    
    # Print detailed error info
    if isa(e, LoadError)
        println("LoadError details:")
        println("  File: $(e.file)")
        println("  Line: $(e.line)")
        println("  Error: $(e.error)")
    end
    
    # Print stack trace
    println("\nStack trace:")
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
    
    exit(1)
end
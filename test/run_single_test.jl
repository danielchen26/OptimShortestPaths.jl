#!/usr/bin/env julia

# Simple test runner that shows actual errors
test_file = length(ARGS) > 0 ? ARGS[1] : "test_core_types.jl"
test_path = isabspath(test_file) ? test_file : joinpath(@__DIR__, test_file)

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
include("../src/OptimShortestPaths.jl")

println("=== Running $(basename(test_path)) ===")

try
    include(test_path)
    println("✅ Test completed successfully")
catch e
    println("❌ Test failed with error:")
    println("Error type: $(typeof(e))")
    println("Error message: $e")
    
    if isa(e, LoadError)
        println("LoadError details:")
        println("  File: $(e.file)")
        println("  Line: $(e.line)")
        println("  Underlying error: $(e.error)")
    end
    
    println("\nFull stack trace:")
    showerror(stdout, e, catch_backtrace())
    println()
end

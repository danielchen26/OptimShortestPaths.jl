#!/usr/bin/env julia

# Simple test runner that shows actual errors
test_file = length(ARGS) > 0 ? ARGS[1] : "test_core_types.jl"

println("=== Running $test_file ===")

try
    include(test_file)
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
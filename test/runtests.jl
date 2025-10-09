using Test

# Add the src directory to the load path
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

# Load the module
include("../src/OPUS.jl")
using .OPUS

@testset "OPUS Framework Tests" begin
    include("test_core_types.jl")
    include("test_graph_utils.jl")
    include("test_bmssp.jl")
    include("test_pivot_selection.jl")
    include("test_dmy_algorithm.jl")
    include("test_utilities.jl")
    include("test_pharma_networks.jl")
    include("test_multi_objective.jl")
    include("test_correctness.jl")
end

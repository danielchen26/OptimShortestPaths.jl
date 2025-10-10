module ExampleSeedUtils

using Random

export resolve_seed, configure_global_rng, derived_seed, derived_rng, reset_global_rng

const DEFAULT_SEED = 42

function _extract_seed_from_args(args::Vector{String})
    i = 1
    while i <= length(args)
        arg = args[i]
        if startswith(arg, "--seed=")
            return split(arg, "=", limit=2)[2]
        elseif arg == "--seed"
            i == length(args) && error("`--seed` flag must be followed by an integer value")
            return args[i + 1]
        end
        i += 1
    end
    return nothing
end

function resolve_seed(; default::Union{Nothing, Int}=DEFAULT_SEED, require_seed::Bool=false)
    seed_str = _extract_seed_from_args(ARGS)
    seed_str === nothing && (seed_str = get(ENV, "OPTIM_SP_SEED", nothing))

    if seed_str === nothing
        if default === nothing
            require_seed && error("Provide `--seed` or set OPTIM_SP_SEED for reproducible runs.")
            return nothing
        else
            seed_str = string(default)
        end
    end

    try
        return parse(Int, seed_str)
    catch err
        error("Invalid RNG seed \"$seed_str\": $(err)")
    end
end

function configure_global_rng(; default::Union{Nothing, Int}=DEFAULT_SEED, require_seed::Bool=false)
    seed = resolve_seed(default=default, require_seed=require_seed)
    seed === nothing && return nothing
    Random.seed!(seed)
    return seed
end

derived_seed(base::Integer, labels...) = mod1(hash((base, labels...)), typemax(Int32))

derived_rng(base::Integer, labels...) = MersenneTwister(derived_seed(base, labels...))

function reset_global_rng(base::Integer, labels...)
    new_seed = derived_seed(base, labels...)
    Random.seed!(new_seed)
    return new_seed
end

end # module ExampleSeedUtils

using Documenter
using OptimShortestPaths

makedocs(;
    modules=[OptimShortestPaths],
    authors="Tianchi Chen <chentianchi@gmail.com>",
    repo="https://github.com/danielchen26/OptimShortestPaths.jl/blob/{commit}{path}#{line}",
    sitename="OptimShortestPaths.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://danielchen26.github.io/OptimShortestPaths.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "manual/getting_started.md",
            "Problem Transformation" => "manual/transformation.md",
            "Multi-Objective Optimization" => "manual/multiobjective.md",
            "Domain Applications" => "manual/domains.md",
        ],
        "Examples" => [
            "Overview" => "examples.md",
            "Comprehensive Demo" => "examples/comprehensive_demo.md",
            "Drug-Target Networks" => "examples/drug_target_network.md",
            "Metabolic Pathways" => "examples/metabolic_pathway.md",
            "Treatment Protocols" => "examples/treatment_protocol.md",
            "Supply Chain Optimization" => "examples/supply_chain.md",
        ],
        "API Reference" => "api.md",
        "Benchmarks" => "benchmarks.md",
    ],
    warnonly = [:missing_docs],  # Don't fail on missing docstrings during initial setup
)

deploydocs(;
    repo="github.com/danielchen26/OptimShortestPaths.jl",
    devbranch="main",
)

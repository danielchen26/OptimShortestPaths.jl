# DMY Shortest Path Examples

This directory contains practical examples of the DMY shortest-path algorithm applied to pharmaceutical and healthcare use cases. Each example has its own isolated project environment.

## Examples Structure

```
examples/
├── drug_target_network/     # Drug discovery applications
│   ├── Project.toml         # Isolated environment
│   └── drug_target_network.jl
├── metabolic_pathway/       # Systems biology applications  
│   ├── Project.toml         # Isolated environment
│   └── metabolic_pathway.jl
├── treatment_protocol/      # Healthcare optimization
│   ├── Project.toml         # Isolated environment
│   └── treatment_protocol.jl
└── comprehensive_demo/      # Complete feature showcase
    ├── Project.toml         # Isolated environment
    └── comprehensive_demo.jl
```

## Development Setup

Since this is an unregistered package in development mode:

1. **Setup main package in development mode:**
```bash
julia --project=. -e "using Pkg; Pkg.develop(path=\".\")"
```

2. **Setup example environments:**
```bash
# For each example directory
cd examples/drug_target_network
julia --project=. -e "using Pkg; Pkg.develop(path=\"../..\"); Pkg.instantiate()"
```

## Running Examples

Each example runs in its own isolated environment:

```bash
# Drug-target network analysis
julia --project=examples/drug_target_network examples/drug_target_network/drug_target_network.jl

# Metabolic pathway analysis
julia --project=examples/metabolic_pathway examples/metabolic_pathway/metabolic_pathway.jl

# Treatment protocol optimization
julia --project=examples/treatment_protocol examples/treatment_protocol/treatment_protocol.jl

# Comprehensive demonstration
julia --project=examples/comprehensive_demo examples/comprehensive_demo/comprehensive_demo.jl
```

## Features Demonstrated

1. **Drug-Target Networks** - Drug discovery pathway optimization, polypharmacology analysis
2. **Metabolic Pathways** - Biochemical reaction networks, pathway cost optimization  
3. **Treatment Protocols** - Clinical decision support, cost-effective treatment sequences
4. **Comprehensive Demo** - Complete algorithm showcase with performance analysis

Each example demonstrates the practical application of the DMY algorithm in pharmaceutical research and healthcare optimization with realistic data and scenarios.
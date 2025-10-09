module Pharma
using ..OptimShortestPaths: Edge, DMYGraph, INF, dmy_sssp!, dmy_sssp_with_parents!, reconstruct_path,
               PharmaNetwork, DrugTargetNetwork, MetabolicPathway, TreatmentProtocol
export create_drug_target_network, find_drug_target_paths, analyze_drug_connectivity,
       create_metabolic_pathway, find_metabolic_pathway, create_treatment_protocol,
       optimize_treatment_sequence

"""
Pharmaceutical network implementations for drug discovery and healthcare applications.

⚠️ IMPORTANT: These are OPTIONAL CONVENIENCE FUNCTIONS for pharmaceutical domains.

For general use, please use the GENERIC utility functions in utilities.jl:
- `find_shortest_path()` - works for ANY domain, not just drug-target
- `analyze_connectivity()` - works for ANY vertex, not just drugs
- `calculate_distance_ratio()` - works for ANY selectivity/preference calculation
- `find_reachable_vertices()` - works for ANY reachability analysis

The functions in this file are thin convenience wrappers that:
1. Handle name-to-vertex mappings for the pharmaceutical domain
2. Provide domain-specific naming (e.g., "drug", "target", "metabolite")
3. Call the underlying generic functions

ANY domain can create similar convenience wrappers or use the generic functions directly.
"""

"""
    create_drug_target_network(drugs::Vector{String}, targets::Vector{String}, 
                              interactions::Matrix{Float64}) -> DrugTargetNetwork

Create a drug-target interaction network from drug names, target names, and interaction matrix.
The interaction matrix contains binding affinities or interaction strengths.

# Arguments
- `drugs`: Vector of drug names
- `targets`: Vector of target protein names  
- `interactions`: Matrix where interactions[i,j] is the binding affinity between drug i and target j
                 Use 0.0 for no interaction, positive values for binding affinities

# Returns
- DrugTargetNetwork with underlying graph representation

# Network Structure
- Vertices represent both drugs and targets
- Edges represent drug-target interactions
- Edge weights are -log(binding_affinity) to convert to distance metric
"""
function create_drug_target_network(drugs::Vector{String}, targets::Vector{String}, 
                                   interactions::Matrix{Float64})
    
    # Validate inputs
    length(drugs) > 0 || throw(ArgumentError("Must have at least one drug"))
    length(targets) > 0 || throw(ArgumentError("Must have at least one target"))
    size(interactions) == (length(drugs), length(targets)) || 
        throw(ArgumentError("Interaction matrix size must match drugs × targets"))
    
    # Check for valid interaction values
    for interaction in interactions
        interaction >= 0 || throw(ArgumentError("Interaction values must be non-negative"))
    end
    
    # Create vertex mappings
    n_drugs = length(drugs)
    n_targets = length(targets)
    n_vertices = n_drugs + n_targets
    
    drug_indices = Dict{String, Int}()
    target_indices = Dict{String, Int}()
    
    # Drugs get vertices 1 to n_drugs
    for (i, drug) in enumerate(drugs)
        drug_indices[drug] = i
    end
    
    # Targets get vertices (n_drugs + 1) to (n_drugs + n_targets)
    for (i, target) in enumerate(targets)
        target_indices[target] = n_drugs + i
    end
    
    # Create edges and weights
    edges = Edge[]
    weights = Float64[]
    
    # Convert binding affinities to distances using a monotonic log transform.
    # Experimental affinity metrics can exceed 1.0, so we map values through
    # affinity / (1 + affinity) before applying -log. This keeps every weight
    # non-negative and preserves ordering without distorting relative strengths.
    for (i, drug) in enumerate(drugs)
        for (j, target) in enumerate(targets)
            affinity = interactions[i, j]

            if affinity > 0  # Only create edge if there's an interaction
                drug_vertex = drug_indices[drug]
                target_vertex = target_indices[target]

                # Use a small epsilon to guard against log(0) while respecting
                # the original scale of the experimental data.
                affinity_clamped = max(affinity, eps(Float64))
                transformed = affinity_clamped / (1 + affinity_clamped)
                distance = -log(transformed)

                # Create bidirectional edges (drug can bind to target, target can be bound by drug)
                push!(edges, Edge(drug_vertex, target_vertex, length(edges) + 1))
                push!(weights, distance)

                push!(edges, Edge(target_vertex, drug_vertex, length(edges) + 1))
                push!(weights, distance)
            end
        end
    end

    # Create graph
    graph = DMYGraph(n_vertices, edges, weights)
    
    return DrugTargetNetwork(drugs, targets, interactions, graph, drug_indices, target_indices)
end

"""
    find_drug_target_paths(network::DrugTargetNetwork, drug_name::String, 
                          target_name::String) -> Tuple{Float64, Vector{String}}

Find the shortest path from a drug to a target in the network.
Returns the path distance and the sequence of drugs/targets in the path.
"""
function find_drug_target_paths(network::DrugTargetNetwork, drug_name::String, 
                               target_name::String)
    
    # Validate inputs
    haskey(network.drug_indices, drug_name) || throw(ArgumentError("Drug '$drug_name' not found"))
    haskey(network.target_indices, target_name) || throw(ArgumentError("Target '$target_name' not found"))
    
    drug_vertex = network.drug_indices[drug_name]
    target_vertex = network.target_indices[target_name]
    
    # Run DMY algorithm
    dist, parent = dmy_sssp_with_parents!(network.graph, drug_vertex)
    
    # Get distance
    path_distance = dist[target_vertex]
    
    # Reconstruct path
    vertex_path = reconstruct_path(parent, drug_vertex, target_vertex)
    
    # Convert vertex path to drug/target names
    name_path = String[]
    for vertex in vertex_path
        if vertex <= length(network.drugs)
            # It's a drug
            drug_idx = vertex
            push!(name_path, network.drugs[drug_idx])
        else
            # It's a target
            target_idx = vertex - length(network.drugs)
            push!(name_path, network.targets[target_idx])
        end
    end
    
    return path_distance, name_path
end

"""
    analyze_drug_connectivity(network::DrugTargetNetwork, drug_name::String) -> Dict{String, Any}

Analyze the connectivity of a specific drug in the network.
Returns statistics about reachable targets and path lengths.
"""
function analyze_drug_connectivity(network::DrugTargetNetwork, drug_name::String)
    
    haskey(network.drug_indices, drug_name) || throw(ArgumentError("Drug '$drug_name' not found"))
    
    drug_vertex = network.drug_indices[drug_name]
    dist = dmy_sssp!(network.graph, drug_vertex)
    
    analysis = Dict{String, Any}()
    analysis["drug_name"] = drug_name
    analysis["total_targets"] = length(network.targets)
    
    # Count reachable targets
    reachable_targets = String[]
    target_distances = Float64[]
    
    for (target_name, target_vertex) in network.target_indices
        if dist[target_vertex] < INF
            push!(reachable_targets, target_name)
            push!(target_distances, dist[target_vertex])
        end
    end
    
    analysis["reachable_targets"] = length(reachable_targets)
    analysis["reachable_target_names"] = reachable_targets
    analysis["connectivity_ratio"] = length(reachable_targets) / length(network.targets)
    
    if !isempty(target_distances)
        analysis["min_target_distance"] = minimum(target_distances)
        analysis["max_target_distance"] = maximum(target_distances)
        analysis["avg_target_distance"] = sum(target_distances) / length(target_distances)
    end
    
    return analysis
end

"""
    create_metabolic_pathway(metabolites::Vector{String}, reactions::Vector{String}, 
                           reaction_costs::Vector{Float64}, 
                           reaction_network::Vector{Tuple{String, String, String}}) -> MetabolicPathway

Create a metabolic pathway network from metabolites, reactions, and their connections.

# Arguments
- `metabolites`: Vector of metabolite names
- `reactions`: Vector of reaction names
- `reaction_costs`: Vector of costs for each reaction (energy, time, etc.)
- `reaction_network`: Vector of (substrate, reaction, product) tuples defining the pathway

# Returns
- MetabolicPathway with underlying graph representation
"""
function create_metabolic_pathway(metabolites::Vector{String}, reactions::Vector{String}, 
                                 reaction_costs::Vector{Float64}, 
                                 reaction_network::Vector{Tuple{String, String, String}})
    
    # Validate inputs
    length(metabolites) > 0 || throw(ArgumentError("Must have at least one metabolite"))
    length(reactions) > 0 || throw(ArgumentError("Must have at least one reaction"))
    length(reaction_costs) == length(reactions) || 
        throw(ArgumentError("Reaction costs must match number of reactions"))
    
    # Check for valid costs
    all(cost >= 0 for cost in reaction_costs) || 
        throw(ArgumentError("Reaction costs must be non-negative"))
    
    # Create metabolite indices
    metabolite_indices = Dict{String, Int}()
    for (i, metabolite) in enumerate(metabolites)
        metabolite_indices[metabolite] = i
    end
    
    # Create reaction cost mapping
    reaction_cost_map = Dict{String, Float64}()
    for (i, reaction) in enumerate(reactions)
        reaction_cost_map[reaction] = reaction_costs[i]
    end
    
    # Create edges from reaction network
    edges = Edge[]
    weights = Float64[]
    
    for (substrate, reaction, product) in reaction_network
        # Validate that metabolites and reactions exist
        haskey(metabolite_indices, substrate) || 
            throw(ArgumentError("Substrate '$substrate' not found in metabolites"))
        haskey(metabolite_indices, product) || 
            throw(ArgumentError("Product '$product' not found in metabolites"))
        haskey(reaction_cost_map, reaction) || 
            throw(ArgumentError("Reaction '$reaction' not found in reactions"))
        
        substrate_vertex = metabolite_indices[substrate]
        product_vertex = metabolite_indices[product]
        cost = reaction_cost_map[reaction]
        
        # Create directed edge from substrate to product
        push!(edges, Edge(substrate_vertex, product_vertex, length(edges) + 1))
        push!(weights, cost)
    end
    
    # Create graph
    graph = DMYGraph(length(metabolites), edges, weights)
    
    return MetabolicPathway(metabolites, reactions, reaction_costs, graph, metabolite_indices)
end

"""
    find_metabolic_pathway(pathway::MetabolicPathway, start_metabolite::String, 
                          end_metabolite::String) -> Tuple{Float64, Vector{String}}

Find the shortest metabolic pathway between two metabolites.
Returns the total cost and sequence of metabolites in the pathway.
"""
function find_metabolic_pathway(pathway::MetabolicPathway, start_metabolite::String, 
                               end_metabolite::String)
    
    # Validate inputs
    haskey(pathway.metabolite_indices, start_metabolite) || 
        throw(ArgumentError("Start metabolite '$start_metabolite' not found"))
    haskey(pathway.metabolite_indices, end_metabolite) || 
        throw(ArgumentError("End metabolite '$end_metabolite' not found"))
    
    start_vertex = pathway.metabolite_indices[start_metabolite]
    end_vertex = pathway.metabolite_indices[end_metabolite]
    
    # Run DMY algorithm
    dist, parent = dmy_sssp_with_parents!(pathway.graph, start_vertex)
    
    # Get pathway cost
    pathway_cost = dist[end_vertex]
    
    # Reconstruct pathway
    vertex_path = reconstruct_path(parent, start_vertex, end_vertex)
    
    # Convert to metabolite names
    metabolite_path = [pathway.metabolites[v] for v in vertex_path]
    
    return pathway_cost, metabolite_path
end

"""
    create_treatment_protocol(treatments::Vector{String}, costs::Vector{Float64}, 
                            efficacy_weights::Vector{Float64}, 
                            transitions::Vector{Tuple{String, String, Float64}}) -> TreatmentProtocol

Create a treatment protocol network for healthcare optimization.

# Arguments
- `treatments`: Vector of treatment step names
- `costs`: Vector of costs for each treatment
- `efficacy_weights`: Vector of efficacy weights for each treatment
- `transitions`: Vector of (from_treatment, to_treatment, transition_cost) tuples

# Returns
- TreatmentProtocol with underlying graph representation
"""
function create_treatment_protocol(treatments::Vector{String}, costs::Vector{Float64}, 
                                  efficacy_weights::Vector{Float64}, 
                                  transitions::Vector{Tuple{String, String, Float64}})
    
    # Validate inputs
    length(treatments) > 0 || throw(ArgumentError("Must have at least one treatment"))
    length(costs) == length(treatments) || 
        throw(ArgumentError("Costs must match number of treatments"))
    length(efficacy_weights) == length(treatments) || 
        throw(ArgumentError("Efficacy weights must match number of treatments"))
    
    # Check for valid values
    all(cost >= 0 for cost in costs) || throw(ArgumentError("Costs must be non-negative"))
    all(weight >= 0 for weight in efficacy_weights) || 
        throw(ArgumentError("Efficacy weights must be non-negative"))
    
    # Create treatment indices
    treatment_indices = Dict{String, Int}()
    for (i, treatment) in enumerate(treatments)
        treatment_indices[treatment] = i
    end
    
    # Create edges from transitions
    edges = Edge[]
    weights = Float64[]
    
    for (from_treatment, to_treatment, transition_cost) in transitions
        # Validate treatments exist
        haskey(treatment_indices, from_treatment) || 
            throw(ArgumentError("Treatment '$from_treatment' not found"))
        haskey(treatment_indices, to_treatment) || 
            throw(ArgumentError("Treatment '$to_treatment' not found"))
        
        transition_cost >= 0 || throw(ArgumentError("Transition costs must be non-negative"))
        
        from_vertex = treatment_indices[from_treatment]
        to_vertex = treatment_indices[to_treatment]
        
        # Combine treatment cost and transition cost
        # Weight by inverse efficacy (lower efficacy = higher cost)
        from_efficacy = efficacy_weights[from_vertex]
        to_efficacy = efficacy_weights[to_vertex]
        
        # Calculate combined cost: transition cost + treatment cost weighted by efficacy
        combined_cost = transition_cost + costs[to_vertex] / max(to_efficacy, 1e-6)
        
        push!(edges, Edge(from_vertex, to_vertex, length(edges) + 1))
        push!(weights, combined_cost)
    end
    
    # Create graph
    graph = DMYGraph(length(treatments), edges, weights)
    
    return TreatmentProtocol(treatments, costs, efficacy_weights, graph, treatment_indices)
end

"""
    optimize_treatment_sequence(protocol::TreatmentProtocol, start_treatment::String, 
                               end_treatment::String) -> Tuple{Float64, Vector{String}}

Find the optimal treatment sequence from start to end treatment.
Returns the total cost and sequence of treatments.
"""
function optimize_treatment_sequence(protocol::TreatmentProtocol, start_treatment::String, 
                                    end_treatment::String)
    
    # Validate inputs
    haskey(protocol.treatment_indices, start_treatment) || 
        throw(ArgumentError("Start treatment '$start_treatment' not found"))
    haskey(protocol.treatment_indices, end_treatment) || 
        throw(ArgumentError("End treatment '$end_treatment' not found"))
    
    start_vertex = protocol.treatment_indices[start_treatment]
    end_vertex = protocol.treatment_indices[end_treatment]
    
    # Run DMY algorithm
    dist, parent = dmy_sssp_with_parents!(protocol.graph, start_vertex)
    
    # Get total cost
    total_cost = dist[end_vertex]
    
    # Reconstruct treatment sequence
    vertex_path = reconstruct_path(parent, start_vertex, end_vertex)
    
    # Convert to treatment names
    treatment_sequence = [protocol.treatments[v] for v in vertex_path]
    
    return total_cost, treatment_sequence
end
end # module Pharma

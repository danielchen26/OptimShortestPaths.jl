"""
Comprehensive tests for pharmaceutical network implementations.
"""

const INF = OPUS.INF

@testset "Pharmaceutical Networks Tests" begin
    
    @testset "Drug-Target Network Creation and Analysis" begin
        # Create test drug-target network
        drugs = ["Aspirin", "Ibuprofen", "Acetaminophen"]
        targets = ["COX1", "COX2", "TRPV1"]
        
        # Interaction matrix (binding affinities)
        interactions = [
            0.8  0.3  0.0;  # Aspirin: strong COX1, weak COX2, no TRPV1
            0.2  0.9  0.0;  # Ibuprofen: weak COX1, strong COX2, no TRPV1
            0.0  0.0  0.5   # Acetaminophen: no COX1/COX2, moderate TRPV1
        ]
        
        network = create_drug_target_network(drugs, targets, interactions)
        
        @test length(network.drugs) == 3
        @test length(network.targets) == 3
        @test network.graph.n_vertices == 6  # 3 drugs + 3 targets
        
        # Test drug and target indices
        @test network.drug_indices["Aspirin"] == 1
        @test network.drug_indices["Ibuprofen"] == 2
        @test network.drug_indices["Acetaminophen"] == 3
        @test network.target_indices["COX1"] == 4  # After 3 drugs
        @test network.target_indices["COX2"] == 5
        @test network.target_indices["TRPV1"] == 6
        
        # Test that interaction matrix is stored correctly
        @test network.interactions == interactions
        
        # Test graph structure (should have bidirectional edges for interactions > 0)
        expected_edges = 0
        for i in 1:3, j in 1:3
            if interactions[i, j] > 0
                expected_edges += 2  # Bidirectional
            end
        end
        @test length(network.graph.edges) == expected_edges
    end
    
    @testset "Drug-Target Path Finding" begin
        drugs = ["Aspirin", "Ibuprofen"]
        targets = ["COX1", "COX2"]
        interactions = [0.8 0.3; 0.2 0.9]  # Aspirin better for COX1, Ibuprofen better for COX2
        
        network = create_drug_target_network(drugs, targets, interactions)
        
        # Test path finding - Aspirin to COX1 (strong interaction)
        distance1, path1 = find_drug_target_paths(network, "Aspirin", "COX1")
        @test distance1 < INF
        @test !isempty(path1)
        @test path1[1] == "Aspirin"
        @test path1[end] == "COX1"
        @test length(path1) == 2  # Direct connection
        
        # Test path finding - Ibuprofen to COX2 (strong interaction)
        distance2, path2 = find_drug_target_paths(network, "Ibuprofen", "COX2")
        @test distance2 < INF
        @test path2[1] == "Ibuprofen"
        @test path2[end] == "COX2"
        
        # Aspirin should have shorter distance to COX1 than Ibuprofen
        distance3, path3 = find_drug_target_paths(network, "Ibuprofen", "COX1")
        @test distance1 < distance3  # Aspirin->COX1 should be shorter than Ibuprofen->COX1
        
        # Test invalid drug/target names
        @test_throws ArgumentError find_drug_target_paths(network, "NonexistentDrug", "COX1")
        @test_throws ArgumentError find_drug_target_paths(network, "Aspirin", "NonexistentTarget")
    end

    @testset "Affinity Normalisation" begin
        drugs = ["CompoundX"]
        targets = ["HighAffinity", "LowAffinity"]
        interactions = [2.0 0.5]

        network = create_drug_target_network(drugs, targets, interactions)
        src = network.drug_indices["CompoundX"]
        tgt_high = network.target_indices["HighAffinity"]
        tgt_low = network.target_indices["LowAffinity"]

        w_high = OPUS.get_edge_weight_between(network.graph, src, tgt_high)
        w_low = OPUS.get_edge_weight_between(network.graph, src, tgt_low)

        @test w_high !== nothing
        @test w_low !== nothing
        @test w_high < w_low
        @test all(w -> w >= 0, network.graph.weights)
    end
    
    @testset "Drug Connectivity Analysis" begin
        drugs = ["Drug1", "Drug2", "Drug3"]
        targets = ["Target1", "Target2", "Target3", "Target4"]
        interactions = [
            0.8  0.3  0.0  0.0;  # Drug1: 2 targets
            0.0  0.9  0.5  0.0;  # Drug2: 2 targets
            0.2  0.0  0.0  0.7   # Drug3: 2 targets
        ]
        
        network = create_drug_target_network(drugs, targets, interactions)
        
        # Test connectivity analysis for Drug1
        analysis1 = analyze_drug_connectivity(network, "Drug1")
        @test analysis1["drug_name"] == "Drug1"
        @test analysis1["total_targets"] == 4
        @test analysis1["reachable_targets"] == 4  # All targets reachable through network
        @test analysis1["connectivity_ratio"] == 1.0
        @test "Target1" in analysis1["reachable_target_names"]
        @test "Target2" in analysis1["reachable_target_names"]
        @test haskey(analysis1, "min_target_distance")
        @test haskey(analysis1, "max_target_distance")
        @test haskey(analysis1, "avg_target_distance")
        
        # Test connectivity analysis for Drug2
        analysis2 = analyze_drug_connectivity(network, "Drug2")
        @test analysis2["reachable_targets"] == 4  # All targets reachable through network
        @test "Target2" in analysis2["reachable_target_names"]
        @test "Target3" in analysis2["reachable_target_names"]
        
        # Test invalid drug name
        @test_throws ArgumentError analyze_drug_connectivity(network, "NonexistentDrug")
    end
    
    @testset "Metabolic Pathway Creation and Analysis" begin
        # Create test metabolic pathway
        metabolites = ["Glucose", "G6P", "F6P", "Pyruvate"]
        reactions = ["Hexokinase", "PGI", "Glycolysis"]
        reaction_costs = [2.0, 1.0, 3.0]  # ATP costs
        
        # Define pathway: Glucose -> G6P -> F6P -> Pyruvate
        reaction_network = [
            ("Glucose", "Hexokinase", "G6P"),
            ("G6P", "PGI", "F6P"),
            ("F6P", "Glycolysis", "Pyruvate")
        ]
        
        pathway = create_metabolic_pathway(metabolites, reactions, reaction_costs, reaction_network)
        
        @test length(pathway.metabolites) == 4
        @test length(pathway.reactions) == 3
        @test pathway.graph.n_vertices == 4
        @test length(pathway.graph.edges) == 3
        
        # Test metabolite indices
        @test pathway.metabolite_indices["Glucose"] == 1
        @test pathway.metabolite_indices["G6P"] == 2
        @test pathway.metabolite_indices["F6P"] == 3
        @test pathway.metabolite_indices["Pyruvate"] == 4
        
        # Test reaction costs are stored correctly
        @test pathway.enzyme_costs == reaction_costs
    end
    
    @testset "Metabolic Pathway Finding" begin
        metabolites = ["Glucose", "G6P", "F6P", "Pyruvate"]
        reactions = ["Hexokinase", "PGI", "Glycolysis"]
        reaction_costs = [2.0, 1.0, 3.0]
        reaction_network = [
            ("Glucose", "Hexokinase", "G6P"),
            ("G6P", "PGI", "F6P"),
            ("F6P", "Glycolysis", "Pyruvate")
        ]
        
        pathway = create_metabolic_pathway(metabolites, reactions, reaction_costs, reaction_network)
        
        # Test complete pathway: Glucose → Pyruvate
        cost1, path1 = find_metabolic_pathway(pathway, "Glucose", "Pyruvate")
        @test cost1 == 6.0  # 2.0 + 1.0 + 3.0
        @test path1 == ["Glucose", "G6P", "F6P", "Pyruvate"]
        
        # Test shorter pathway: G6P → F6P
        cost2, path2 = find_metabolic_pathway(pathway, "G6P", "F6P")
        @test cost2 == 1.0
        @test path2 == ["G6P", "F6P"]
        
        # Test intermediate pathway: G6P → Pyruvate
        cost3, path3 = find_metabolic_pathway(pathway, "G6P", "Pyruvate")
        @test cost3 == 4.0  # 1.0 + 3.0
        @test path3 == ["G6P", "F6P", "Pyruvate"]
        
        # Test same metabolite
        cost4, path4 = find_metabolic_pathway(pathway, "Glucose", "Glucose")
        @test cost4 == 0.0
        @test path4 == ["Glucose"]
        
        # Test invalid metabolite names
        @test_throws ArgumentError find_metabolic_pathway(pathway, "NonexistentMetabolite", "Pyruvate")
        @test_throws ArgumentError find_metabolic_pathway(pathway, "Glucose", "NonexistentMetabolite")
    end
    
    @testset "Treatment Protocol Creation and Optimization" begin
        # Create test treatment protocol
        treatments = ["Diagnosis", "Surgery", "Chemotherapy", "Recovery"]
        costs = [100.0, 5000.0, 3000.0, 500.0]
        efficacy_weights = [1.0, 0.8, 0.9, 1.0]  # Surgery slightly less certain
        
        # Define valid transitions
        transitions = [
            ("Diagnosis", "Surgery", 50.0),      # Transition cost
            ("Diagnosis", "Chemotherapy", 100.0),
            ("Surgery", "Recovery", 200.0),
            ("Surgery", "Chemotherapy", 150.0),  # Surgery then chemo
            ("Chemotherapy", "Recovery", 100.0)
        ]
        
        protocol = create_treatment_protocol(treatments, costs, efficacy_weights, transitions)
        
        @test length(protocol.treatments) == 4
        @test protocol.graph.n_vertices == 4
        @test length(protocol.graph.edges) == 5
        
        # Test treatment indices
        @test protocol.treatment_indices["Diagnosis"] == 1
        @test protocol.treatment_indices["Surgery"] == 2
        @test protocol.treatment_indices["Chemotherapy"] == 3
        @test protocol.treatment_indices["Recovery"] == 4
        
        # Test costs and efficacy weights are stored
        @test protocol.costs == costs
        @test protocol.efficacy_weights == efficacy_weights
    end
    
    @testset "Treatment Sequence Optimization" begin
        treatments = ["Diagnosis", "Surgery", "Chemotherapy", "Recovery"]
        costs = [100.0, 5000.0, 3000.0, 500.0]
        efficacy_weights = [1.0, 0.8, 0.9, 1.0]
        transitions = [
            ("Diagnosis", "Surgery", 50.0),
            ("Diagnosis", "Chemotherapy", 100.0),
            ("Surgery", "Recovery", 200.0),
            ("Surgery", "Chemotherapy", 150.0),
            ("Chemotherapy", "Recovery", 100.0)
        ]
        
        protocol = create_treatment_protocol(treatments, costs, efficacy_weights, transitions)
        
        # Test treatment optimization: Diagnosis → Recovery
        cost1, sequence1 = optimize_treatment_sequence(protocol, "Diagnosis", "Recovery")
        @test cost1 < INF
        @test !isempty(sequence1)
        @test sequence1[1] == "Diagnosis"
        @test sequence1[end] == "Recovery"
        @test length(sequence1) >= 3  # At least Diagnosis → Treatment → Recovery
        
        # Test direct path if available: Surgery → Recovery
        cost2, sequence2 = optimize_treatment_sequence(protocol, "Surgery", "Recovery")
        @test sequence2[1] == "Surgery"
        @test sequence2[end] == "Recovery"
        
        # Test same treatment
        cost3, sequence3 = optimize_treatment_sequence(protocol, "Diagnosis", "Diagnosis")
        @test cost3 == 0.0
        @test sequence3 == ["Diagnosis"]
        
        # Test invalid treatment names
        @test_throws ArgumentError optimize_treatment_sequence(protocol, "NonexistentTreatment", "Recovery")
        @test_throws ArgumentError optimize_treatment_sequence(protocol, "Diagnosis", "NonexistentTreatment")
    end
    
    @testset "Pharmaceutical Network Error Handling" begin
        # Test invalid drug-target network creation
        @test_throws ArgumentError create_drug_target_network(String[], ["T1"], zeros(0, 1))
        @test_throws ArgumentError create_drug_target_network(["D1"], String[], zeros(1, 0))
        
        # Test mismatched interaction matrix size
        @test_throws ArgumentError create_drug_target_network(["D1"], ["T1", "T2"], reshape([0.5], 1, 1))
        @test_throws ArgumentError create_drug_target_network(["D1", "D2"], ["T1"], ones(2, 2))
        
        # Test negative interaction values
        @test_throws ArgumentError create_drug_target_network(["D1"], ["T1"], reshape([-0.5], 1, 1))
        
        # Test invalid metabolic pathway creation
        @test_throws ArgumentError create_metabolic_pathway(String[], ["R1"], [1.0], [("M1", "R1", "M2")])
        @test_throws ArgumentError create_metabolic_pathway(["M1"], String[], [1.0], [("M1", "R1", "M2")])
        
        # Test mismatched reaction costs
        @test_throws ArgumentError create_metabolic_pathway(["M1", "M2"], ["R1"], [1.0, 2.0], [("M1", "R1", "M2")])
        
        # Test negative reaction costs
        @test_throws ArgumentError create_metabolic_pathway(["M1", "M2"], ["R1"], [-1.0], [("M1", "R1", "M2")])
        
        # Test invalid metabolite/reaction in network
        @test_throws ArgumentError create_metabolic_pathway(["M1", "M2"], ["R1"], [1.0], [("M3", "R1", "M2")])
        @test_throws ArgumentError create_metabolic_pathway(["M1", "M2"], ["R1"], [1.0], [("M1", "R2", "M2")])
        
        # Test invalid treatment protocol creation
        @test_throws ArgumentError create_treatment_protocol(String[], [100.0], [1.0], [("T1", "T2", 50.0)])
        @test_throws ArgumentError create_treatment_protocol(["T1"], [100.0], [1.0, 0.8], [("T1", "T2", 50.0)])
        
        # Test negative costs and efficacy weights
        @test_throws ArgumentError create_treatment_protocol(["T1"], [-100.0], [1.0], [("T1", "T2", 50.0)])
        @test_throws ArgumentError create_treatment_protocol(["T1"], [100.0], [-1.0], [("T1", "T2", 50.0)])
        
        # Test invalid treatment in transitions
        @test_throws ArgumentError create_treatment_protocol(["T1"], [100.0], [1.0], [("T3", "T1", 50.0)])
        @test_throws ArgumentError create_treatment_protocol(["T1"], [100.0], [1.0], [("T1", "T3", 50.0)])
        
        # Test negative transition costs
        @test_throws ArgumentError create_treatment_protocol(["T1", "T2"], [100.0, 200.0], [1.0, 0.8], [("T1", "T2", -50.0)])
    end
    
    @testset "Pharmaceutical Network Integration" begin
        # Test that all network types work with DMY algorithm
        
        # Drug-target network
        drugs = ["Drug1", "Drug2"]
        targets = ["Target1", "Target2"]
        interactions = [0.8 0.2; 0.3 0.9]
        dt_network = create_drug_target_network(drugs, targets, interactions)
        
        # Should be able to run DMY on the underlying graph
        dist = dmy_sssp!(dt_network.graph, 1)
        @test length(dist) == 4
        @test dist[1] == 0.0
        
        # Metabolic pathway
        metabolites = ["M1", "M2", "M3"]
        reactions = ["R1", "R2"]
        costs = [1.0, 2.0]
        network = [("M1", "R1", "M2"), ("M2", "R2", "M3")]
        mp_pathway = create_metabolic_pathway(metabolites, reactions, costs, network)
        
        dist_mp = dmy_sssp!(mp_pathway.graph, 1)
        @test length(dist_mp) == 3
        @test dist_mp[1] == 0.0
        
        # Treatment protocol
        treatments = ["T1", "T2", "T3"]
        costs_t = [100.0, 200.0, 150.0]
        efficacy = [1.0, 0.9, 0.8]
        transitions = [("T1", "T2", 50.0), ("T2", "T3", 30.0)]
        tp_protocol = create_treatment_protocol(treatments, costs_t, efficacy, transitions)
        
        dist_tp = dmy_sssp!(tp_protocol.graph, 1)
        @test length(dist_tp) == 3
        @test dist_tp[1] == 0.0
    end
    
    @testset "Complex Pharmaceutical Networks" begin
        # Test larger, more complex networks
        
        # Large drug-target network
        n_drugs = 10
        n_targets = 8
        drugs = ["Drug_$i" for i in 1:n_drugs]
        targets = ["Target_$i" for i in 1:n_targets]
        
        # Create sparse interaction matrix
        interactions = zeros(n_drugs, n_targets)
        for i in 1:n_drugs
            # Each drug interacts with 2-3 targets
            n_interactions = rand(2:3)
            target_indices = rand(1:n_targets, n_interactions)
            for j in target_indices
                interactions[i, j] = rand() * 0.8 + 0.1  # Random affinity 0.1-0.9
            end
        end
        
        large_network = create_drug_target_network(drugs, targets, interactions)
        @test large_network.graph.n_vertices == n_drugs + n_targets
        
        # Test connectivity analysis on large network
        analysis = analyze_drug_connectivity(large_network, "Drug_1")
        @test analysis["total_targets"] == n_targets
        @test analysis["reachable_targets"] >= 2  # Should have at least 2 interactions
        
        # Complex metabolic pathway (branched)
        metabolites = ["A", "B", "C", "D", "E", "F"]
        reactions = ["R1", "R2", "R3", "R4", "R5"]
        costs = [1.0, 2.0, 1.5, 3.0, 0.5]
        reaction_network = [
            ("A", "R1", "B"),
            ("A", "R2", "C"),  # Branch
            ("B", "R3", "D"),
            ("C", "R4", "E"),
            ("D", "R5", "F"),
            ("E", "R5", "F")   # Convergence
        ]
        
        complex_pathway = create_metabolic_pathway(metabolites, reactions, costs, reaction_network)
        
        # Test multiple paths to same destination
        cost_via_B, path_via_B = find_metabolic_pathway(complex_pathway, "A", "F")
        @test cost_via_B < INF
        @test path_via_B[1] == "A"
        @test path_via_B[end] == "F"
        
        # Should find optimal path
        @test cost_via_B <= 4.5  # A->B->D->F or A->C->E->F, whichever is cheaper
    end
    
end

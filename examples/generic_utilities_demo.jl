#!/usr/bin/env julia

"""
Generic Utilities Demonstration
================================
This example shows how OptimSPath's generic utility functions can be applied
to ANY domain. We'll demonstrate with a simple logistics network, but
these same functions work for ANY graph-based problem!
"""

using OptimSPath

println("🌐 OptimSPath Generic Utilities Demonstration")
println("=" ^ 60)

# Example 1: Supply Chain Network
println("\n📦 Example 1: Supply Chain Network")
println("-" ^ 40)

# Create a simple supply chain graph
# Vertices: 1=Factory, 2-4=Warehouses, 5-8=Stores
println("Network: Factory → Warehouses → Stores")

edges = [
    # Factory to warehouses (shipping cost)
    Edge(1, 2, 1), Edge(1, 3, 2), Edge(1, 4, 3),
    # Warehouse 1 to stores
    Edge(2, 5, 4), Edge(2, 6, 5),
    # Warehouse 2 to stores  
    Edge(3, 6, 6), Edge(3, 7, 7),
    # Warehouse 3 to stores
    Edge(4, 7, 8), Edge(4, 8, 9)
]
weights = [15.0, 20.0, 25.0,  # Factory to warehouses
           10.0, 12.0,         # Warehouse 1 to stores
           8.0, 11.0,          # Warehouse 2 to stores
           9.0, 14.0]          # Warehouse 3 to stores

supply_graph = DMYGraph(8, edges, weights)

# 1. ANALYZE CONNECTIVITY from factory
println("\n1️⃣ Factory Connectivity Analysis:")
factory_metrics = analyze_connectivity(supply_graph, 1)
println("   Reachable locations: $(factory_metrics["reachable_count"])/8")
println("   Average shipping cost: \$$(round(factory_metrics["avg_distance"], digits=2))")
println("   Max shipping cost: \$$(round(factory_metrics["max_distance"], digits=2))")

# 2. COMPARE WAREHOUSES for reaching Store 6
println("\n2️⃣ Best Warehouse for Store 6:")
warehouses = [2, 3, 4]
store6_costs = compare_sources(supply_graph, warehouses, 6)
for (warehouse, cost) in store6_costs
    wh_name = "Warehouse $(warehouse-1)"
    if cost < OptimSPath.INF
        println("   $wh_name → Store 6: \$$(round(cost, digits=2))")
    else
        println("   $wh_name → Store 6: No route")
    end
end
best_warehouse = argmin(store6_costs) 
println("   ✓ Best choice: Warehouse $(best_warehouse-1)")

# 3. FIND REACHABLE STORES within budget
println("\n3️⃣ Stores Reachable within \$30 Budget:")
budget = 30.0
reachable = find_reachable_vertices(supply_graph, 1, budget)
stores_in_budget = filter(v -> v >= 5, reachable)  # Stores are vertices 5-8
println("   Stores within budget: $(length(stores_in_budget))/4")
for store in stores_in_budget
    dist = dmy_sssp!(supply_graph, 1)[store]
    println("   Store $(store-4): \$$(round(dist, digits=2))")
end

# 4. CALCULATE PREFERENCE between two warehouses
println("\n4️⃣ Warehouse Preference for Store 7:")
# Which warehouse is better for Store 7: Warehouse 2 or 3?
preference = calculate_path_preference(supply_graph, 7, 3, 4)  # Store 7 prefers WH2 over WH3
if preference > 1.0
    println("   Store 7 prefers Warehouse 2 ($(round(preference, digits=2))x preference)")
else
    println("   Store 7 prefers Warehouse 3 ($(round(1/preference, digits=2))x preference)")
end

# Example 2: Social Network
println("\n\n👥 Example 2: Social Network (Influence Propagation)")
println("-" ^ 40)

# Create a simple social network
# Vertices represent people, edges represent influence strength
social_edges = [
    Edge(1, 2, 1), Edge(1, 3, 2),  # Person 1 influences 2 and 3
    Edge(2, 4, 3), Edge(2, 5, 4),  # Person 2 influences 4 and 5
    Edge(3, 5, 5), Edge(3, 6, 6),  # Person 3 influences 5 and 6
    Edge(4, 7, 7), Edge(5, 7, 8)   # 4 and 5 influence 7
]
# Lower weight = stronger influence
influence_weights = [0.2, 0.3, 0.4, 0.5, 0.6, 0.3, 0.7, 0.8]
social_graph = DMYGraph(7, social_edges, influence_weights)

# Analyze influence reach from Person 1 (the influencer)
influence_metrics = analyze_connectivity(social_graph, 1)
println("Person 1's Influence Network:")
println("   Can influence: $(influence_metrics["reachable_count"])/7 people")
println("   Average influence distance: $(round(influence_metrics["avg_distance"], digits=2))")

# Find people within "strong influence" range (distance < 1.0)
strong_influence = find_reachable_vertices(social_graph, 1, 1.0)
println("   Strong influence (distance < 1.0): $(length(strong_influence)) people")

# Example 3: ANY Domain!
println("\n\n🎯 Key Takeaway:")
println("-" ^ 40)
println("""
These GENERIC functions work with ANY graph:
• Transportation networks (cities & routes)
• Computer networks (nodes & connections)  
• Biological networks (proteins & interactions)
• Economic networks (markets & trade routes)
• Project dependencies (tasks & prerequisites)

Simply:
1. Map your entities to vertices
2. Map relationships to weighted edges
3. Use the generic functions for analysis!

No domain-specific code needed - OptimSPath handles it all!
""")

println("\n✅ Generic utilities demonstration complete!")
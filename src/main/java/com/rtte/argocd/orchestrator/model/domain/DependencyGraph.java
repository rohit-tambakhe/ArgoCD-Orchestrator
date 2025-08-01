package com.rtte.argocd.orchestrator.model.domain;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import jakarta.persistence.*;
import java.util.*;

/**
 * Domain model representing a dependency graph for microservices.
 * Handles complex dependency relationships and circular dependency detection.
 */
@Entity
@Table(name = "dependency_graphs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DependencyGraph {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "customer_id", nullable = false)
    private String customerId;
    
    @Column(name = "graph_name")
    private String graphName;
    
    @OneToMany(mappedBy = "dependencyGraph", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    private List<DependencyNode> nodes = new ArrayList<>();
    
    @OneToMany(mappedBy = "dependencyGraph", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    private List<DependencyEdge> edges = new ArrayList<>();
    
    @Column(name = "is_valid")
    private Boolean isValid = true;
    
    @Column(name = "has_circular_dependencies")
    private Boolean hasCircularDependencies = false;
    
    @Column(name = "topological_order")
    @ElementCollection
    @CollectionTable(name = "dependency_graph_topological_order",
                    joinColumns = @JoinColumn(name = "dependency_graph_id"))
    @OrderColumn(name = "order_index")
    private List<String> topologicalOrder = new ArrayList<>();
    
    @Column(name = "created_at")
    private java.time.LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private java.time.LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = java.time.LocalDateTime.now();
        updatedAt = java.time.LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = java.time.LocalDateTime.now();
    }
    
    /**
     * Add a node to the dependency graph
     */
    public void addNode(DependencyNode node) {
        node.setDependencyGraph(this);
        nodes.add(node);
    }
    
    /**
     * Add an edge to the dependency graph
     */
    public void addEdge(DependencyEdge edge) {
        edge.setDependencyGraph(this);
        edges.add(edge);
    }
    
    /**
     * Get all dependencies for a specific service
     */
    public List<String> getDependenciesForService(String serviceName) {
        return edges.stream()
                .filter(edge -> edge.getFromService().equals(serviceName))
                .map(DependencyEdge::getToService)
                .toList();
    }
    
    /**
     * Get all services that depend on a specific service
     */
    public List<String> getDependentsForService(String serviceName) {
        return edges.stream()
                .filter(edge -> edge.getToService().equals(serviceName))
                .map(DependencyEdge::getFromService)
                .toList();
    }
    
    /**
     * Check if there are circular dependencies
     */
    public boolean hasCircularDependencies() {
        Set<String> visited = new HashSet<>();
        Set<String> recursionStack = new HashSet<>();
        
        for (DependencyNode node : nodes) {
            if (!visited.contains(node.getServiceName())) {
                if (hasCircularDependenciesUtil(node.getServiceName(), visited, recursionStack)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    private boolean hasCircularDependenciesUtil(String serviceName, Set<String> visited, Set<String> recursionStack) {
        visited.add(serviceName);
        recursionStack.add(serviceName);
        
        List<String> dependencies = getDependenciesForService(serviceName);
        for (String dependency : dependencies) {
            if (!visited.contains(dependency)) {
                if (hasCircularDependenciesUtil(dependency, visited, recursionStack)) {
                    return true;
                }
            } else if (recursionStack.contains(dependency)) {
                return true;
            }
        }
        
        recursionStack.remove(serviceName);
        return false;
    }
    
    /**
     * Generate topological order for the dependency graph
     */
    public List<String> generateTopologicalOrder() {
        if (hasCircularDependencies()) {
            throw new IllegalStateException("Cannot generate topological order for graph with circular dependencies");
        }
        
        Map<String, Integer> inDegree = new HashMap<>();
        Map<String, List<String>> adjacencyList = new HashMap<>();
        
        // Initialize in-degree and adjacency list
        for (DependencyNode node : nodes) {
            inDegree.put(node.getServiceName(), 0);
            adjacencyList.put(node.getServiceName(), new ArrayList<>());
        }
        
        // Build adjacency list and calculate in-degrees
        for (DependencyEdge edge : edges) {
            String from = edge.getFromService();
            String to = edge.getToService();
            adjacencyList.get(from).add(to);
            inDegree.put(to, inDegree.get(to) + 1);
        }
        
        // Kahn's algorithm for topological sorting
        Queue<String> queue = new LinkedList<>();
        List<String> result = new ArrayList<>();
        
        // Add all nodes with in-degree 0 to queue
        for (Map.Entry<String, Integer> entry : inDegree.entrySet()) {
            if (entry.getValue() == 0) {
                queue.offer(entry.getKey());
            }
        }
        
        while (!queue.isEmpty()) {
            String current = queue.poll();
            result.add(current);
            
            for (String neighbor : adjacencyList.get(current)) {
                inDegree.put(neighbor, inDegree.get(neighbor) - 1);
                if (inDegree.get(neighbor) == 0) {
                    queue.offer(neighbor);
                }
            }
        }
        
        this.topologicalOrder = result;
        return result;
    }
    
    /**
     * Get sync wave order based on dependencies
     */
    public Map<Integer, List<String>> getSyncWaveOrder() {
        List<String> topologicalOrder = generateTopologicalOrder();
        Map<Integer, List<String>> syncWaves = new TreeMap<>();
        
        for (String serviceName : topologicalOrder) {
            DependencyNode node = nodes.stream()
                    .filter(n -> n.getServiceName().equals(serviceName))
                    .findFirst()
                    .orElse(null);
            
            if (node != null) {
                int wave = node.getSyncWave();
                syncWaves.computeIfAbsent(wave, k -> new ArrayList<>()).add(serviceName);
            }
        }
        
        return syncWaves;
    }
    
    /**
     * Dependency node representing a microservice in the graph
     */
    @Entity
    @Table(name = "dependency_nodes")
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DependencyNode {
        
        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;
        
        @Column(name = "service_name", nullable = false)
        private String serviceName;
        
        @Column(name = "sync_wave")
        private Integer syncWave = 0;
        
        @Column(name = "priority")
        private Integer priority = 0;
        
        @ManyToOne
        @JoinColumn(name = "dependency_graph_id")
        private DependencyGraph dependencyGraph;
        
        @Column(name = "created_at")
        private java.time.LocalDateTime createdAt;
        
        @PrePersist
        protected void onCreate() {
            createdAt = java.time.LocalDateTime.now();
        }
    }
    
    /**
     * Dependency edge representing a dependency relationship
     */
    @Entity
    @Table(name = "dependency_edges")
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DependencyEdge {
        
        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;
        
        @Column(name = "from_service", nullable = false)
        private String fromService;
        
        @Column(name = "to_service", nullable = false)
        private String toService;
        
        @Column(name = "dependency_type")
        @Enumerated(EnumType.STRING)
        private DependencyType dependencyType = DependencyType.HARD;
        
        @Column(name = "weight")
        private Integer weight = 1;
        
        @ManyToOne
        @JoinColumn(name = "dependency_graph_id")
        private DependencyGraph dependencyGraph;
        
        @Column(name = "created_at")
        private java.time.LocalDateTime createdAt;
        
        @PrePersist
        protected void onCreate() {
            createdAt = java.time.LocalDateTime.now();
        }
        
        /**
         * Types of dependencies
         */
        public enum DependencyType {
            HARD,      // Service cannot start without this dependency
            SOFT,      // Service can start but may have degraded functionality
            OPTIONAL   // Service can start normally without this dependency
        }
    }
} 
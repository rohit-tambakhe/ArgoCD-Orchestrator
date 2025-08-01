package com.rtte.argocd.orchestrator.service;

import com.rtte.argocd.orchestrator.model.domain.DependencyGraph;
import com.rtte.argocd.orchestrator.model.domain.Microservice;
import com.rtte.argocd.orchestrator.model.domain.SyncWave;
import com.rtte.argocd.orchestrator.repository.DependencyRepository;
import com.rtte.argocd.orchestrator.repository.MicroserviceRepository;
import com.rtte.argocd.orchestrator.repository.SyncWaveRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for resolving dependencies between 55+ microservices.
 * Handles complex dependency graphs, circular dependency detection, and sync wave generation.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DependencyResolutionService {
    
    private final DependencyRepository dependencyRepository;
    private final MicroserviceRepository microserviceRepository;
    private final SyncWaveRepository syncWaveRepository;
    
    /**
     * Resolve dependencies for a customer's microservices
     */
    @Transactional
    public DependencyResolutionResult resolveDependencies(String customerId, List<Microservice> microservices) {
        log.info("Resolving dependencies for customer: {} with {} microservices", customerId, microservices.size());
        
        try {
            // Create dependency graph
            DependencyGraph graph = createDependencyGraph(customerId, microservices);
            
            // Check for circular dependencies
            if (graph.hasCircularDependencies()) {
                log.error("Circular dependencies detected for customer: {}", customerId);
                return DependencyResolutionResult.builder()
                        .success(false)
                        .error("Circular dependencies detected")
                        .circularDependencies(detectCircularDependencies(graph))
                        .build();
            }
            
            // Generate topological order
            List<String> topologicalOrder = graph.generateTopologicalOrder();
            
            // Generate sync waves
            Map<Integer, List<String>> syncWaves = generateSyncWaves(graph, microservices);
            
            // Save dependency graph
            dependencyRepository.save(graph);
            
            // Create sync wave entities
            List<SyncWave> syncWaveEntities = createSyncWaveEntities(customerId, syncWaves);
            syncWaveRepository.saveAll(syncWaveEntities);
            
            log.info("Successfully resolved dependencies for customer: {}. Generated {} sync waves", 
                    customerId, syncWaves.size());
            
            return DependencyResolutionResult.builder()
                    .success(true)
                    .dependencyGraph(graph)
                    .topologicalOrder(topologicalOrder)
                    .syncWaves(syncWaves)
                    .syncWaveEntities(syncWaveEntities)
                    .build();
                    
        } catch (Exception e) {
            log.error("Error resolving dependencies for customer: {}", customerId, e);
            return DependencyResolutionResult.builder()
                    .success(false)
                    .error(e.getMessage())
                    .build();
        }
    }
    
    /**
     * Create dependency graph from microservices
     */
    private DependencyGraph createDependencyGraph(String customerId, List<Microservice> microservices) {
        DependencyGraph graph = DependencyGraph.builder()
                .customerId(customerId)
                .graphName("dependency-graph-" + customerId)
                .build();
        
        // Create nodes for each microservice
        for (Microservice microservice : microservices) {
            DependencyGraph.DependencyNode node = DependencyGraph.DependencyNode.builder()
                    .serviceName(microservice.getName())
                    .syncWave(microservice.getSyncWave())
                    .priority(0)
                    .build();
            graph.addNode(node);
        }
        
        // Create edges for dependencies
        for (Microservice microservice : microservices) {
            if (microservice.getDependencies() != null) {
                for (String dependency : microservice.getDependencies()) {
                    DependencyGraph.DependencyEdge edge = DependencyGraph.DependencyEdge.builder()
                            .fromService(microservice.getName())
                            .toService(dependency)
                            .dependencyType(DependencyGraph.DependencyEdge.DependencyType.HARD)
                            .weight(1)
                            .build();
                    graph.addEdge(edge);
                }
            }
        }
        
        return graph;
    }
    
    /**
     * Detect circular dependencies and return the cycle
     */
    private List<String> detectCircularDependencies(DependencyGraph graph) {
        Set<String> visited = new HashSet<>();
        Set<String> recursionStack = new HashSet<>();
        Map<String, String> parent = new HashMap<>();
        
        for (DependencyGraph.DependencyNode node : graph.getNodes()) {
            if (!visited.contains(node.getServiceName())) {
                if (hasCircularDependenciesUtil(node.getServiceName(), visited, recursionStack, parent, graph)) {
                    return buildCircularDependencyPath(node.getServiceName(), parent);
                }
            }
        }
        
        return new ArrayList<>();
    }
    
    private boolean hasCircularDependenciesUtil(String serviceName, Set<String> visited, 
                                              Set<String> recursionStack, Map<String, String> parent, 
                                              DependencyGraph graph) {
        visited.add(serviceName);
        recursionStack.add(serviceName);
        
        List<String> dependencies = graph.getDependenciesForService(serviceName);
        for (String dependency : dependencies) {
            if (!visited.contains(dependency)) {
                parent.put(dependency, serviceName);
                if (hasCircularDependenciesUtil(dependency, visited, recursionStack, parent, graph)) {
                    return true;
                }
            } else if (recursionStack.contains(dependency)) {
                parent.put(dependency, serviceName);
                return true;
            }
        }
        
        recursionStack.remove(serviceName);
        return false;
    }
    
    private List<String> buildCircularDependencyPath(String startService, Map<String, String> parent) {
        List<String> cycle = new ArrayList<>();
        String current = startService;
        
        do {
            cycle.add(current);
            current = parent.get(current);
        } while (current != null && !cycle.contains(current));
        
        // Find the start of the cycle
        int cycleStart = cycle.indexOf(current);
        if (cycleStart != -1) {
            cycle = cycle.subList(cycleStart, cycle.size());
        }
        
        return cycle;
    }
    
    /**
     * Generate sync waves based on dependencies and sync wave numbers
     */
    private Map<Integer, List<String>> generateSyncWaves(DependencyGraph graph, List<Microservice> microservices) {
        Map<Integer, List<String>> syncWaves = new TreeMap<>();
        
        // Group services by sync wave number
        for (Microservice microservice : microservices) {
            int waveNumber = microservice.getSyncWave();
            syncWaves.computeIfAbsent(waveNumber, k -> new ArrayList<>()).add(microservice.getName());
        }
        
        // Sort services within each wave based on dependencies
        for (Map.Entry<Integer, List<String>> entry : syncWaves.entrySet()) {
            List<String> services = entry.getValue();
            services.sort((s1, s2) -> {
                // Services with fewer dependencies come first
                int deps1 = graph.getDependenciesForService(s1).size();
                int deps2 = graph.getDependenciesForService(s2).size();
                return Integer.compare(deps1, deps2);
            });
        }
        
        return syncWaves;
    }
    
    /**
     * Create sync wave entities from the sync wave map
     */
    private List<SyncWave> createSyncWaveEntities(String customerId, Map<Integer, List<String>> syncWaves) {
        List<SyncWave> entities = new ArrayList<>();
        
        for (Map.Entry<Integer, List<String>> entry : syncWaves.entrySet()) {
            int waveNumber = entry.getKey();
            List<String> services = entry.getValue();
            
            SyncWave syncWave = SyncWave.builder()
                    .customerId(customerId)
                    .waveNumber(waveNumber)
                    .waveName(SyncWave.SyncWaveType.fromWaveNumber(waveNumber).getDisplayName())
                    .services(services)
                    .status(SyncWave.SyncWaveStatus.PENDING)
                    .totalServices(services.size())
                    .timeoutSeconds(300) // 5 minutes
                    .healthCheckTimeoutSeconds(60) // 1 minute
                    .maxRetries(3)
                    .retryDelaySeconds(30)
                    .build();
            
            entities.add(syncWave);
        }
        
        return entities;
    }
    
    /**
     * Validate dependencies for a customer
     */
    @Transactional(readOnly = true)
    public DependencyValidationResult validateDependencies(String customerId) {
        log.info("Validating dependencies for customer: {}", customerId);
        
        try {
            List<Microservice> microservices = microserviceRepository.findByCustomerId(customerId);
            
            if (microservices.isEmpty()) {
                return DependencyValidationResult.builder()
                        .valid(false)
                        .error("No microservices found for customer: " + customerId)
                        .build();
            }
            
            DependencyGraph graph = createDependencyGraph(customerId, microservices);
            
            boolean hasCircularDeps = graph.hasCircularDependencies();
            List<String> circularDeps = hasCircularDeps ? detectCircularDependencies(graph) : new ArrayList<>();
            
            return DependencyValidationResult.builder()
                    .valid(!hasCircularDeps)
                    .circularDependencies(circularDeps)
                    .totalServices(microservices.size())
                    .totalDependencies(countTotalDependencies(microservices))
                    .build();
                    
        } catch (Exception e) {
            log.error("Error validating dependencies for customer: {}", customerId, e);
            return DependencyValidationResult.builder()
                    .valid(false)
                    .error(e.getMessage())
                    .build();
        }
    }
    
    /**
     * Count total dependencies across all microservices
     */
    private int countTotalDependencies(List<Microservice> microservices) {
        return microservices.stream()
                .mapToInt(ms -> ms.getDependencies() != null ? ms.getDependencies().size() : 0)
                .sum();
    }
    
    /**
     * Get dependency graph for a customer
     */
    @Transactional(readOnly = true)
    public Optional<DependencyGraph> getDependencyGraph(String customerId) {
        return dependencyRepository.findByCustomerId(customerId);
    }
    
    /**
     * Get sync waves for a customer
     */
    @Transactional(readOnly = true)
    public List<SyncWave> getSyncWaves(String customerId) {
        return syncWaveRepository.findByCustomerIdOrderByWaveNumber(customerId);
    }
    
    /**
     * Check if a service's dependencies are satisfied
     */
    @Transactional(readOnly = true)
    public boolean areDependenciesSatisfied(String customerId, String serviceName) {
        Optional<DependencyGraph> graphOpt = getDependencyGraph(customerId);
        if (graphOpt.isEmpty()) {
            return false;
        }
        
        DependencyGraph graph = graphOpt.get();
        List<String> dependencies = graph.getDependenciesForService(serviceName);
        
        if (dependencies.isEmpty()) {
            return true;
        }
        
        // Check if all dependencies are healthy
        for (String dependency : dependencies) {
            Optional<Microservice> depService = microserviceRepository.findByCustomerIdAndName(customerId, dependency);
            if (depService.isEmpty() || !Microservice.MicroserviceStatus.HEALTHY.equals(depService.get().getStatus())) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Result class for dependency resolution
     */
    public static class DependencyResolutionResult {
        private boolean success;
        private String error;
        private DependencyGraph dependencyGraph;
        private List<String> topologicalOrder;
        private Map<Integer, List<String>> syncWaves;
        private List<SyncWave> syncWaveEntities;
        private List<String> circularDependencies;
        
        // Builder pattern implementation
        public static Builder builder() {
            return new Builder();
        }
        
        public static class Builder {
            private DependencyResolutionResult result = new DependencyResolutionResult();
            
            public Builder success(boolean success) {
                result.success = success;
                return this;
            }
            
            public Builder error(String error) {
                result.error = error;
                return this;
            }
            
            public Builder dependencyGraph(DependencyGraph graph) {
                result.dependencyGraph = graph;
                return this;
            }
            
            public Builder topologicalOrder(List<String> order) {
                result.topologicalOrder = order;
                return this;
            }
            
            public Builder syncWaves(Map<Integer, List<String>> waves) {
                result.syncWaves = waves;
                return this;
            }
            
            public Builder syncWaveEntities(List<SyncWave> entities) {
                result.syncWaveEntities = entities;
                return this;
            }
            
            public Builder circularDependencies(List<String> deps) {
                result.circularDependencies = deps;
                return this;
            }
            
            public DependencyResolutionResult build() {
                return result;
            }
        }
        
        // Getters
        public boolean isSuccess() { return success; }
        public String getError() { return error; }
        public DependencyGraph getDependencyGraph() { return dependencyGraph; }
        public List<String> getTopologicalOrder() { return topologicalOrder; }
        public Map<Integer, List<String>> getSyncWaves() { return syncWaves; }
        public List<SyncWave> getSyncWaveEntities() { return syncWaveEntities; }
        public List<String> getCircularDependencies() { return circularDependencies; }
    }
    
    /**
     * Result class for dependency validation
     */
    public static class DependencyValidationResult {
        private boolean valid;
        private String error;
        private List<String> circularDependencies;
        private int totalServices;
        private int totalDependencies;
        
        // Builder pattern implementation
        public static Builder builder() {
            return new Builder();
        }
        
        public static class Builder {
            private DependencyValidationResult result = new DependencyValidationResult();
            
            public Builder valid(boolean valid) {
                result.valid = valid;
                return this;
            }
            
            public Builder error(String error) {
                result.error = error;
                return this;
            }
            
            public Builder circularDependencies(List<String> deps) {
                result.circularDependencies = deps;
                return this;
            }
            
            public Builder totalServices(int count) {
                result.totalServices = count;
                return this;
            }
            
            public Builder totalDependencies(int count) {
                result.totalDependencies = count;
                return this;
            }
            
            public DependencyValidationResult build() {
                return result;
            }
        }
        
        // Getters
        public boolean isValid() { return valid; }
        public String getError() { return error; }
        public List<String> getCircularDependencies() { return circularDependencies; }
        public int getTotalServices() { return totalServices; }
        public int getTotalDependencies() { return totalDependencies; }
    }
} 
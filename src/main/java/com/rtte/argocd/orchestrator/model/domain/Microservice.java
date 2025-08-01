package com.rtte.argocd.orchestrator.model.domain;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import jakarta.persistence.*;
import java.util.List;
import java.util.Map;

/**
 * Domain model representing a microservice in the orchestrator.
 * Supports 55+ microservices with dependency management and sync waves.
 */
@Entity
@Table(name = "microservices")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Microservice {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    @Column(name = "customer_id", nullable = false)
    private String customerId;
    
    @Column(name = "version", nullable = false)
    private String version;
    
    @Column(name = "enabled")
    private Boolean enabled = true;
    
    @Column(name = "sync_wave")
    private Integer syncWave = 0;
    
    @ElementCollection
    @CollectionTable(name = "microservice_dependencies", 
                    joinColumns = @JoinColumn(name = "microservice_id"))
    @Column(name = "dependency_name")
    private List<String> dependencies;
    
    @Embedded
    private HealthCheck healthCheck;
    
    @Column(name = "deployment_strategy")
    @Enumerated(EnumType.STRING)
    private DeploymentStrategy deploymentStrategy = DeploymentStrategy.ROLLING_UPDATE;
    
    @Column(name = "replicas")
    private Integer replicas = 1;
    
    @Embedded
    private ResourceRequirements resources;
    
    @ElementCollection
    @CollectionTable(name = "microservice_config_maps",
                    joinColumns = @JoinColumn(name = "microservice_id"))
    @MapKeyColumn(name = "config_key")
    @Column(name = "config_value")
    private Map<String, String> configMaps;
    
    @ElementCollection
    @CollectionTable(name = "microservice_secrets",
                    joinColumns = @JoinColumn(name = "microservice_id"))
    @MapKeyColumn(name = "secret_key")
    @Column(name = "secret_value")
    private Map<String, String> secrets;
    
    @ElementCollection
    @CollectionTable(name = "microservice_volume_claims",
                    joinColumns = @JoinColumn(name = "microservice_id"))
    @Column(name = "volume_claim")
    private List<String> volumeClaims;
    
    @Embedded
    private RollbackConfig rollbackConfig;
    
    @Column(name = "image_repository")
    private String imageRepository;
    
    @Column(name = "image_tag")
    private String imageTag;
    
    @Column(name = "namespace")
    private String namespace;
    
    @Column(name = "status")
    @Enumerated(EnumType.STRING)
    private MicroserviceStatus status = MicroserviceStatus.PENDING;
    
    @Column(name = "last_health_check")
    private java.time.LocalDateTime lastHealthCheck;
    
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
     * Health check configuration for microservices
     */
    @Embeddable
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class HealthCheck {
        @Column(name = "endpoint")
        private String endpoint = "/health";
        
        @Column(name = "method")
        private String method = "GET";
        
        @Column(name = "expected_status")
        private Integer expectedStatus = 200;
        
        @Column(name = "timeout_seconds")
        private Integer timeoutSeconds = 10;
        
        @Column(name = "interval_seconds")
        private Integer intervalSeconds = 30;
        
        @Column(name = "failure_threshold")
        private Integer failureThreshold = 3;
        
        @Column(name = "success_threshold")
        private Integer successThreshold = 1;
    }
    
    /**
     * Resource requirements for microservices
     */
    @Embeddable
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResourceRequirements {
        @Embedded
        private Resource requests;
        
        @Embedded
        private Resource limits;
        
        @Embeddable
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Resource {
            @Column(name = "cpu")
            private String cpu;
            
            @Column(name = "memory")
            private String memory;
        }
    }
    
    /**
     * Rollback configuration for microservices
     */
    @Embeddable
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RollbackConfig {
        @Column(name = "enabled")
        private Boolean enabled = true;
        
        @Column(name = "max_versions")
        private Integer maxVersions = 5;
        
        @Column(name = "auto_rollback")
        private Boolean autoRollback = true;
        
        @Column(name = "failure_threshold")
        private Integer failureThreshold = 3;
        
        @Column(name = "rollback_timeout_seconds")
        private Integer rollbackTimeoutSeconds = 300;
    }
    
    /**
     * Deployment strategies
     */
    public enum DeploymentStrategy {
        ROLLING_UPDATE,
        BLUE_GREEN,
        CANARY,
        RECREATE
    }
    
    /**
     * Microservice status
     */
    public enum MicroserviceStatus {
        PENDING,
        DEPLOYING,
        HEALTHY,
        UNHEALTHY,
        FAILED,
        ROLLING_BACK,
        ROLLED_BACK
    }
} 
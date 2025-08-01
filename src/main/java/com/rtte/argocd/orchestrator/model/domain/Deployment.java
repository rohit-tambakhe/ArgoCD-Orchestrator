package com.rtte.argocd.orchestrator.model.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.Map;

/**
 * Deployment entity representing deployment records
 */
@Entity
@Table(name = "deployments")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Deployment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "deployment_id", unique = true, nullable = false)
    private String deploymentId;

    @Column(name = "customer_id", nullable = false)
    private String customerId;

    @Column(name = "application_name", nullable = false)
    private String applicationName;

    @Column(name = "environment", nullable = false)
    private String environment;

    @Column(name = "target_revision", nullable = false)
    private String targetRevision;

    @Column(name = "strategy", nullable = false)
    private String strategy;

    @Column(name = "status", nullable = false)
    @Enumerated(EnumType.STRING)
    private DeploymentStatus status;

    @Column(name = "argo_application_name")
    private String argoApplicationName;

    @Column(name = "argo_project")
    private String argoProject;

    @Column(name = "source_repo_url")
    private String sourceRepoUrl;

    @Column(name = "source_path")
    private String sourcePath;

    @Column(name = "destination_namespace")
    private String destinationNamespace;

    @Column(name = "destination_server")
    private String destinationServer;

    @Column(columnDefinition = "TEXT")
    private String parameters;

    @Column(columnDefinition = "TEXT")
    private String values;

    @Column(name = "sync_policy", columnDefinition = "TEXT")
    private String syncPolicy;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    @CreationTimestamp
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    @UpdateTimestamp
    private Instant updatedAt;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "duration_seconds")
    private Long durationSeconds;

    @ElementCollection
    @CollectionTable(name = "deployment_metadata", 
                     joinColumns = @JoinColumn(name = "deployment_id"))
    @MapKeyColumn(name = "metadata_key")
    @Column(name = "metadata_value")
    private Map<String, String> metadata;

    public enum DeploymentStatus {
        PENDING,
        IN_PROGRESS,
        SUCCESS,
        FAILED,
        CANCELLED,
        ROLLBACK
    }
} 
package com.rtte.argocd.orchestrator.model.domain;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import jakarta.persistence.*;
import java.util.List;

/**
 * Domain model representing a sync wave for microservice deployment.
 * Manages deployment ordering and health checks for 55+ microservices.
 */
@Entity
@Table(name = "sync_waves")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncWave {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "customer_id", nullable = false)
    private String customerId;
    
    @Column(name = "wave_number", nullable = false)
    private Integer waveNumber;
    
    @Column(name = "wave_name")
    private String waveName;
    
    @ElementCollection
    @CollectionTable(name = "sync_wave_services",
                    joinColumns = @JoinColumn(name = "sync_wave_id"))
    @Column(name = "service_name")
    private List<String> services;
    
    @Column(name = "status")
    @Enumerated(EnumType.STRING)
    private SyncWaveStatus status = SyncWaveStatus.PENDING;
    
    @Column(name = "total_services")
    private Integer totalServices = 0;
    
    @Column(name = "deployed_services")
    private Integer deployedServices = 0;
    
    @Column(name = "healthy_services")
    private Integer healthyServices = 0;
    
    @Column(name = "failed_services")
    private Integer failedServices = 0;
    
    @Column(name = "start_time")
    private java.time.LocalDateTime startTime;
    
    @Column(name = "end_time")
    private java.time.LocalDateTime endTime;
    
    @Column(name = "timeout_seconds")
    private Integer timeoutSeconds = 300; // 5 minutes default
    
    @Column(name = "health_check_timeout_seconds")
    private Integer healthCheckTimeoutSeconds = 60; // 1 minute default
    
    @Column(name = "retry_count")
    private Integer retryCount = 0;
    
    @Column(name = "max_retries")
    private Integer maxRetries = 3;
    
    @Column(name = "retry_delay_seconds")
    private Integer retryDelaySeconds = 30;
    
    @Column(name = "dependencies_satisfied")
    private Boolean dependenciesSatisfied = false;
    
    @Column(name = "created_at")
    private java.time.LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private java.time.LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = java.time.LocalDateTime.now();
        updatedAt = java.time.LocalDateTime.now();
        if (services != null) {
            totalServices = services.size();
        }
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = java.time.LocalDateTime.now();
    }
    
    /**
     * Start the sync wave deployment
     */
    public void start() {
        this.status = SyncWaveStatus.DEPLOYING;
        this.startTime = java.time.LocalDateTime.now();
        this.deployedServices = 0;
        this.healthyServices = 0;
        this.failedServices = 0;
    }
    
    /**
     * Complete the sync wave deployment
     */
    public void complete() {
        this.status = SyncWaveStatus.COMPLETED;
        this.endTime = java.time.LocalDateTime.now();
    }
    
    /**
     * Fail the sync wave deployment
     */
    public void fail() {
        this.status = SyncWaveStatus.FAILED;
        this.endTime = java.time.LocalDateTime.now();
    }
    
    /**
     * Retry the sync wave deployment
     */
    public void retry() {
        if (retryCount < maxRetries) {
            this.retryCount++;
            this.status = SyncWaveStatus.RETRYING;
            this.startTime = java.time.LocalDateTime.now();
            this.deployedServices = 0;
            this.healthyServices = 0;
            this.failedServices = 0;
        } else {
            this.status = SyncWaveStatus.FAILED;
            this.endTime = java.time.LocalDateTime.now();
        }
    }
    
    /**
     * Update deployment progress
     */
    public void updateProgress(int deployed, int healthy, int failed) {
        this.deployedServices = deployed;
        this.healthyServices = healthy;
        this.failedServices = failed;
        
        // Check if all services are deployed and healthy
        if (deployedServices.equals(totalServices) && healthyServices.equals(totalServices)) {
            this.status = SyncWaveStatus.COMPLETED;
            this.endTime = java.time.LocalDateTime.now();
        } else if (failedServices > 0 && (failedServices + healthyServices).equals(totalServices)) {
            this.status = SyncWaveStatus.FAILED;
            this.endTime = java.time.LocalDateTime.now();
        }
    }
    
    /**
     * Check if sync wave has timed out
     */
    public boolean hasTimedOut() {
        if (startTime == null) {
            return false;
        }
        
        java.time.LocalDateTime timeoutTime = startTime.plusSeconds(timeoutSeconds);
        return java.time.LocalDateTime.now().isAfter(timeoutTime);
    }
    
    /**
     * Get deployment duration in seconds
     */
    public Long getDurationSeconds() {
        if (startTime == null) {
            return 0L;
        }
        
        java.time.LocalDateTime endTime = this.endTime != null ? this.endTime : java.time.LocalDateTime.now();
        return java.time.Duration.between(startTime, endTime).getSeconds();
    }
    
    /**
     * Get deployment progress percentage
     */
    public double getProgressPercentage() {
        if (totalServices == 0) {
            return 0.0;
        }
        return (double) deployedServices / totalServices * 100.0;
    }
    
    /**
     * Get health check progress percentage
     */
    public double getHealthProgressPercentage() {
        if (totalServices == 0) {
            return 0.0;
        }
        return (double) healthyServices / totalServices * 100.0;
    }
    
    /**
     * Check if sync wave is ready to proceed
     */
    public boolean isReadyToProceed() {
        return status == SyncWaveStatus.COMPLETED && 
               dependenciesSatisfied && 
               healthyServices.equals(totalServices);
    }
    
    /**
     * Sync wave status enumeration
     */
    public enum SyncWaveStatus {
        PENDING,        // Wave is waiting to start
        DEPLOYING,      // Wave is currently deploying services
        HEALTH_CHECKING, // Wave is checking service health
        COMPLETED,      // Wave completed successfully
        FAILED,         // Wave failed
        RETRYING,       // Wave is being retried
        TIMED_OUT,      // Wave timed out
        CANCELLED       // Wave was cancelled
    }
    
    /**
     * Sync wave types for different deployment phases
     */
    public enum SyncWaveType {
        INFRASTRUCTURE(0, "Infrastructure"),
        DATABASES(1, "Databases"),
        CORE_APIS(2, "Core APIs"),
        BUSINESS_SERVICES(3, "Business Services"),
        FRONTEND(4, "Frontend"),
        MONITORING(5, "Monitoring"),
        CUSTOM(6, "Custom");
        
        private final int waveNumber;
        private final String displayName;
        
        SyncWaveType(int waveNumber, String displayName) {
            this.waveNumber = waveNumber;
            this.displayName = displayName;
        }
        
        public int getWaveNumber() {
            return waveNumber;
        }
        
        public String getDisplayName() {
            return displayName;
        }
        
        public static SyncWaveType fromWaveNumber(int waveNumber) {
            for (SyncWaveType type : values()) {
                if (type.waveNumber == waveNumber) {
                    return type;
                }
            }
            return CUSTOM;
        }
    }
} 
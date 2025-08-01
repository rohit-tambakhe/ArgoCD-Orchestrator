package com.rtte.argocd.orchestrator.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.fabric8.kubernetes.api.model.coordination.v1.Lease;
import io.fabric8.kubernetes.api.model.coordination.v1.LeaseBuilder;
import io.fabric8.kubernetes.client.KubernetesClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * State manager for StatefulSet operations with leader election
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class StateManager {

    private final KubernetesClient kubernetesClient;
    private final RedisTemplate<String, OrchestratorState> redisTemplate;
    private final ObjectMapper objectMapper;

    @Value("${orchestrator.pod-name:argocd-orchestrator-0}")
    private String podName;

    @Value("${orchestrator.pod-namespace:argocd-orchestrator}")
    private String namespace;

    @Value("${orchestrator.leader-election.enabled:true}")
    private boolean leaderElectionEnabled;

    @Value("${orchestrator.leader-election.lease-duration:15s}")
    private Duration leaseDuration;

    @Value("${orchestrator.leader-election.renew-deadline:10s}")
    private Duration renewDeadline;

    @Value("${orchestrator.leader-election.retry-period:2s}")
    private Duration retryPeriod;

    @Value("${orchestrator.state.storage-path:/data/state}")
    private String stateStoragePath;

    private volatile boolean isLeader = false;
    private volatile Instant lastLeaseRenewal = Instant.now();
    private final ScheduledExecutorService executor = Executors.newScheduledThreadPool(2);

    @PostConstruct
    public void init() {
        if (leaderElectionEnabled) {
            startLeaderElection();
        } else {
            isLeader = true;
            log.info("Leader election disabled, pod {} is leader", podName);
        }
    }

    /**
     * Start leader election process
     */
    private void startLeaderElection() {
        log.info("Starting leader election for pod: {}", podName);
        
        executor.scheduleWithFixedDelay(this::tryAcquireLeadership, 0, 
                retryPeriod.toSeconds(), TimeUnit.SECONDS);
        
        executor.scheduleWithFixedDelay(this::renewLease, leaseDuration.toSeconds() / 2, 
                leaseDuration.toSeconds() / 2, TimeUnit.SECONDS);
    }

    /**
     * Try to acquire leadership
     */
    private void tryAcquireLeadership() {
        try {
            var lease = getOrCreateLease();
            
            if (lease == null || isLeaseExpired(lease) || isLeaseOwner(lease)) {
                if (acquireLease()) {
                    onBecomeLeader();
                }
            } else {
                if (isLeader) {
                    onLoseLeadership();
                }
            }
        } catch (Exception e) {
            log.error("Error during leader election", e);
        }
    }

    /**
     * Renew lease if we are the leader
     */
    private void renewLease() {
        if (!isLeader) {
            return;
        }

        try {
            var lease = getLease();
            if (lease != null && isLeaseOwner(lease)) {
                renewLease(lease);
                lastLeaseRenewal = Instant.now();
            }
        } catch (Exception e) {
            log.error("Error renewing lease", e);
        }
    }

    /**
     * Get or create lease
     */
    private Lease getOrCreateLease() {
        var lease = getLease();
        if (lease == null) {
            lease = createLease();
        }
        return lease;
    }

    /**
     * Get existing lease
     */
    private Lease getLease() {
        return kubernetesClient.coordination().v1().leases()
                .inNamespace(namespace)
                .withName("orchestrator-leader")
                .get();
    }

    /**
     * Create new lease
     */
    private Lease createLease() {
        var lease = new LeaseBuilder()
                .withNewMetadata()
                .withName("orchestrator-leader")
                .withNamespace(namespace)
                .endMetadata()
                .withNewSpec()
                .withLeaseDurationSeconds((int) leaseDuration.toSeconds())
                .withRenewTime(Instant.now())
                .withHolderIdentity(podName)
                .endSpec()
                .build();

        return kubernetesClient.coordination().v1().leases()
                .inNamespace(namespace)
                .create(lease);
    }

    /**
     * Acquire lease
     */
    private boolean acquireLease() {
        try {
            var lease = getLease();
            if (lease == null) {
                createLease();
                return true;
            }

            if (isLeaseExpired(lease)) {
                lease.getSpec().setHolderIdentity(podName);
                lease.getSpec().setRenewTime(Instant.now());
                
                kubernetesClient.coordination().v1().leases()
                        .inNamespace(namespace)
                        .withName("orchestrator-leader")
                        .replace(lease);
                
                return true;
            }

            return false;
        } catch (Exception e) {
            log.error("Error acquiring lease", e);
            return false;
        }
    }

    /**
     * Renew lease
     */
    private void renewLease(Lease lease) {
        lease.getSpec().setRenewTime(Instant.now());
        
        kubernetesClient.coordination().v1().leases()
                .inNamespace(namespace)
                .withName("orchestrator-leader")
                .replace(lease);
    }

    /**
     * Check if lease is expired
     */
    private boolean isLeaseExpired(Lease lease) {
        if (lease.getSpec().getRenewTime() == null) {
            return true;
        }

        var renewTime = lease.getSpec().getRenewTime();
        var expirationTime = renewTime.plusSeconds(lease.getSpec().getLeaseDurationSeconds());
        
        return Instant.now().isAfter(expirationTime);
    }

    /**
     * Check if we are the lease owner
     */
    private boolean isLeaseOwner(Lease lease) {
        return podName.equals(lease.getSpec().getHolderIdentity());
    }

    /**
     * Called when becoming leader
     */
    private void onBecomeLeader() {
        if (!isLeader) {
            log.info("Pod {} became leader", podName);
            isLeader = true;
            startBackgroundTasks();
        }
    }

    /**
     * Called when losing leadership
     */
    private void onLoseLeadership() {
        if (isLeader) {
            log.info("Pod {} lost leadership", podName);
            isLeader = false;
            stopBackgroundTasks();
        }
    }

    /**
     * Start background tasks that should only run on leader
     */
    private void startBackgroundTasks() {
        log.info("Starting background tasks on leader pod");
        // Background tasks will be implemented in other services
    }

    /**
     * Stop background tasks
     */
    private void stopBackgroundTasks() {
        log.info("Stopping background tasks on non-leader pod");
        // Background tasks will be stopped in other services
    }

    /**
     * Save state to Redis and disk
     */
    public OrchestratorState saveState(OrchestratorState state) {
        try {
            // Save to Redis with pod-specific key
            var key = "orchestrator:state:" + state.getCustomerId();
            redisTemplate.opsForValue().set(key, state, Duration.ofHours(24));

            // Also persist to StatefulSet volume if leader
            if (isLeader) {
                persistToDisk(state);
            }

            return state;
        } catch (Exception e) {
            log.error("Failed to save state for customer: {}", state.getCustomerId(), e);
            throw new RuntimeException("Failed to save state", e);
        }
    }

    /**
     * Load state from Redis or disk
     */
    public OrchestratorState loadState(String customerId) {
        try {
            // Try Redis first
            var key = "orchestrator:state:" + customerId;
            var state = redisTemplate.opsForValue().get(key);
            
            if (state != null) {
                return state;
            }

            // Fallback to disk
            return loadFromDisk(customerId);
        } catch (Exception e) {
            log.error("Failed to load state for customer: {}", customerId, e);
            return null;
        }
    }

    /**
     * Persist state to disk
     */
    private void persistToDisk(OrchestratorState state) {
        try {
            var stateFile = Paths.get(stateStoragePath, state.getCustomerId() + ".json");
            Files.createDirectories(stateFile.getParent());
            Files.writeString(stateFile, objectMapper.writeValueAsString(state));
            log.debug("Persisted state to disk: {}", stateFile);
        } catch (IOException e) {
            log.error("Failed to persist state to disk", e);
        }
    }

    /**
     * Load state from disk
     */
    private OrchestratorState loadFromDisk(String customerId) {
        try {
            var stateFile = Paths.get(stateStoragePath, customerId + ".json");
            if (Files.exists(stateFile)) {
                var content = Files.readString(stateFile);
                return objectMapper.readValue(content, OrchestratorState.class);
            }
        } catch (IOException e) {
            log.error("Failed to load state from disk for customer: {}", customerId, e);
        }
        return null;
    }

    /**
     * Check if current pod is leader
     */
    public boolean isLeader() {
        return isLeader;
    }

    /**
     * Get last lease renewal time
     */
    public Instant getLastLeaseRenewal() {
        return lastLeaseRenewal;
    }

    /**
     * Orchestrator state model
     */
    public static class OrchestratorState {
        private String customerId;
        private Instant lastSyncTime;
        private String syncStatus;
        private String lastError;
        private Instant createdAt;
        private Instant updatedAt;

        // Getters and setters
        public String getCustomerId() { return customerId; }
        public void setCustomerId(String customerId) { this.customerId = customerId; }
        
        public Instant getLastSyncTime() { return lastSyncTime; }
        public void setLastSyncTime(Instant lastSyncTime) { this.lastSyncTime = lastSyncTime; }
        
        public String getSyncStatus() { return syncStatus; }
        public void setSyncStatus(String syncStatus) { this.syncStatus = syncStatus; }
        
        public String getLastError() { return lastError; }
        public void setLastError(String lastError) { this.lastError = lastError; }
        
        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
        
        public Instant getUpdatedAt() { return updatedAt; }
        public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
    }
} 
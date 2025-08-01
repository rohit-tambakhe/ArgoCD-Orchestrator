package com.rtte.argocd.orchestrator.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.Map;

/**
 * DTO for deployment responses
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeploymentResponse {

    private String deploymentId;
    private String status;
    private String message;
    private String argoApplicationName;
    private Instant createdAt;
    private Instant startedAt;
    private Instant completedAt;
    private Long durationSeconds;
    private String errorMessage;
    private Map<String, Object> details;
    private Map<String, String> metadata;

    public enum Status {
        PENDING,
        IN_PROGRESS,
        SUCCESS,
        FAILED,
        CANCELLED,
        ROLLBACK
    }
} 
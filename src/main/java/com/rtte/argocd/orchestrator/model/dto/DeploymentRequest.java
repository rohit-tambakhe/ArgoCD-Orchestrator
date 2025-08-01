package com.rtte.argocd.orchestrator.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.Map;

/**
 * DTO for deployment requests
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeploymentRequest {

    @NotBlank
    private String applicationName;

    @NotBlank
    private String environment;

    @NotBlank
    private String targetRevision;

    @NotBlank
    private String strategy;

    private String customerId;

    private String argoProject;

    private String sourceRepoUrl;

    private String sourcePath;

    private String destinationNamespace;

    private String destinationServer;

    private List<ParameterConfig> parameters;

    private Map<String, Object> values;

    private SyncPolicyConfig syncPolicy;

    private Map<String, String> metadata;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ParameterConfig {
        @NotBlank
        private String name;
        
        @NotBlank
        private String value;
        
        private boolean forceString = false;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SyncPolicyConfig {
        private boolean automated = true;
        private boolean prune = true;
        private boolean selfHeal = true;
        private SyncOptionsConfig syncOptions;
        private RetryStrategyConfig retry;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SyncOptionsConfig {
        private boolean createNamespace = true;
        private boolean prunePropagationPolicy = true;
        private boolean pruneLast = true;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RetryStrategyConfig {
        private int limit = 5;
        private String backoff = "exponential";
        private int duration = 5;
        private int factor = 2;
        private int maxDuration = 300;
    }
} 
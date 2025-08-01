package com.rtte.argocd.orchestrator.model.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * Customer configuration model representing CAC configuration
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerConfig {

    private String customer;
    private String environment;
    private List<ApplicationConfig> applications;
    private Map<String, Object> globalConfig;
    private Map<String, String> labels;
    private Map<String, String> annotations;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApplicationConfig {
        private String name;
        private boolean enabled = true;
        private String version;
        private String imageRepository;
        private String deploymentStrategy = "ROLLING_UPDATE";
        private int replicas = 1;
        private ResourceConfig resources;
        private Map<String, String> configMaps;
        private Map<String, String> volumeClaims;
        private List<ParameterConfig> parameters;
        private Map<String, Object> values;
        private String environment;
        private boolean autoSync = true;
        private String syncPolicy;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResourceConfig {
        private ResourceRequest requests;
        private ResourceRequest limits;

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class ResourceRequest {
            private String cpu;
            private String memory;
            private String storage;
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ParameterConfig {
        private String name;
        private String value;
        private boolean forceString = false;
    }
} 
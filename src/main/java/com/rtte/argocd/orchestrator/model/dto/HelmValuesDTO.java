package com.rtte.argocd.orchestrator.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * DTO for Helm chart values
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HelmValuesDTO {

    private String namespace;
    private ImageConfig image;
    private ResourceConfig resources;
    private Map<String, String> configMaps;
    private Map<String, String> volumeClaims;
    private int replicas;
    private Map<String, Object> values;
    private List<ParameterConfig> parameters;
    private Map<String, String> labels;
    private Map<String, String> annotations;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ImageConfig {
        private String repository;
        private String tag;
        private String pullPolicy;
        private String pullSecret;
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
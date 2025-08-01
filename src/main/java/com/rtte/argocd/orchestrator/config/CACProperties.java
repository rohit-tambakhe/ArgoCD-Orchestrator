package com.rtte.argocd.orchestrator.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Configuration properties for Config as Code (CAC) integration
 */
@Data
@Component
@ConfigurationProperties(prefix = "cac")
@Validated
public class CACProperties {

    @NotBlank
    private String repositoryUrl;

    @NotBlank
    private String branch = "main";

    @NotBlank
    private String configPath = "customers";

    private String sshKeyPath;

    private String username;

    private String password;

    @Valid
    @NotNull
    private ValidationConfig validation = new ValidationConfig();

    @Valid
    @NotNull
    private CacheConfig cache = new CacheConfig();

    @Data
    public static class ValidationConfig {
        private boolean enabled = true;
        private String schemaPath = "schemas/customer-config.yaml";
        private boolean strictMode = false;
    }

    @Data
    public static class CacheConfig {
        private int ttlMinutes = 5;
        private int maxSize = 1000;
    }
} 
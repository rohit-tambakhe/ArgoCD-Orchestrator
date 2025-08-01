package com.rtte.argocd.orchestrator.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Duration;
import java.util.List;

/**
 * Configuration properties for ArgoCD integration
 */
@Data
@Component
@ConfigurationProperties(prefix = "argocd")
@Validated
public class ArgoCDProperties {

    @NotBlank
    private String serverUrl;

    @NotBlank
    private String username;

    @NotBlank
    private String password;

    private boolean insecure = false;

    @NotNull
    private Duration timeout = Duration.ofSeconds(30);

    @NotNull
    private ApplicationSetConfig applicationSet = new ApplicationSetConfig();

    @NotNull
    private List<EnvironmentConfig> environments = List.of();

    @Data
    public static class ApplicationSetConfig {
        private boolean enabled = true;
        private String namespace = "argocd";
    }

    @Data
    public static class EnvironmentConfig {
        @NotBlank
        private String name;
        
        @NotBlank
        private String namespace;
        
        @NotBlank
        private String defaultStrategy = "ROLLING_UPDATE";
        
        private boolean approvalRequired = false;
        
        private List<String> allowedHours = List.of();
    }
} 
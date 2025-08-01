package com.rtte.argocd.orchestrator.config;

import io.fabric8.kubernetes.client.KubernetesClient;
import io.fabric8.kubernetes.client.KubernetesClientBuilder;
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

import jakarta.validation.constraints.NotBlank;

/**
 * Configuration for Kubernetes client integration
 */
@Configuration
public class KubernetesConfig {

    @Bean
    public KubernetesClient kubernetesClient() {
        return new KubernetesClientBuilder().build();
    }

    @Data
    @Component
    @ConfigurationProperties(prefix = "kubernetes")
    @Validated
    public static class KubernetesProperties {

        @NotBlank
        private String masterUrl = "https://kubernetes.default.svc";

        private String namespace = "argocd-orchestrator";

        private String serviceAccount = "argocd-orchestrator";

        private String configPath;

        private boolean trustCertificates = true;
    }
} 
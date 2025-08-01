package com.rtte.argocd.orchestrator.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Duration;

/**
 * Configuration properties for GitHub integration
 */
@Data
@Component
@ConfigurationProperties(prefix = "github")
@Validated
public class GitHubProperties {

    private String token;

    private String webhookSecret;

    @NotBlank
    private String apiUrl = "https://api.github.com";

    @NotNull
    private Duration timeout = Duration.ofSeconds(30);
} 
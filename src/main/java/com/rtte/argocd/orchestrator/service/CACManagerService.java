package com.rtte.argocd.orchestrator.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.rtte.argocd.orchestrator.config.CACProperties;
import com.rtte.argocd.orchestrator.engine.CACValidationEngine;
import com.rtte.argocd.orchestrator.model.domain.CustomerConfig;
import com.rtte.argocd.orchestrator.model.dto.HelmValuesDTO;
import com.rtte.argocd.orchestrator.repository.CustomerConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * Service for managing Config as Code (CAC) operations
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class CACManagerService {

    private final GitHubIntegrationService gitHubService;
    private final CACProperties cacProperties;
    private final CustomerConfigRepository configRepository;
    private final CACValidationEngine validationEngine;
    private final ApplicationEventPublisher eventPublisher;
    private final ObjectMapper yamlMapper;

    /**
     * Get customer configuration with caching
     */
    @Cacheable(value = "customerConfigs", key = "#customerId")
    public Mono<CustomerConfig> getCustomerConfig(String customerId) {
        return fetchConfigFromGit(customerId)
                .flatMap(this::parseAndValidateConfig)
                .doOnNext(config -> configRepository.save(config))
                .doOnError(error -> log.error("Failed to load config for customer {}", customerId, error));
    }

    /**
     * Get all customer configurations
     */
    public Mono<List<CustomerConfig>> getAllCustomerConfigs() {
        return gitHubService.listDirectory(
                        cacProperties.getRepositoryUrl(),
                        cacProperties.getConfigPath(),
                        cacProperties.getBranch()
                )
                .flatMapMany(Flux::fromIterable)
                .filter(path -> path.endsWith("/config.yaml"))
                .map(this::extractCustomerId)
                .flatMap(this::getCustomerConfig)
                .collectList();
    }

    /**
     * Generate Helm values for a specific application
     */
    public Mono<HelmValuesDTO> generateHelmValues(String customerId, String application) {
        return getCustomerConfig(customerId)
                .map(config -> buildHelmValues(config, application));
    }

    /**
     * Handle configuration change events
     */
    public void handleConfigChange(String customerId, boolean requiresRedeployment, List<String> affectedApplications) {
        log.info("Config change detected for customer: {}", customerId);
        evictCache(customerId);

        // Trigger redeployment if needed
        if (requiresRedeployment) {
            eventPublisher.publishEvent(new CACConfigChangeEvent(customerId, affectedApplications));
        }
    }

    /**
     * Evict cache for a customer
     */
    @CacheEvict(value = "customerConfigs", key = "#customerId")
    public Mono<Void> evictCache(String customerId) {
        log.debug("Evicting cache for customer: {}", customerId);
        return Mono.empty();
    }

    /**
     * Fetch configuration from Git repository
     */
    private Mono<String> fetchConfigFromGit(String customerId) {
        String configPath = String.format("%s/%s/config.yaml", 
                cacProperties.getConfigPath(), customerId);
        
        return gitHubService.getFileContent(
                cacProperties.getRepositoryUrl(),
                configPath,
                cacProperties.getBranch()
        );
    }

    /**
     * Parse and validate configuration
     */
    private Mono<CustomerConfig> parseAndValidateConfig(String configYaml) {
        return Mono.fromCallable(() -> {
            try {
                CustomerConfig config = yamlMapper.readValue(configYaml, CustomerConfig.class);
                
                if (cacProperties.getValidation().isEnabled()) {
                    validationEngine.validateConfig(config);
                }
                
                return config;
            } catch (Exception e) {
                log.error("Failed to parse customer config", e);
                throw new RuntimeException("Invalid customer configuration", e);
            }
        });
    }

    /**
     * Build Helm values from customer configuration
     */
    private HelmValuesDTO buildHelmValues(CustomerConfig config, String application) {
        var appConfig = config.getApplications().stream()
                .filter(app -> app.getName().equals(application))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Application " + application + " not found for customer " + config.getCustomer()));

        return HelmValuesDTO.builder()
                .namespace(config.getCustomer())
                .image(HelmValuesDTO.ImageConfig.builder()
                        .repository(appConfig.getImageRepository())
                        .tag(appConfig.getVersion())
                        .build())
                .resources(convertResourceConfig(appConfig.getResources()))
                .configMaps(appConfig.getConfigMaps())
                .volumeClaims(appConfig.getVolumeClaims())
                .replicas(appConfig.getReplicas())
                .values(appConfig.getValues())
                .parameters(convertParameterConfigs(appConfig.getParameters()))
                .labels(config.getLabels())
                .annotations(config.getAnnotations())
                .build();
    }

    /**
     * Extract customer ID from file path
     */
    private String extractCustomerId(String filePath) {
        String[] parts = filePath.split("/");
        if (parts.length >= 2) {
            return parts[parts.length - 2]; // customer-id/config.yaml
        }
        throw new IllegalArgumentException("Invalid config file path: " + filePath);
    }

    /**
     * Convert resource configuration
     */
    private HelmValuesDTO.ResourceConfig convertResourceConfig(CustomerConfig.ResourceConfig resourceConfig) {
        if (resourceConfig == null) {
            return null;
        }

        return HelmValuesDTO.ResourceConfig.builder()
                .requests(convertResourceRequest(resourceConfig.getRequests()))
                .limits(convertResourceRequest(resourceConfig.getLimits()))
                .build();
    }

    /**
     * Convert resource request
     */
    private HelmValuesDTO.ResourceConfig.ResourceRequest convertResourceRequest(
            CustomerConfig.ResourceConfig.ResourceRequest request) {
        if (request == null) {
            return null;
        }

        return HelmValuesDTO.ResourceConfig.ResourceRequest.builder()
                .cpu(request.getCpu())
                .memory(request.getMemory())
                .storage(request.getStorage())
                .build();
    }

    /**
     * Convert parameter configurations
     */
    private List<HelmValuesDTO.ParameterConfig> convertParameterConfigs(
            List<CustomerConfig.ParameterConfig> parameters) {
        if (parameters == null) {
            return List.of();
        }

        return parameters.stream()
                .map(param -> HelmValuesDTO.ParameterConfig.builder()
                        .name(param.getName())
                        .value(param.getValue())
                        .forceString(param.isForceString())
                        .build())
                .toList();
    }

    /**
     * Event class for CAC configuration changes
     */
    public static class CACConfigChangeEvent {
        private final String customerId;
        private final List<String> affectedApplications;

        public CACConfigChangeEvent(String customerId, List<String> affectedApplications) {
            this.customerId = customerId;
            this.affectedApplications = affectedApplications;
        }

        public String getCustomerId() {
            return customerId;
        }

        public List<String> getAffectedApplications() {
            return affectedApplications;
        }
    }
} 
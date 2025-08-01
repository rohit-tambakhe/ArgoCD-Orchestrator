package com.rtte.argocd.orchestrator.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rtte.argocd.orchestrator.model.domain.CustomerConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for processing CAC webhook events
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class CACWebhookProcessor {

    private final CACManagerService cacManager;
    private final ApplicationSetService applicationSetService;
    private final ApplicationEventPublisher eventPublisher;
    private final ObjectMapper objectMapper;

    /**
     * Process webhook event
     */
    public Mono<WebhookProcessingResult> processWebhook(String eventType, String payload) {
        if (!"push".equals(eventType)) {
            return Mono.just(WebhookProcessingResult.ignored("Only push events are processed"));
        }

        return Mono.fromCallable(() -> objectMapper.readValue(payload, PushEvent.class))
                .flatMap(this::processCACPushEvent);
    }

    /**
     * Process CAC push event
     */
    private Mono<WebhookProcessingResult> processCACPushEvent(PushEvent event) {
        // Extract changed files
        var changedFiles = event.getCommits().stream()
                .flatMap(commit -> commit.getAdded().stream())
                .filter(file -> file.startsWith("customers/"))
                .collect(Collectors.toList());

        if (changedFiles.isEmpty()) {
            return Mono.just(WebhookProcessingResult.ignored("No customer config changes"));
        }

        // Extract affected customers
        var affectedCustomers = changedFiles.stream()
                .map(this::extractCustomerFromPath)
                .distinct()
                .collect(Collectors.toList());

        // Process each affected customer
        return Flux.fromIterable(affectedCustomers)
                .flatMap(this::processCustomerConfigChange)
                .collectList()
                .map(results -> WebhookProcessingResult.success(
                        "Processed " + results.size() + " customer configs"));
    }

    /**
     * Process customer configuration change
     */
    private Mono<CustomerConfigChangeResult> processCustomerConfigChange(String customerId) {
        return cacManager.evictCache(customerId)
                .then(cacManager.getCustomerConfig(customerId))
                .flatMap(config -> applicationSetService.createOrUpdateApplicationSet(customerId))
                .map(appSet -> CustomerConfigChangeResult.success(customerId))
                .doOnNext(result -> eventPublisher.publishEvent(
                        new CACManagerService.CACConfigChangeEvent(customerId, 
                                extractAffectedApplications(customerId))))
                .onErrorReturn(CustomerConfigChangeResult.failure(customerId));
    }

    /**
     * Extract customer ID from file path
     */
    private String extractCustomerFromPath(String filePath) {
        String[] parts = filePath.split("/");
        if (parts.length >= 2) {
            return parts[1]; // customers/customer-id/...
        }
        throw new IllegalArgumentException("Invalid file path: " + filePath);
    }

    /**
     * Extract affected applications for a customer
     */
    private List<String> extractAffectedApplications(String customerId) {
        // This would typically query the customer config to get affected applications
        // For now, return a default list
        return List.of("uqh"); // Default application
    }

    /**
     * Webhook processing result
     */
    public static class WebhookProcessingResult {
        private final boolean success;
        private final String message;
        private final List<CustomerConfigChangeResult> customerResults;

        private WebhookProcessingResult(boolean success, String message, 
                                      List<CustomerConfigChangeResult> customerResults) {
            this.success = success;
            this.message = message;
            this.customerResults = customerResults;
        }

        public static WebhookProcessingResult success(String message) {
            return new WebhookProcessingResult(true, message, List.of());
        }

        public static WebhookProcessingResult ignored(String message) {
            return new WebhookProcessingResult(false, message, List.of());
        }

        public boolean isSuccess() { return success; }
        public String getMessage() { return message; }
        public List<CustomerConfigChangeResult> getCustomerResults() { return customerResults; }
    }

    /**
     * Customer configuration change result
     */
    public static class CustomerConfigChangeResult {
        private final String customerId;
        private final boolean success;
        private final String errorMessage;

        private CustomerConfigChangeResult(String customerId, boolean success, String errorMessage) {
            this.customerId = customerId;
            this.success = success;
            this.errorMessage = errorMessage;
        }

        public static CustomerConfigChangeResult success(String customerId) {
            return new CustomerConfigChangeResult(customerId, true, null);
        }

        public static CustomerConfigChangeResult failure(String customerId) {
            return new CustomerConfigChangeResult(customerId, false, "Processing failed");
        }

        public String getCustomerId() { return customerId; }
        public boolean isSuccess() { return success; }
        public String getErrorMessage() { return errorMessage; }
    }

    /**
     * GitHub push event model
     */
    public static class PushEvent {
        private String ref;
        private List<Commit> commits;

        public String getRef() { return ref; }
        public void setRef(String ref) { this.ref = ref; }
        public List<Commit> getCommits() { return commits; }
        public void setCommits(List<Commit> commits) { this.commits = commits; }
    }

    /**
     * GitHub commit model
     */
    public static class Commit {
        private String id;
        private List<String> added;
        private List<String> modified;
        private List<String> removed;

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public List<String> getAdded() { return added; }
        public void setAdded(List<String> added) { this.added = added; }
        public List<String> getModified() { return modified; }
        public void setModified(List<String> modified) { this.modified = modified; }
        public List<String> getRemoved() { return removed; }
        public void setRemoved(List<String> removed) { this.removed = removed; }
    }
} 
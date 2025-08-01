package com.rtte.argocd.orchestrator.controller;

import com.rtte.argocd.orchestrator.service.CACWebhookProcessor;
import com.rtte.argocd.orchestrator.service.WebhookSecurityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

/**
 * Enhanced webhook controller for handling GitHub and CAC webhooks
 */
@RestController
@RequestMapping("/webhooks")
@Slf4j
@RequiredArgsConstructor
@Validated
public class EnhancedWebhookController {

    private final CACWebhookProcessor cacWebhookProcessor;
    private final WebhookSecurityService webhookSecurityService;

    /**
     * Handle CAC webhook events
     */
    @PostMapping("/cac")
    public Mono<ResponseEntity<String>> handleCACWebhook(
            @RequestHeader("X-GitHub-Event") String eventType,
            @RequestHeader("X-GitHub-Delivery") String deliveryId,
            @RequestHeader("X-Hub-Signature-256") String signature,
            @RequestBody String payload) {

        return webhookSecurityService.validateGitHubSignature(signature, payload)
                .filter(Boolean::booleanValue)
                .switchIfEmpty(Mono.error(new SecurityException("Invalid webhook signature")))
                .then(cacWebhookProcessor.processWebhook(eventType, payload))
                .map(result -> ResponseEntity.ok("CAC webhook processed successfully"))
                .doOnNext(response -> log.info("CAC webhook {} processed successfully", deliveryId))
                .doOnError(error -> log.error("Failed to process CAC webhook {}", deliveryId, error))
                .onErrorReturn(ResponseEntity.badRequest().body("Webhook processing failed"));
    }

    /**
     * Handle GitHub webhook events for application deployments
     */
    @PostMapping("/github")
    public Mono<ResponseEntity<String>> handleGitHubWebhook(
            @RequestHeader("X-GitHub-Event") String eventType,
            @RequestHeader("X-GitHub-Delivery") String deliveryId,
            @RequestHeader("X-Hub-Signature-256") String signature,
            @RequestBody String payload) {

        return webhookSecurityService.validateGitHubSignature(signature, payload)
                .filter(Boolean::booleanValue)
                .switchIfEmpty(Mono.error(new SecurityException("Invalid webhook signature")))
                .then(Mono.fromCallable(() -> {
                    log.info("Processing GitHub webhook: {} for delivery: {}", eventType, deliveryId);
                    // Process GitHub webhook logic here
                    return "GitHub webhook processed";
                }))
                .map(result -> ResponseEntity.ok(result))
                .doOnNext(response -> log.info("GitHub webhook {} processed successfully", deliveryId))
                .doOnError(error -> log.error("Failed to process GitHub webhook {}", deliveryId, error))
                .onErrorReturn(ResponseEntity.badRequest().body("GitHub webhook processing failed"));
    }

    /**
     * Health check endpoint for webhooks
     */
    @GetMapping("/health")
    public Mono<ResponseEntity<String>> healthCheck() {
        return Mono.just(ResponseEntity.ok("Webhook service is healthy"));
    }
} 
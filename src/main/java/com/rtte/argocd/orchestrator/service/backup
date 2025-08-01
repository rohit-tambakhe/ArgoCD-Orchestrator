package com.rtte.argocd.orchestrator.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rtte.argocd.orchestrator.config.ArgoCDProperties;
import com.rtte.argocd.orchestrator.config.CACProperties;
import com.rtte.argocd.orchestrator.integration.argocd.ArgoCDIntegrationService;
import com.rtte.argocd.orchestrator.model.domain.ApplicationSetSpec;
import com.rtte.argocd.orchestrator.model.domain.CustomerConfig;
import io.fabric8.kubernetes.api.model.GenericKubernetesResource;
import io.fabric8.kubernetes.api.model.PatchContext;
import io.fabric8.kubernetes.api.model.PatchType;
import io.fabric8.kubernetes.client.KubernetesClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.util.List;
import java.util.Map;

/**
 * Service for managing ArgoCD ApplicationSets
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class ApplicationSetService {

    private final ArgoCDIntegrationService argoCDService;
    private final CACManagerService cacManager;
    private final CACProperties cacProperties;
    private final ArgoCDProperties argoCDProperties;
    private final KubernetesClient kubernetesClient;
    private final ObjectMapper objectMapper;

    /**
     * Create or update ApplicationSet for a customer
     */
    public Mono<ApplicationSetSpec> createOrUpdateApplicationSet(String customerId) {
        return cacManager.getCustomerConfig(customerId)
                .map(this::buildApplicationSetSpec)
                .flatMap(this::applyApplicationSet);
    }

    /**
     * Delete ApplicationSet for a customer
     */
    public Mono<Void> deleteApplicationSet(String customerId) {
        return Mono.fromCallable(() -> {
            var resource = kubernetesClient
                    .customResource(ApplicationSetSpec.class)
                    .inNamespace(argoCDProperties.getApplicationSet().getNamespace());

            resource.withName(customerId + "-apps").delete();
            return null;
        })
        .subscribeOn(Schedulers.boundedElastic())
        .doOnSuccess(result -> log.info("Deleted ApplicationSet for customer: {}", customerId))
        .doOnError(error -> log.error("Failed to delete ApplicationSet for customer: {}", customerId, error));
    }

    /**
     * Build ApplicationSet specification from customer configuration
     */
    private ApplicationSetSpec buildApplicationSetSpec(CustomerConfig config) {
        return ApplicationSetSpec.builder()
                .metadata(ApplicationSetSpec.ObjectMeta.builder()
                        .name(config.getCustomer() + "-apps")
                        .namespace(argoCDProperties.getApplicationSet().getNamespace())
                        .labels(Map.of(
                                "customer", config.getCustomer(),
                                "managed-by", "orchestrator"
                        ))
                        .build())
                .spec(ApplicationSetSpec.ApplicationSetSpecDetails.builder()
                        .generators(buildGenerators(config))
                        .template(buildApplicationTemplate(config))
                        .build())
                .build();
    }

    /**
     * Build generators for ApplicationSet
     */
    private List<ApplicationSetSpec.Generator> buildGenerators(CustomerConfig config) {
        return List.of(
                ApplicationSetSpec.Generator.builder()
                        .git(ApplicationSetSpec.GitGenerator.builder()
                                .repoURL(cacProperties.getRepositoryUrl())
                                .revision(cacProperties.getBranch())
                                .files(List.of(
                                        ApplicationSetSpec.FileGenerator.builder()
                                                .path("customers/" + config.getCustomer() + "/*/values.yaml")
                                                .build()
                                ))
                                .build())
                        .build(),
                ApplicationSetSpec.Generator.builder()
                        .matrix(ApplicationSetSpec.MatrixGenerator.builder()
                                .generators(buildMatrixGenerators(config))
                                .build())
                        .build()
        );
    }

    /**
     * Build matrix generators for applications
     */
    private List<ApplicationSetSpec.Generator> buildMatrixGenerators(CustomerConfig config) {
        return config.getApplications().stream()
                .filter(CustomerConfig.ApplicationConfig::isEnabled)
                .map(app -> ApplicationSetSpec.Generator.builder()
                        .list(ApplicationSetSpec.ListGenerator.builder()
                                .elements(List.of(Map.of(
                                        "customer", config.getCustomer(),
                                        "application", app.getName(),
                                        "version", app.getVersion(),
                                        "strategy", app.getDeploymentStrategy(),
                                        "replicas", app.getReplicas()
                                )))
                                .build())
                        .build())
                .toList();
    }

    /**
     * Build application template
     */
    private ApplicationSetSpec.ApplicationTemplate buildApplicationTemplate(CustomerConfig config) {
        return ApplicationSetSpec.ApplicationTemplate.builder()
                .metadata(ApplicationSetSpec.ApplicationMetadata.builder()
                        .name("{{customer}}-{{application}}")
                        .namespace(argoCDProperties.getApplicationSet().getNamespace())
                        .finalizers(List.of("resources-finalizer.argocd.argoproj.io"))
                        .annotations(Map.of(
                                "deployment.strategy", "{{strategy}}",
                                "customer.id", config.getCustomer()
                        ))
                        .build())
                .spec(ApplicationSetSpec.ApplicationSpec.builder()
                        .project("{{customer}}-project")
                        .source(buildSource(config))
                        .destination(buildDestination(config))
                        .syncPolicy(buildSyncPolicy(config))
                        .build())
                .build();
    }

    /**
     * Build source configuration
     */
    private ApplicationSetSpec.Source buildSource(CustomerConfig config) {
        return ApplicationSetSpec.Source.builder()
                .repoURL("https://github.com/rtte/helm-charts")
                .targetRevision("{{revision}}")
                .path("charts/{{application}}")
                .helm(ApplicationSetSpec.HelmSource.builder()
                        .valueFiles(List.of(
                                "values.yaml",
                                "../../cac-configs/customers/{{customer}}/{{application}}/values.yaml"
                        ))
                        .parameters(buildHelmParameters(config))
                        .build())
                .build();
    }

    /**
     * Build destination configuration
     */
    private ApplicationSetSpec.Destination buildDestination(CustomerConfig config) {
        return ApplicationSetSpec.Destination.builder()
                .server("https://kubernetes.default.svc")
                .namespace(config.getCustomer())
                .build();
    }

    /**
     * Build sync policy
     */
    private ApplicationSetSpec.SyncPolicy buildSyncPolicy(CustomerConfig config) {
        return ApplicationSetSpec.SyncPolicy.builder()
                .automated(true)
                .prune(true)
                .selfHeal(true)
                .syncOptions(ApplicationSetSpec.SyncOptions.builder()
                        .createNamespace(true)
                        .prunePropagationPolicy(true)
                        .pruneLast(true)
                        .build())
                .retry(ApplicationSetSpec.RetryStrategy.builder()
                        .limit(5)
                        .backoff("exponential")
                        .duration(5)
                        .factor(2)
                        .maxDuration(300)
                        .build())
                .build();
    }

    /**
     * Build Helm parameters
     */
    private List<ApplicationSetSpec.HelmParameter> buildHelmParameters(CustomerConfig config) {
        return List.of(
                ApplicationSetSpec.HelmParameter.builder()
                        .name("customer")
                        .value(config.getCustomer())
                        .build(),
                ApplicationSetSpec.HelmParameter.builder()
                        .name("environment")
                        .value(config.getEnvironment())
                        .build()
        );
    }

    /**
     * Apply ApplicationSet to Kubernetes
     */
    private Mono<ApplicationSetSpec> applyApplicationSet(ApplicationSetSpec spec) {
        return Mono.fromCallable(() -> {
            var resource = kubernetesClient
                    .customResource(ApplicationSetSpec.class)
                    .inNamespace(argoCDProperties.getApplicationSet().getNamespace());

            var existing = resource.withName(spec.getMetadata().getName()).get();

            if (existing != null) {
                return resource.withName(spec.getMetadata().getName())
                        .patch(PatchContext.of(PatchType.STRATEGIC_MERGE), spec);
            } else {
                return resource.create(spec);
            }
        })
        .subscribeOn(Schedulers.boundedElastic())
        .doOnSuccess(result -> log.info("Applied ApplicationSet: {}", spec.getMetadata().getName()))
        .doOnError(error -> log.error("Failed to apply ApplicationSet: {}", spec.getMetadata().getName(), error));
    }
} 
package com.rtte.argocd.orchestrator.model.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * ApplicationSet specification model for ArgoCD
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApplicationSetSpec {

    private ObjectMeta metadata;
    private ApplicationSetSpecDetails spec;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ObjectMeta {
        private String name;
        private String namespace;
        private Map<String, String> labels;
        private Map<String, String> annotations;
        private List<String> finalizers;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApplicationSetSpecDetails {
        private List<Generator> generators;
        private ApplicationTemplate template;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Generator {
        private GitGenerator git;
        private MatrixGenerator matrix;
        private ListGenerator list;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GitGenerator {
        private String repoURL;
        private String revision;
        private List<FileGenerator> files;
        private List<DirectoryGenerator> directories;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FileGenerator {
        private String path;
        private String pathExpression;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DirectoryGenerator {
        private String path;
        private boolean exclude;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MatrixGenerator {
        private List<Generator> generators;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListGenerator {
        private List<Map<String, Object>> elements;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApplicationTemplate {
        private ApplicationMetadata metadata;
        private ApplicationSpec spec;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApplicationMetadata {
        private String name;
        private String namespace;
        private List<String> finalizers;
        private Map<String, String> annotations;
        private Map<String, String> labels;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApplicationSpec {
        private String project;
        private Source source;
        private Destination destination;
        private SyncPolicy syncPolicy;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Source {
        private String repoURL;
        private String targetRevision;
        private String path;
        private HelmSource helm;
        private KustomizeSource kustomize;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class HelmSource {
        private List<String> valueFiles;
        private List<HelmParameter> parameters;
        private Map<String, Object> values;
        private String releaseName;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class HelmParameter {
        private String name;
        private String value;
        private boolean forceString = false;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class KustomizeSource {
        private List<String> images;
        private Map<String, String> commonLabels;
        private Map<String, String> commonAnnotations;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Destination {
        private String server;
        private String namespace;
        private String name;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SyncPolicy {
        private boolean automated;
        private boolean prune;
        private boolean selfHeal;
        private SyncOptions syncOptions;
        private RetryStrategy retry;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SyncOptions {
        private boolean createNamespace = true;
        private boolean prunePropagationPolicy = true;
        private boolean pruneLast = true;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RetryStrategy {
        private int limit;
        private String backoff;
        private int duration;
        private int factor;
        private int maxDuration;
    }
} 
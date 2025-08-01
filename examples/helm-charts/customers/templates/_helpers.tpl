{{/*
Expand the name of the chart.
*/}}
{{- define "customer-services.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "customer-services.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "customer-services.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "customer-services.labels" -}}
helm.sh/chart: {{ include "customer-services.chart" . }}
{{ include "customer-services.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "customer-services.selectorLabels" -}}
app.kubernetes.io/name: {{ include "customer-services.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Customer-specific labels
*/}}
{{- define "customer-services.customerLabels" -}}
customer: {{ .Values.global.customerId }}
environment: {{ .Values.global.environment }}
{{- end }}

{{/*
Sync wave condition template
*/}}
{{- define "syncWaveCondition" -}}
{{- $wave := . }}
{{- if $wave.sync-wave }}
argocd.argoproj.io/sync-wave: "{{ $wave.sync-wave }}"
{{- end }}
{{- if $wave.timeout }}
argocd.argoproj.io/sync-options: "Prune=false"
argocd.argoproj.io/sync-timeout: "{{ $wave.timeout }}"
{{- end }}
{{- end }}

{{/*
Dependency condition template
*/}}
{{- define "dependencyCondition" -}}
{{- $service := . }}
{{- if $service.dependencies }}
orchestrator.rtte.com/dependencies: "{{ join "," $service.dependencies }}"
{{- end }}
{{- if $service.dependencyTimeout }}
orchestrator.rtte.com/dependency-timeout: "{{ $service.dependencyTimeout }}"
{{- end }}
{{- end }}

{{/*
Health check condition template
*/}}
{{- define "healthCheckCondition" -}}
{{- $service := . }}
{{- if $service.healthCheck }}
orchestrator.rtte.com/health-check-enabled: "true"
orchestrator.rtte.com/health-endpoint: "{{ $service.healthCheck.endpoint }}"
orchestrator.rtte.com/health-port: "{{ $service.healthCheck.port | default 8080 }}"
orchestrator.rtte.com/health-interval: "{{ $service.healthCheck.intervalSeconds | default 30 }}s"
orchestrator.rtte.com/health-timeout: "{{ $service.healthCheck.timeoutSeconds | default 10 }}s"
orchestrator.rtte.com/health-failure-threshold: "{{ $service.healthCheck.failureThreshold | default 3 }}"
{{- else }}
orchestrator.rtte.com/health-check-enabled: "false"
{{- end }}
{{- end }}

{{/*
Deployment strategy condition template
*/}}
{{- define "deploymentStrategyCondition" -}}
{{- $service := . }}
{{- if $service.deploymentStrategy }}
orchestrator.rtte.com/deployment-strategy: "{{ $service.deploymentStrategy }}"
{{- if eq $service.deploymentStrategy "BLUE_GREEN" }}
orchestrator.rtte.com/blue-green-enabled: "true"
orchestrator.rtte.com/auto-promotion: "{{ $service.autoPromotion | default false }}"
orchestrator.rtte.com/scale-down-delay: "{{ $service.scaleDownDelaySeconds | default 30 }}s"
{{- end }}
{{- if eq $service.deploymentStrategy "CANARY" }}
orchestrator.rtte.com/canary-enabled: "true"
orchestrator.rtte.com/canary-steps: "{{ $service.canarySteps | default '25,50,75,100' }}"
orchestrator.rtte.com/canary-pause-duration: "{{ $service.canaryPauseDuration | default '30s' }}"
{{- end }}
{{- if eq $service.deploymentStrategy "ROLLING_UPDATE" }}
orchestrator.rtte.com/rolling-update-enabled: "true"
orchestrator.rtte.com/max-surge: "{{ $service.maxSurge | default '25%' }}"
orchestrator.rtte.com/max-unavailable: "{{ $service.maxUnavailable | default '25%' }}"
{{- end }}
{{- end }}
{{- end }}

{{/*
Rollback condition template
*/}}
{{- define "rollbackCondition" -}}
{{- $service := . }}
{{- if $service.rollback.enabled }}
orchestrator.rtte.com/rollback-enabled: "true"
orchestrator.rtte.com/rollback-timeout: "{{ $service.rollback.rollbackTimeoutSeconds | default 300 }}s"
orchestrator.rtte.com/rollback-window: "{{ $service.rollback.rollbackWindow | default '5m' }}"
{{- if $service.rollback.autoRollback }}
orchestrator.rtte.com/auto-rollback: "true"
{{- end }}
{{- else }}
orchestrator.rtte.com/rollback-enabled: "false"
{{- end }}
{{- end }}

{{/*
Resource requirements template
*/}}
{{- define "resourceRequirements" -}}
{{- $resources := . }}
{{- if $resources }}
resources:
  {{- if $resources.requests }}
  requests:
    {{- if $resources.requests.cpu }}
    cpu: {{ $resources.requests.cpu }}
    {{- end }}
    {{- if $resources.requests.memory }}
    memory: {{ $resources.requests.memory }}
    {{- end }}
  {{- end }}
  {{- if $resources.limits }}
  limits:
    {{- if $resources.limits.cpu }}
    cpu: {{ $resources.limits.cpu }}
    {{- end }}
    {{- if $resources.limits.memory }}
    memory: {{ $resources.limits.memory }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Volume claims template
*/}}
{{- define "volumeClaims" -}}
{{- $volumeClaims := . }}
{{- if $volumeClaims }}
volumeClaimTemplates:
  {{- range $volumeClaims }}
  - metadata:
      name: {{ .name }}
    spec:
      accessModes: ["ReadWriteOnce"]
      {{- if .storageClass }}
      storageClassName: {{ .storageClass }}
      {{- end }}
      resources:
        requests:
          storage: {{ .size }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
ConfigMap volume mounts template
*/}}
{{- define "configMapVolumeMounts" -}}
{{- $configMaps := . }}
{{- if $configMaps }}
volumes:
  {{- range $configMaps }}
  - name: {{ . }}-config
    configMap:
      name: {{ $.Values.global.customerId }}-{{ . }}-config
  {{- end }}
volumeMounts:
  {{- range $configMaps }}
  - name: {{ . }}-config
    mountPath: /config/{{ . }}
    readOnly: true
  {{- end }}
{{- end }}
{{- end }}

{{/*
Secret volume mounts template
*/}}
{{- define "secretVolumeMounts" -}}
{{- $secrets := . }}
{{- if $secrets }}
volumes:
  {{- range $secrets }}
  - name: {{ . }}-secret
    secret:
      secretName: {{ $.Values.global.customerId }}-{{ . }}-secret
  {{- end }}
volumeMounts:
  {{- range $secrets }}
  - name: {{ . }}-secret
    mountPath: /secrets/{{ . }}
    readOnly: true
  {{- end }}
{{- end }}
{{- end }}

{{/*
Service mesh annotations template
*/}}
{{- define "serviceMeshAnnotations" -}}
{{- if .Values.istio.enabled }}
sidecar.istio.io/inject: "true"
sidecar.istio.io/rewriteAppHTTPProbers: "true"
{{- if .Values.istio.virtualService.enabled }}
orchestrator.rtte.com/virtual-service: "{{ .Values.global.customerId }}-{{ .name }}-vs"
{{- end }}
{{- if .Values.istio.destinationRule.enabled }}
orchestrator.rtte.com/destination-rule: "{{ .Values.global.customerId }}-{{ .name }}-dr"
{{- end }}
{{- end }}
{{- end }}

{{/*
Monitoring annotations template
*/}}
{{- define "monitoringAnnotations" -}}
{{- if .Values.monitoring.enabled }}
prometheus.io/scrape: "true"
prometheus.io/port: "{{ .Values.monitoring.serviceMonitor.port | default 'http' }}"
prometheus.io/path: "{{ .Values.monitoring.serviceMonitor.path | default '/metrics' }}"
{{- if .Values.monitoring.serviceMonitor.interval }}
prometheus.io/interval: "{{ .Values.monitoring.serviceMonitor.interval }}"
{{- end }}
{{- end }}
{{- end }}

{{/*
Circuit breaker annotations template
*/}}
{{- define "circuitBreakerAnnotations" -}}
{{- if .Values.global.circuitBreaker.enabled }}
orchestrator.rtte.com/circuit-breaker-enabled: "true"
orchestrator.rtte.com/circuit-breaker-threshold: "{{ .Values.global.circuitBreaker.threshold | default 5 }}"
orchestrator.rtte.com/circuit-breaker-timeout: "{{ .Values.global.circuitBreaker.timeout | default '30s' }}"
orchestrator.rtte.com/circuit-breaker-half-open-limit: "{{ .Values.global.circuitBreaker.halfOpenLimit | default 2 }}"
{{- end }}
{{- end }}

{{/*
Security context template
*/}}
{{- define "securityContext" -}}
{{- if .Values.global.securityContext }}
securityContext:
  {{- if .Values.global.securityContext.runAsNonRoot }}
  runAsNonRoot: {{ .Values.global.securityContext.runAsNonRoot }}
  {{- end }}
  {{- if .Values.global.securityContext.runAsUser }}
  runAsUser: {{ .Values.global.securityContext.runAsUser }}
  {{- end }}
  {{- if .Values.global.securityContext.fsGroup }}
  fsGroup: {{ .Values.global.securityContext.fsGroup }}
  {{- end }}
  {{- if .Values.global.securityContext.capabilities }}
  capabilities:
    {{- if .Values.global.securityContext.capabilities.drop }}
    drop:
      {{- range .Values.global.securityContext.capabilities.drop }}
      - {{ . }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Pod disruption budget template
*/}}
{{- define "podDisruptionBudget" -}}
{{- $service := . }}
{{- if $service.podDisruptionBudget }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ $.Values.global.customerId }}-{{ $service.name }}-pdb
  namespace: {{ $.Values.global.namespace }}
  labels:
    app: {{ $service.name }}
    customer: {{ $.Values.global.customerId }}
spec:
  {{- if $service.podDisruptionBudget.minAvailable }}
  minAvailable: {{ $service.podDisruptionBudget.minAvailable }}
  {{- end }}
  {{- if $service.podDisruptionBudget.maxUnavailable }}
  maxUnavailable: {{ $service.podDisruptionBudget.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      app: {{ $service.name }}
      customer: {{ $.Values.global.customerId }}
{{- end }}
{{- end }}

{{/*
Horizontal pod autoscaler template
*/}}
{{- define "horizontalPodAutoscaler" -}}
{{- $service := . }}
{{- if $service.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $.Values.global.customerId }}-{{ $service.name }}-hpa
  namespace: {{ $.Values.global.namespace }}
  labels:
    app: {{ $service.name }}
    customer: {{ $.Values.global.customerId }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $.Values.global.customerId }}-{{ $service.name }}
  minReplicas: {{ $service.autoscaling.minReplicas | default 1 }}
  maxReplicas: {{ $service.autoscaling.maxReplicas | default 10 }}
  metrics:
    {{- if $service.autoscaling.cpu }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $service.autoscaling.cpu.targetAverageUtilization | default 80 }}
    {{- end }}
    {{- if $service.autoscaling.memory }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $service.autoscaling.memory.targetAverageUtilization | default 80 }}
    {{- end }}
    {{- if $service.autoscaling.customMetrics }}
    {{- range $service.autoscaling.customMetrics }}
    - type: Object
      object:
        metric:
          name: {{ .name }}
        describedObject:
          apiVersion: v1
          kind: Service
          name: {{ $.Values.global.customerId }}-{{ $service.name }}
        target:
          type: AverageValue
          averageValue: {{ .targetAverageValue }}
    {{- end }}
    {{- end }}
  {{- if $service.autoscaling.behavior }}
  behavior:
    {{- if $service.autoscaling.behavior.scaleUp }}
    scaleUp:
      {{- if $service.autoscaling.behavior.scaleUp.stabilizationWindowSeconds }}
      stabilizationWindowSeconds: {{ $service.autoscaling.behavior.scaleUp.stabilizationWindowSeconds }}
      {{- end }}
      {{- if $service.autoscaling.behavior.scaleUp.policies }}
      policies:
        {{- range $service.autoscaling.behavior.scaleUp.policies }}
        - type: {{ .type }}
          value: {{ .value }}
          periodSeconds: {{ .periodSeconds }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if $service.autoscaling.behavior.scaleDown }}
    scaleDown:
      {{- if $service.autoscaling.behavior.scaleDown.stabilizationWindowSeconds }}
      stabilizationWindowSeconds: {{ $service.autoscaling.behavior.scaleDown.stabilizationWindowSeconds }}
      {{- end }}
      {{- if $service.autoscaling.behavior.scaleDown.policies }}
      policies:
        {{- range $service.autoscaling.behavior.scaleDown.policies }}
        - type: {{ .type }}
          value: {{ .value }}
          periodSeconds: {{ .periodSeconds }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }} 
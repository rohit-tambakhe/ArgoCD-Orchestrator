{{/*
Expand the name of the chart.
*/}}
{{- define "base-services.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "base-services.fullname" -}}
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
{{- define "base-services.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "base-services.labels" -}}
helm.sh/chart: {{ include "base-services.chart" . }}
{{ include "base-services.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "base-services.selectorLabels" -}}
app.kubernetes.io/name: {{ include "base-services.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Environment labels
*/}}
{{- define "base-services.environmentLabels" -}}
environment: {{ .Values.global.environment }}
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
ConfigMap volume mounts template
*/}}
{{- define "configMapVolumeMounts" -}}
{{- $configMaps := . }}
{{- if $configMaps }}
volumes:
  {{- range $configMaps }}
  - name: {{ .name }}-config
    configMap:
      name: {{ $.Release.Name }}-{{ .name }}-config
  {{- end }}
volumeMounts:
  {{- range $configMaps }}
  - name: {{ .name }}-config
    mountPath: /config/{{ .name }}
    readOnly: true
  {{- end }}
{{- end }}
{{- end }}

{{/*
Storage template
*/}}
{{- define "storage" -}}
{{- $storage := . }}
{{- if $storage }}
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      {{- if $storage.storageClass }}
      storageClassName: {{ $storage.storageClass }}
      {{- end }}
      resources:
        requests:
          storage: {{ $storage.size }}
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
Service mesh annotations template
*/}}
{{- define "serviceMeshAnnotations" -}}
{{- if .Values.infrastructure.istio.enabled }}
sidecar.istio.io/inject: "true"
sidecar.istio.io/rewriteAppHTTPProbers: "true"
{{- end }}
{{- end }}

{{/*
Monitoring annotations template
*/}}
{{- define "monitoringAnnotations" -}}
{{- if .Values.monitoring.enabled }}
prometheus.io/scrape: "true"
prometheus.io/port: "http"
prometheus.io/path: "/metrics"
{{- end }}
{{- end }}

{{/*
Network policy template
*/}}
{{- define "networkPolicy" -}}
{{- $policy := . }}
{{- if $policy }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $.Release.Name }}-{{ $policy.name }}-network-policy
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "base-services.labels" $ | nindent 4 }}
spec:
  {{- if $policy.podSelector }}
  podSelector:
    {{- toYaml $policy.podSelector | nindent 4 }}
  {{- end }}
  {{- if $policy.policyTypes }}
  policyTypes:
    {{- range $policy.policyTypes }}
    - {{ . }}
    {{- end }}
  {{- end }}
  {{- if $policy.ingress }}
  ingress:
    {{- toYaml $policy.ingress | nindent 4 }}
  {{- end }}
  {{- if $policy.egress }}
  egress:
    {{- toYaml $policy.egress | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Resource quota template
*/}}
{{- define "resourceQuota" -}}
{{- $quota := . }}
{{- if $quota }}
apiVersion: v1
kind: ResourceQuota
metadata:
  name: {{ $.Release.Name }}-{{ $quota.name }}-quota
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "base-services.labels" $ | nindent 4 }}
spec:
  hard:
    {{- range $key, $value := $quota }}
    {{ $key }}: {{ $value }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Limit range template
*/}}
{{- define "limitRange" -}}
{{- $limits := . }}
{{- if $limits }}
apiVersion: v1
kind: LimitRange
metadata:
  name: {{ $.Release.Name }}-{{ $limits.name }}-limits
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "base-services.labels" $ | nindent 4 }}
spec:
  limits:
    {{- if $limits.default }}
    - type: Container
      default:
        {{- toYaml $limits.default | nindent 8 }}
    {{- end }}
    {{- if $limits.defaultRequest }}
    - type: Container
      defaultRequest:
        {{- toYaml $limits.defaultRequest | nindent 8 }}
    {{- end }}
    {{- if $limits.max }}
    - type: Container
      max:
        {{- toYaml $limits.max | nindent 8 }}
    {{- end }}
    {{- if $limits.min }}
    - type: Container
      min:
        {{- toYaml $limits.min | nindent 8 }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Service account template
*/}}
{{- define "serviceAccount" -}}
{{- $sa := . }}
{{- if $sa }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $sa.name }}
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "base-services.labels" $ | nindent 4 }}
  {{- if $sa.annotations }}
  annotations:
    {{- toYaml $sa.annotations | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Cluster role template
*/}}
{{- define "clusterRole" -}}
{{- $role := . }}
{{- if $role }}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ $role.name }}
  labels:
    {{- include "base-services.labels" $ | nindent 4 }}
rules:
  {{- range $role.rules }}
  - apiGroups:
      {{- range .apiGroups }}
      - {{ . }}
      {{- end }}
    resources:
      {{- range .resources }}
      - {{ . }}
      {{- end }}
    verbs:
      {{- range .verbs }}
      - {{ . }}
      {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Cluster role binding template
*/}}
{{- define "clusterRoleBinding" -}}
{{- $binding := . }}
{{- if $binding }}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ $binding.name }}
  labels:
    {{- include "base-services.labels" $ | nindent 4 }}
roleRef:
  apiGroup: {{ $binding.roleRef.apiGroup }}
  kind: {{ $binding.roleRef.kind }}
  name: {{ $binding.roleRef.name }}
subjects:
  {{- range $binding.subjects }}
  - kind: {{ .kind }}
    name: {{ .name }}
    namespace: {{ .namespace }}
  {{- end }}
{{- end }}
{{- end }} 
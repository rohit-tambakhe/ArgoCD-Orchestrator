# ArgoCD Orchestrator for rtte

A comprehensive ArgoCD orchestrator with Config as Code (CAC) integration, Argo Events (Sensors) driven architecture, and sync-wave dependency management for managing 55+ microservices on AWS EKS.

## 🏗️ Enhanced Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Git Repositories                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Helm Charts   │  │  CAC Configs    │  │ Application Code│  │
│  │   (uqh-chart)   │  │  (customers/)   │  │  (microservices)│  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │ Webhooks
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Argo Events (EventBus)                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   EventSource   │  │     Sensor      │  │   Trigger       │  │
│  │  (GitHub, SNS)  │  │  (Dependency    │  │  (ArgoCD Sync)  │  │
│  │                 │  │   Resolution)   │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │ Events
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              ArgoCD Orchestrator (Java + Spring Boot)           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ CAC Manager     │  │ Dependency      │  │ GitHub          │  │
│  │                 │  │ Engine          │  │ Integration     │  │
│  │                 │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ ApplicationSet  │  │ Sync Wave       │  │ State Manager   │  │
│  │   Generator     │  │ Manager         │  │  (StatefulSet)  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Microservice    │  │ Health Check    │  │ Rollback        │  │
│  │ Dependency      │  │ Manager         │  │ Manager         │  │
│  │ Resolver        │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS EKS Cluster                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Customer A NS  │  │  Customer B NS  │  │ Customer C NS   │  │
│  │  (55+ services) │  │  (55+ services) │  │  (55+ services) │  │
│  │  Sync Waves:    │  │  Sync Waves:    │  │  Sync Waves:    │  │
│  │  0: Infra       │  │  0: Infra       │  │  0: Infra       │  │
│  │  1: Databases   │  │  1: Databases   │  │  1: Databases   │  │
│  │  2: Core APIs   │  │  2: Core APIs   │  │  2: Core APIs   │  │
│  │  3: Business    │  │  3: Business    │  │  3: Business    │  │
│  │  4: Frontend    │  │  4: Frontend    │  │  4: Frontend    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## ✨ Enhanced Key Features

- **Config as Code (CAC)**: Customer configurations stored in Git repositories
- **Multi-tenant Support**: Isolated customer environments with namespace separation
- **Argo Events Integration**: Event-driven architecture with Sensors and EventSources
- **Sync Wave Management**: Intelligent dependency resolution for 55+ microservices
- **Microservice Dependency Graph**: Automatic dependency resolution and ordering
- **Health Check Orchestration**: Comprehensive health monitoring across services
- **Rollback Management**: Intelligent rollback strategies with dependency awareness
- **StatefulSet Deployment**: Leader election and state persistence
- **Dynamic ApplicationSet Generation**: Automatic ArgoCD ApplicationSet creation
- **GitHub Integration**: Webhook-based deployment triggers
- **Helm Chart Support**: Integration with existing Helm charts (uqh-chart)
- **Monitoring & Observability**: Prometheus metrics, distributed tracing, and health checks
- **Security**: RBAC, webhook signature validation, and secure secrets management
- **Circuit Breaker Pattern**: Fault tolerance and resilience
- **Blue-Green/Canary Deployments**: Advanced deployment strategies

## 🚀 Quick Start

### Prerequisites

- Java 17+
- Maven 3.8+
- Docker
- Kubernetes cluster (AWS EKS recommended)
- ArgoCD installed
- Argo Events installed
- PostgreSQL database
- Redis instance
- Prometheus & Grafana (for monitoring)

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/rtte/argocd-orchestrator.git
   cd argocd-orchestrator
   ```

2. **Set up environment variables**
   ```bash
   export DB_HOST=localhost
   export DB_PORT=5432
   export DB_NAME=argocd_orchestrator
   export DB_USERNAME=postgres
   export DB_PASSWORD=password
   export REDIS_HOST=localhost
   export REDIS_PORT=6379
   export ARGOCD_SERVER_URL=https://argocd.example.com
   export ARGOCD_USERNAME=admin
   export ARGOCD_PASSWORD=admin123
   export GITHUB_TOKEN=your-github-token
   export CAC_REPOSITORY_URL=https://github.com/rtte/cac-configs
   export ARGO_EVENTS_NAMESPACE=argo-events
   export PROMETHEUS_URL=http://localhost:9090
   ```

3. **Build the application**
   ```bash
   mvn clean package
   ```

4. **Run the application**
   ```bash
   java -jar target/argocd-orchestrator-1.0.0.jar
   ```

### Production Deployment

1. **Install Argo Events**
   ```bash
   kubectl create namespace argo-events
   kubectl apply -f https://github.com/argoproj/argo-events/releases/download/v1.8.0/install.yaml
   ```

2. **Create namespace**
   ```bash
   kubectl create namespace argocd-orchestrator
   ```

3. **Create secrets**
   ```bash
   kubectl create secret generic orchestrator-secrets \
     --from-literal=db-username=postgres \
     --from-literal=db-password=$DB_PASSWORD \
     --from-literal=github-token=$GITHUB_TOKEN \
     --from-literal=argocd-password=$ARGOCD_PASSWORD \
     --from-literal=github-webhook-secret=$WEBHOOK_SECRET \
     --from-literal=argo-events-webhook-secret=$ARGO_EVENTS_SECRET \
     -n argocd-orchestrator

   kubectl create secret generic git-ssh-key \
     --from-file=ssh-privatekey=/path/to/ssh-key \
     -n argocd-orchestrator
   ```

4. **Deploy the orchestrator**
   ```bash
   kubectl apply -f k8s/statefulset.yaml
   kubectl apply -f k8s/argo-events/
   ```

5. **Verify deployment**
   ```bash
   kubectl get pods -n argocd-orchestrator
   kubectl get pods -n argo-events
   kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator
   ```

## 📁 Enhanced Project Structure

```
argocd-orchestrator/
├── src/main/java/com/rtte/argocd/orchestrator/
│   ├── config/                          # Configuration classes
│   │   ├── ArgoCDProperties.java
│   │   ├── CACProperties.java
│   │   ├── GitHubProperties.java
│   │   ├── KubernetesConfig.java
│   │   ├── ArgoEventsProperties.java
│   │   └── SyncWaveProperties.java
│   ├── controller/                      # REST controllers
│   │   ├── EnhancedWebhookController.java
│   │   ├── ArgoEventsController.java
│   │   ├── SyncWaveController.java
│   │   └── HealthCheckController.java
│   ├── service/                         # Business logic services
│   │   ├── CACManagerService.java
│   │   ├── ApplicationSetService.java
│   │   ├── StateManager.java
│   │   ├── CACWebhookProcessor.java
│   │   ├── DependencyResolutionService.java
│   │   ├── SyncWaveManagerService.java
│   │   ├── MicroserviceHealthService.java
│   │   ├── RollbackManagerService.java
│   │   └── ArgoEventsIntegrationService.java
│   ├── model/                           # Domain models and DTOs
│   │   ├── domain/
│   │   │   ├── Deployment.java
│   │   │   ├── CustomerConfig.java
│   │   │   ├── ApplicationSetSpec.java
│   │   │   ├── Microservice.java
│   │   │   ├── DependencyGraph.java
│   │   │   ├── SyncWave.java
│   │   │   └── HealthStatus.java
│   │   └── dto/
│   │       ├── DeploymentRequest.java
│   │       ├── DeploymentResponse.java
│   │       ├── HelmValuesDTO.java
│   │       ├── DependencyRequest.java
│   │       └── SyncWaveRequest.java
│   ├── repository/                      # Data access layer
│   │   ├── DeploymentRepository.java
│   │   ├── MicroserviceRepository.java
│   │   └── DependencyRepository.java
│   ├── integration/                     # External integrations
│   │   ├── ArgoCDClient.java
│   │   ├── ArgoEventsClient.java
│   │   ├── GitHubClient.java
│   │   └── PrometheusClient.java
│   ├── engine/                          # Business logic engines
│   │   ├── DependencyResolutionEngine.java
│   │   ├── SyncWaveEngine.java
│   │   ├── HealthCheckEngine.java
│   │   └── RollbackEngine.java
│   └── util/                            # Utility classes
│       ├── GraphUtils.java
│       ├── HelmUtils.java
│       └── ValidationUtils.java
├── src/main/resources/
│   ├── application.yml                  # Main configuration
│   ├── db/migration/                    # Database migrations
│   ├── schemas/                         # JSON schemas
│   │   ├── microservice-schema.json
│   │   └── dependency-schema.json
│   └── templates/                       # Helm templates
│       ├── sync-wave-template.yaml
│       └── dependency-graph-template.yaml
├── k8s/                                 # Kubernetes manifests
│   ├── statefulset.yaml
│   ├── argo-events/                     # Argo Events configuration
│   │   ├── eventbus.yaml
│   │   ├── eventsource.yaml
│   │   ├── sensor.yaml
│   │   └── trigger.yaml
│   ├── sync-waves/                      # Sync wave definitions
│   │   ├── infrastructure.yaml
│   │   ├── databases.yaml
│   │   ├── core-apis.yaml
│   │   ├── business-services.yaml
│   │   └── frontend.yaml
│   └── monitoring/                      # Monitoring configuration
│       ├── prometheus-rules.yaml
│       ├── grafana-dashboards.yaml
│       └── alertmanager-config.yaml
├── examples/                            # Example configurations
│   ├── helm-charts/                     # Helm charts for customers
│   │   ├── customers/                   # Customer-specific values
│   │   │   ├── customer-a/
│   │   │   │   ├── values.yaml          # 8 configMaps + 55 microservices
│   │   │   │   ├── Chart.yaml
│   │   │   │   ├── templates/
│   │   │   │   │   ├── _helpers.tpl     # Sync wave & dependency conditions
│   │   │   │   │   ├── deployment.yaml
│   │   │   │   │   ├── service.yaml
│   │   │   │   │   ├── configmap.yaml
│   │   │   │   │   └── secret.yaml
│   │   │   │   └── .helmignore
│   │   │   ├── customer-b/
│   │   │   └── ... (more customers)
│   │   └── base/                        # Base chart templates
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── _helpers.tpl
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── configmap.yaml
│   │           └── secret.yaml
│   ├── cac-configs/                     # Legacy configs (deprecated)
│   └── dependency-graphs/               # Dependency graph examples
│       ├── customer-a-dependencies.yaml
│       └── customer-b-dependencies.yaml
├── k8s/                                 # Kubernetes manifests
│   ├── argocd/                          # ArgoCD configuration
│   │   ├── applicationset.yaml          # ApplicationSet for customers
│   │   ├── project.yaml                 # ArgoCD project
│   │   └── rbac.yaml                    # RBAC configuration
│   ├── statefulset.yaml                 # Orchestrator deployment
│   ├── argo-events/                     # Argo Events configuration
│   │   ├── eventbus.yaml
│   │   ├── eventsource.yaml
│   │   ├── sensor.yaml
│   │   └── trigger.yaml
│   ├── sync-waves/                      # Sync wave definitions
│   │   ├── infrastructure.yaml
│   │   ├── databases.yaml
│   │   ├── core-apis.yaml
│   │   ├── business-services.yaml
│   │   └── frontend.yaml
│   └── monitoring/                      # Monitoring configuration
│       ├── prometheus-rules.yaml
│       ├── grafana-dashboards.yaml
│       └── alertmanager-config.yaml
└── pom.xml
```

## 🔧 Enhanced Configuration

### Application Properties

The main configuration is in `src/main/resources/application.yml`:

```yaml
# ArgoCD Configuration
argocd:
  server-url: https://argocd.example.com
  username: admin
  password: ${ARGOCD_PASSWORD}
  application-set:
    enabled: true
    namespace: argocd

# Helm Configuration
helm:
  charts-path: examples/helm-charts/customers
  base-chart: examples/helm-charts/base
  validation:
    enabled: true
    schema-path: schemas/helm-values.yaml

# Argo Events Configuration
argo-events:
  namespace: argo-events
  eventbus: default
  webhook-secret: ${ARGO_EVENTS_WEBHOOK_SECRET}
  sensor:
    enabled: true
    reconciliation-period: 10s

# Sync Wave Configuration
sync-wave:
  enabled: true
  max-waves: 10
  health-check-timeout: 300s
  rollback-threshold: 3
  dependency-resolution:
    algorithm: topological-sort
    max-retries: 3
    retry-delay: 30s

# Microservice Configuration
microservices:
  total-count: 55
  health-check:
    enabled: true
    interval: 30s
    timeout: 10s
    failure-threshold: 3
  dependency:
    auto-discovery: true
    graph-visualization: true
    circular-dependency-detection: true

# StatefulSet Configuration
orchestrator:
  leader-election:
    enabled: true
    lease-duration: 15s
  sync:
    interval: 300000 # 5 minutes

# Monitoring Configuration
monitoring:
  prometheus:
    url: ${PROMETHEUS_URL}
    enabled: true
  distributed-tracing:
    enabled: true
    jaeger-endpoint: ${JAEGER_ENDPOINT}
  alerting:
    enabled: true
    slack-webhook: ${SLACK_WEBHOOK_URL}
```

### Helm Values Configuration

Each customer has a dedicated `values.yaml` file with 8 configMaps and 55+ microservices:

```yaml
# examples/helm-charts/customers/customer-a/values.yaml
global:
  customerId: customer-a
  environment: production
  imageTag: "v2.1.0"  # Updated by CI/CD pipeline
  namespace: customer-a-production

# 8 ConfigMaps per customer
configMaps:
  app-config: customer-a-app-config
  database-config: customer-a-database-config
  cache-config: customer-a-cache-config
  messaging-config: customer-a-messaging-config
  monitoring-config: customer-a-monitoring-config
  security-config: customer-a-security-config
  integration-config: customer-a-integration-config
  feature-flags: customer-a-feature-flags

# Microservices organized by sync waves
microservices:
  infrastructure:
    sync-wave: 0
    services:
      - name: ingress-controller
        enabled: true
        image: nginx/ingress-controller:v1.8.0
        replicas: 2
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

      - name: cert-manager
        enabled: true
        image: jetstack/cert-manager:v1.12.0
        replicas: 1
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

      - name: external-secrets
        enabled: true
        image: external-secrets/external-secrets:v0.8.0
        replicas: 1
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

  databases:
    sync-wave: 1
    services:
      - name: postgres
        enabled: true
        image: postgres:15-alpine
        dependencies: []
        replicas: 1
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "2000m"
            memory: "4Gi"
        volumeClaims:
          - name: postgres-data
            size: 20Gi
            storageClass: gp2

      - name: redis
        enabled: true
        image: redis:7-alpine
        dependencies: []
        replicas: 1
        resources:
          requests:
            cpu: "200m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "2Gi"
        volumeClaims:
          - name: redis-data
            size: 10Gi
            storageClass: gp2

  core-apis:
    sync-wave: 2
    services:
      - name: user-service
        enabled: true
        image: rtte/user-service:{{ .Values.global.imageTag }}
        dependencies: [postgres, redis]
        healthCheck:
          endpoint: /health
          method: GET
          expectedStatus: 200
          timeoutSeconds: 10
          intervalSeconds: 30
        deploymentStrategy: ROLLING_UPDATE
        replicas: 3
        resources:
          requests:
            cpu: "200m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1024Mi"
        configMaps:
          - name: app-config
            key: customer-a-user-service-config
        secrets:
          - name: db-credentials
            key: customer-a-db-secret
        volumeClaims:
          - name: logs
            size: 5Gi
            storageClass: gp2
        rollback:
          enabled: true
          maxVersions: 5
          autoRollback: true
          failureThreshold: 3

      - name: auth-service
        enabled: true
        image: rtte/auth-service:{{ .Values.global.imageTag }}
        dependencies: [postgres, redis]
        healthCheck:
          endpoint: /health
          method: GET
          expectedStatus: 200
        deploymentStrategy: ROLLING_UPDATE
        replicas: 2
        resources:
          requests:
            cpu: "200m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1024Mi"
        configMaps:
          - name: app-config
            key: customer-a-auth-service-config
        secrets:
          - name: db-credentials
            key: customer-a-db-secret

      # ... 53 more microservices with similar configuration

  business-services:
    sync-wave: 3
    services:
      - name: payment-service
        enabled: true
        image: rtte/payment-service:{{ .Values.global.imageTag }}
        dependencies: [user-service, notification-service]
        healthCheck:
          endpoint: /health
          method: GET
          expectedStatus: 200
        deploymentStrategy: BLUE_GREEN
        replicas: 2
        resources:
          requests:
            cpu: "300m"
            memory: "768Mi"
          limits:
            cpu: "1500m"
            memory: "1536Mi"
        configMaps:
          - name: payment-config
            key: customer-a-payment-config
        secrets:
          - name: payment-gateway
            key: customer-a-payment-gateway-secret
        rollback:
          enabled: true
          maxVersions: 3
          autoRollback: true
          failureThreshold: 2

      # ... more business services

  frontend:
    sync-wave: 4
    services:
      - name: web-ui
        enabled: true
        image: rtte/web-ui:{{ .Values.global.imageTag }}
        dependencies: [user-service, payment-service]
        healthCheck:
          endpoint: /health
          method: GET
          expectedStatus: 200
        deploymentStrategy: ROLLING_UPDATE
        replicas: 2
        resources:
          requests:
            cpu: "100m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        configMaps:
          - name: app-config
            key: customer-a-web-ui-config
```

### Helm Chart Templates

The `_helpers.tpl` file contains conditions for sync waves and dependencies:

```yaml
# examples/helm-charts/customers/_helpers.tpl
{{/*
  Sync wave conditions for deployment ordering
*/}}
{{- define "syncWaveCondition" -}}
{{- $syncWave := .syncWave | default 0 -}}
{{- if eq $syncWave 0 -}}
  argocd.argoproj.io/sync-wave: "0"
{{- else if eq $syncWave 1 -}}
  argocd.argoproj.io/sync-wave: "1"
{{- else if eq $syncWave 2 -}}
  argocd.argoproj.io/sync-wave: "2"
{{- else if eq $syncWave 3 -}}
  argocd.argoproj.io/sync-wave: "3"
{{- else if eq $syncWave 4 -}}
  argocd.argoproj.io/sync-wave: "4"
{{- end -}}
{{- end -}}

{{/*
  Dependency conditions
*/}}
{{- define "dependencyCondition" -}}
{{- if .dependencies -}}
  argocd.argoproj.io/sync-options: "Prune=false"
  orchestrator.rtte.com/dependencies: '{{ .dependencies | toJson }}'
{{- end -}}
{{- end -}}

{{/*
  Health check conditions
*/}}
{{- define "healthCheckCondition" -}}
{{- if .healthCheck -}}
  orchestrator.rtte.com/health-check: '{{ .healthCheck | toJson }}'
{{- end -}}
{{- end -}}

{{/*
  Deployment strategy conditions
*/}}
{{- define "deploymentStrategyCondition" -}}
{{- if eq .deploymentStrategy "BLUE_GREEN" -}}
  orchestrator.rtte.com/deployment-strategy: "blue-green"
{{- else if eq .deploymentStrategy "CANARY" -}}
  orchestrator.rtte.com/deployment-strategy: "canary"
{{- else -}}
  orchestrator.rtte.com/deployment-strategy: "rolling-update"
{{- end -}}
{{- end -}}
```
    services: [payment-service, notification-service, analytics-service]
  - wave: 4
    name: frontend
    services: [web-ui, mobile-api, admin-dashboard]

applications:
  - name: user-service
    enabled: true
    version: "2.1.0"
    sync-wave: 2
    dependencies: [postgres, redis]
    health-check:
      endpoint: /health
      method: GET
      expected-status: 200
    deployment-strategy: BLUE_GREEN
    replicas: 3
    resources:
      requests:
        cpu: "200m"
        memory: "512Mi"
      limits:
        cpu: "1000m"
        memory: "1024Mi"
    config-maps:
      app-config: customer-a-user-service-config
    secrets:
      db-credentials: customer-a-db-secret
    volume-claims:
      logs: pvc-customer-a-user-service-logs
      data: pvc-customer-a-user-service-data
    rollback:
      enabled: true
      max-versions: 5
      auto-rollback: true
      failure-threshold: 3

  - name: payment-service
    enabled: true
    version: "1.8.0"
    sync-wave: 3
    dependencies: [user-service, postgres, redis]
    health-check:
      endpoint: /health
      method: GET
      expected-status: 200
    deployment-strategy: CANARY
    replicas: 2
    resources:
      requests:
        cpu: "300m"
        memory: "768Mi"
      limits:
        cpu: "1500m"
        memory: "1536Mi"
    config-maps:
      payment-config: customer-a-payment-config
    secrets:
      payment-gateway: customer-a-payment-gateway-secret
    volume-claims:
      logs: pvc-customer-a-payment-service-logs
    rollback:
      enabled: true
      max-versions: 3
      auto-rollback: true
      failure-threshold: 2

# ... (52 more microservices with similar configuration)
```

## 🔌 Enhanced API Endpoints

### Webhooks

- `POST /api/v1/webhooks/cac` - CAC configuration webhooks
- `POST /api/v1/webhooks/github` - GitHub application webhooks
- `POST /api/v1/webhooks/argo-events` - Argo Events webhooks
- `GET /api/v1/webhooks/health` - Webhook health check

### Management

- `GET /actuator/health` - Application health
- `GET /actuator/metrics` - Prometheus metrics
- `GET /swagger-ui.html` - API documentation

### Sync Wave Management

- `GET /api/v1/sync-waves` - List all sync waves
- `GET /api/v1/sync-waves/{wave}` - Get sync wave details
- `POST /api/v1/sync-waves/{wave}/trigger` - Trigger sync wave
- `GET /api/v1/sync-waves/{wave}/status` - Get sync wave status

### Dependency Management

- `GET /api/v1/dependencies` - List all dependencies
- `GET /api/v1/dependencies/graph` - Get dependency graph
- `POST /api/v1/dependencies/resolve` - Resolve dependencies
- `GET /api/v1/dependencies/circular` - Check for circular dependencies

### Health Checks

- `GET /api/v1/health/services` - All service health status
- `GET /api/v1/health/services/{service}` - Specific service health
- `POST /api/v1/health/services/{service}/check` - Trigger health check

### Rollback Management

- `GET /api/v1/rollback/history` - Rollback history
- `POST /api/v1/rollback/services/{service}` - Rollback specific service
- `POST /api/v1/rollback/wave/{wave}` - Rollback entire sync wave

## 🔄 Enhanced Workflow

### **Helm-Based Architecture Overview**

The ArgoCD Orchestrator uses a **Helm Charts + ApplicationSet** approach for managing 55+ microservices:

```
CI/CD Pipeline → Helm Charts (values.yaml) → ArgoCD ApplicationSet → Argo Workflows → Argo Orchestrator
```

### **Customer Configuration Structure**

Each customer has a dedicated Helm values file with 8 configMaps:

```yaml
# examples/helm-charts/customers/customer-a/values.yaml
global:
  customerId: customer-a
  environment: production
  imageTag: "v2.1.0"  # Updated by CI/CD

# 8 ConfigMaps per customer
configMaps:
  app-config: customer-a-app-config
  database-config: customer-a-database-config
  cache-config: customer-a-cache-config
  messaging-config: customer-a-messaging-config
  monitoring-config: customer-a-monitoring-config
  security-config: customer-a-security-config
  integration-config: customer-a-integration-config
  feature-flags: customer-a-feature-flags

# Microservices with sync waves
microservices:
  infrastructure:
    sync-wave: 0
    services:
      - name: ingress-controller
        enabled: true
        image: nginx/ingress-controller:v1.8.0
      - name: cert-manager
        enabled: true
        image: jetstack/cert-manager:v1.12.0
      - name: external-secrets
        enabled: true
        image: external-secrets/external-secrets:v0.8.0

  databases:
    sync-wave: 1
    services:
      - name: postgres
        enabled: true
        image: postgres:15-alpine
        dependencies: []
      - name: redis
        enabled: true
        image: redis:7-alpine
        dependencies: []

  core-apis:
    sync-wave: 2
    services:
      - name: user-service
        enabled: true
        image: rtte/user-service:{{ .Values.global.imageTag }}
        dependencies: [postgres, redis]
        healthCheck:
          endpoint: /health
          method: GET
          expectedStatus: 200
      - name: auth-service
        enabled: true
        image: rtte/auth-service:{{ .Values.global.imageTag }}
        dependencies: [postgres, redis]
      # ... 53 more microservices

  business-services:
    sync-wave: 3
    services:
      - name: payment-service
        enabled: true
        image: rtte/payment-service:{{ .Values.global.imageTag }}
        dependencies: [user-service, notification-service]
        deploymentStrategy: BLUE_GREEN
      # ... more business services

  frontend:
    sync-wave: 4
    services:
      - name: web-ui
        enabled: true
        image: rtte/web-ui:{{ .Values.global.imageTag }}
        dependencies: [user-service, payment-service]
```

### **CI/CD Pipeline Integration with Argo Workflows**

1. **Build and Tag Generation**
   ```yaml
   # .github/workflows/build-and-deploy.yml
   name: Build and Deploy
   on:
     push:
       branches: [main]
   
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Build and Push Images
           run: |
             # Build microservices
             docker build -t rtte/user-service:${{ github.sha }} ./services/user-service
             docker build -t rtte/payment-service:${{ github.sha }} ./services/payment-service
             # ... build all 55 microservices
             
             # Push to registry
             docker push rtte/user-service:${{ github.sha }}
             docker push rtte/payment-service:${{ github.sha }}
   
     update-helm-values:
       needs: build
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Update Helm Values
           run: |
             # Update image tags in all customer values.yaml files
             for customer in examples/helm-charts/customers/*/; do
               sed -i "s/imageTag: \".*\"/imageTag: \"${{ github.sha }}\"/g" $customer/values.yaml
             done
         
         - name: Commit and Push Changes
           run: |
             git config user.name "GitHub Actions"
             git config user.email "actions@github.com"
             git add examples/helm-charts/customers/*/values.yaml
             git commit -m "Update image tags to ${{ github.sha }}"
             git push
   
     trigger-argo-workflow:
       needs: update-helm-values
       runs-on: ubuntu-latest
       steps:
         - name: Trigger Argo Workflow
           run: |
             # Trigger Argo Workflow for deployment
             kubectl create -f k8s/argo-workflows/deployment-workflow.yaml \
               --dry-run=client -o yaml | \
               kubectl apply -f -
   ```

2. **Argo Workflow Execution**
   ```bash
   # Trigger workflow manually
   kubectl create -f k8s/argo-workflows/deployment-workflow.yaml
   
   # Monitor workflow progress
   kubectl get workflows -n argo-workflows
   kubectl logs -f -l workflows.argoproj.io/workflow=comprehensive-deployment-workflow
   ```

### **ArgoCD ApplicationSet Configuration**

```yaml
# k8s/argocd/applicationset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: customer-applications
  namespace: argocd
spec:
  generators:
    - git:
        repoURL: https://github.com/rtte/argo-orchestrator
        targetRevision: main
        directories:
          - path: examples/helm-charts/customers/*/
  
  template:
    metadata:
      name: '{{name}}-applications'
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/rtte/argo-orchestrator
        targetRevision: main
        path: '{{path}}'
        helm:
          valueFiles:
            - values.yaml
          parameters:
            - name: customerId
              value: '{{name}}'
      
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{name}}-production'
      
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - PrunePropagationPolicy=foreground
          - PruneLast=true
      
      # Argo Orchestrator integration
      annotations:
        orchestrator.rtte.com/customer-id: '{{name}}'
        orchestrator.rtte.com/sync-waves: "true"
        orchestrator.rtte.com/dependency-management: "true"
```

### **Helm Chart Structure with _helpers.tpl**

```yaml
# examples/helm-charts/customers/_helpers.tpl
{{/*
  Sync wave conditions for deployment ordering
*/}}
{{- define "syncWaveCondition" -}}
{{- $syncWave := .syncWave | default 0 -}}
{{- if eq $syncWave 0 -}}
  argocd.argoproj.io/sync-wave: "0"
{{- else if eq $syncWave 1 -}}
  argocd.argoproj.io/sync-wave: "1"
{{- else if eq $syncWave 2 -}}
  argocd.argoproj.io/sync-wave: "2"
{{- else if eq $syncWave 3 -}}
  argocd.argoproj.io/sync-wave: "3"
{{- else if eq $syncWave 4 -}}
  argocd.argoproj.io/sync-wave: "4"
{{- end -}}
{{- end -}}

{{/*
  Dependency conditions
*/}}
{{- define "dependencyCondition" -}}
{{- if .dependencies -}}
  argocd.argoproj.io/sync-options: "Prune=false"
  orchestrator.rtte.com/dependencies: '{{ .dependencies | toJson }}'
{{- end -}}
{{- end -}}

{{/*
  Health check conditions
*/}}
{{- define "healthCheckCondition" -}}
{{- if .healthCheck -}}
  orchestrator.rtte.com/health-check: '{{ .healthCheck | toJson }}'
{{- end -}}
{{- end -}}

{{/*
  Deployment strategy conditions
*/}}
{{- define "deploymentStrategyCondition" -}}
{{- if eq .deploymentStrategy "BLUE_GREEN" -}}
  orchestrator.rtte.com/deployment-strategy: "blue-green"
{{- else if eq .deploymentStrategy "CANARY" -}}
  orchestrator.rtte.com/deployment-strategy: "canary"
{{- else -}}
  orchestrator.rtte.com/deployment-strategy: "rolling-update"
{{- end -}}
{{- end -}}
```

### **Adding a New Customer**

1. **Create Customer Helm Values**
   ```bash
   # Create new customer directory
   mkdir -p examples/helm-charts/customers/customer-b
   
   # Copy template values
   cp examples/helm-charts/customers/customer-a/values.yaml examples/helm-charts/customers/customer-b/values.yaml
   
   # Customize for customer-b
   sed -i 's/customer-a/customer-b/g' examples/helm-charts/customers/customer-b/values.yaml
   ```

2. **Trigger Argo Workflow**
   ```bash
   # Create workflow with customer parameters
   kubectl create -f - <<EOF
   apiVersion: argoproj.io/v1alpha1
   kind: Workflow
   metadata:
     name: deploy-customer-b
     namespace: argo-workflows
   spec:
     arguments:
       parameters:
         - name: customer-id
           value: "customer-b"
         - name: environment
           value: "production"
         - name: image-tag
           value: "latest"
     workflowTemplateRef:
       name: deployment-workflow-template
   EOF
   ```

3. **Monitor Deployment**
   ```bash
   # Monitor workflow progress
   kubectl get workflows -n argo-workflows deploy-customer-b
   
   # Check Argo Rollouts
   kubectl get rollouts -n customer-b-production
   
   # Monitor sync waves
   kubectl logs -f -l app=argocd-orchestrator -n argocd-orchestrator
   ```

### **Updating Microservice Configuration**

1. **Update values.yaml**
   ```yaml
   # examples/helm-charts/customers/customer-a/values.yaml
   microservices:
     business-services:
       sync-wave: 3
       services:
         - name: payment-service
           enabled: true
           image: rtte/payment-service:{{ .Values.global.imageTag }}
           dependencies: [user-service, notification-service, audit-service]  # Added dependency
           deploymentStrategy: CANARY  # Changed strategy
   ```

2. **CI/CD Triggers Update**
   ```bash
   # Commit and push changes
   git add examples/helm-charts/customers/customer-a/values.yaml
   git commit -m "Update payment-service dependencies and strategy"
   git push origin main
   ```

3. **ArgoCD Syncs Automatically**
   ```bash
   # ArgoCD detects changes and syncs
   kubectl get applications -n argocd customer-a-applications -o yaml
   ```

### **Argo Workflows and Argo Rollouts Integration**

The deployment process uses **Argo Workflows** for orchestration and **Argo Rollouts** for advanced deployment strategies:

#### **Argo Workflows Pipeline**
```yaml
# k8s/argo-workflows/deployment-workflow.yaml
spec:
  templates:
    - name: deployment-pipeline
      steps:
        - - name: validate-prerequisites
        - - name: setup-argo-events
        - - name: deploy-orchestrator
        - - name: validate-helm-values
        - - name: trigger-application-set
        - - name: monitor-sync-waves
        - - name: validate-deployment
        - - name: notify-completion
```

#### **Argo Rollouts with _helpers.tpl Conditions**
```yaml
# examples/helm-charts/customers/templates/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  annotations:
    {{- include "syncWaveCondition" $wave | nindent 4 }}
    {{- include "dependencyCondition" $service | nindent 4 }}
    {{- include "healthCheckCondition" $service | nindent 4 }}
    {{- include "deploymentStrategyCondition" $service | nindent 4 }}
spec:
  strategy:
    {{- if eq $service.deploymentStrategy "BLUE_GREEN" }}
    blueGreen:
      activeService: {{ $.Values.global.customerId }}-{{ $service.name }}-active
      previewService: {{ $.Values.global.customerId }}-{{ $service.name }}-preview
      autoPromotionEnabled: false
    {{- else if eq $service.deploymentStrategy "CANARY" }}
    canary:
      steps:
        - setWeight: 25
        - pause: {duration: 30s}
        - setWeight: 50
        - pause: {duration: 30s}
        - setWeight: 75
        - pause: {duration: 30s}
        - setWeight: 100
    {{- end }}
```

#### **Analysis Templates for Health Checks**
```yaml
# k8s/argo-rollouts/analysis-template.yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  metrics:
    - name: success-rate
      successCondition: result[0] >= 0.95
      provider:
        prometheus:
          query: |
            sum(rate(http_requests_total{service="{{args.service-name}}", status=~"2.."}[5m])) 
            / 
            sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

### **Argo Orchestrator Integration**

The Argo Orchestrator monitors ArgoCD applications and manages:

- **Sync Wave Orchestration**: Ensures proper deployment order
- **Dependency Validation**: Validates service dependencies
- **Health Check Management**: Monitors service health
- **Rollback Management**: Handles failed deployments
- **Multi-tenant Isolation**: Manages customer environments

```bash
# Check orchestrator status
curl -X GET http://localhost:8080/api/v1/orchestrator/status

# Monitor customer deployments
curl -X GET http://localhost:8080/api/v1/customers/customer-a/deployments

# Check sync wave progress
curl -X GET http://localhost:8080/api/v1/customers/customer-a/sync-waves

# Monitor Argo Rollouts
kubectl get rollouts -n customer-a-production
kubectl argo rollouts get rollout customer-a-user-service -n customer-a-production
```

## 📊 Enhanced Monitoring

### Metrics

The application exposes comprehensive Prometheus metrics:

- `argocd_orchestrator_deployments_total` - Total deployments
- `argocd_orchestrator_deployments_active` - Active deployments
- `argocd_orchestrator_sync_waves_total` - Total sync waves
- `argocd_orchestrator_sync_waves_duration_seconds` - Sync wave duration
- `argocd_orchestrator_dependencies_resolved_total` - Dependencies resolved
- `argocd_orchestrator_health_checks_total` - Health checks performed
- `argocd_orchestrator_rollbacks_total` - Total rollbacks
- `argocd_orchestrator_microservices_healthy` - Healthy microservices count
- `argocd_orchestrator_cac_sync_duration_seconds` - CAC sync duration
- `argocd_orchestrator_leader_election_status` - Leader election status

### Health Checks

- **Liveness**: `/actuator/health/liveness`
- **Readiness**: `/actuator/health/readiness`
- **Startup**: `/actuator/health/startup`
- **Microservice Health**: `/api/v1/health/services`
- **Dependency Health**: `/api/v1/dependencies/health`

### Distributed Tracing

- **Jaeger Integration**: Automatic tracing for all API calls
- **Trace Correlation**: Correlate traces across microservices
- **Performance Monitoring**: Track sync wave performance

### Alerting

- **Sync Wave Failures**: Alert when sync waves fail
- **Health Check Failures**: Alert when services become unhealthy
- **Dependency Resolution Failures**: Alert when dependencies can't be resolved
- **Rollback Events**: Alert when rollbacks occur

### Logging

Enhanced structured logging with correlation IDs:

- Console: Standard output with JSON format
- File: `/app/logs/argocd-orchestrator.log`
- Kubernetes: `kubectl logs -n argocd-orchestrator`
- Centralized: ELK stack integration

## 🔒 Enhanced Security

### Authentication & Authorization

- **Webhook Security**: GitHub signature validation
- **Argo Events Security**: Webhook signature validation
- **RBAC**: Kubernetes role-based access control
- **OAuth2 Integration**: JWT token validation
- **Secrets Management**: Kubernetes secrets for sensitive data

### Network Security

- **Pod Security**: Non-root containers with security contexts
- **Network Policies**: Isolated customer namespaces
- **TLS**: Encrypted communication with mTLS
- **Service Mesh**: Istio integration for service-to-service communication

### Compliance

- **Audit Logging**: Comprehensive audit trails
- **Data Encryption**: At-rest and in-transit encryption
- **Access Control**: Fine-grained access control
- **Compliance Reports**: Automated compliance reporting

## 🧪 Enhanced Testing

The ArgoCD Orchestrator includes comprehensive testing strategies to ensure reliability and performance for 55+ microservices deployments.

### 🧪 Unit Tests

Run unit tests for individual components:

```bash
# Run all unit tests
mvn test

# Run specific test class
mvn test -Dtest=DependencyResolutionServiceTest

# Run tests with coverage
mvn test jacoco:report

# Run tests in parallel
mvn test -Dparallel=methods -DthreadCount=4
```

**Key Unit Test Areas:**
- Dependency resolution algorithms
- Sync wave management
- Microservice health checks
- Argo Events integration
- Configuration validation
- Database operations

### 🔗 Integration Tests

Test component interactions and external integrations:

```bash
# Run all integration tests
mvn test -Dtest=*IntegrationTest

# Run specific integration test category
mvn test -Dtest=*ArgoCDIntegrationTest
mvn test -Dtest=*ArgoEventsIntegrationTest
mvn test -Dtest=*DatabaseIntegrationTest

# Run with test containers
mvn test -Dtest=*IntegrationTest -Dspring.profiles.active=test-containers
```

**Integration Test Coverage:**
- ArgoCD API interactions
- Argo Events webhook processing
- Database connectivity and migrations
- Kubernetes API operations
- External service integrations

### 🚀 End-to-End Tests

Comprehensive testing of the complete deployment pipeline:

```bash
# Deploy to test environment
kubectl create namespace argocd-orchestrator-test
kubectl apply -f k8s/statefulset.yaml -n argocd-orchestrator-test

# Run E2E test suite
./scripts/e2e-tests.sh

# Run specific E2E scenarios
./scripts/e2e-tests.sh --scenario=55-microservices-deployment
./scripts/e2e-tests.sh --scenario=sync-wave-orchestration
./scripts/e2e-tests.sh --scenario=rollback-scenarios
```

**E2E Test Scenarios:**
- Complete 55 microservices deployment
- Sync wave orchestration
- Dependency resolution
- Health check workflows
- Rollback procedures
- Argo Events integration
- Multi-tenant deployments

### 📊 Performance Tests

Load testing for high-scale deployments:

```bash
# Run performance tests
./scripts/performance-tests.sh

# Run specific performance scenarios
./scripts/performance-tests.sh --scenario=55-services-deployment
./scripts/performance-tests.sh --scenario=concurrent-deployments
./scripts/performance-tests.sh --scenario=high-frequency-updates

# Run with custom parameters
./scripts/performance-tests.sh --services=100 --concurrent=10 --duration=30m
```

**Performance Test Metrics:**
- Deployment time for 55+ microservices
- Sync wave execution time
- Dependency resolution performance
- API response times
- Resource utilization
- Memory and CPU usage

### 🎯 Chaos Engineering

Resilience testing for production scenarios:

```bash
# Run chaos engineering tests
./scripts/chaos-tests.sh

# Run specific chaos scenarios
./scripts/chaos-tests.sh --scenario=network-partition
./scripts/chaos-tests.sh --scenario=pod-failures
./scripts/chaos-tests.sh --scenario=database-outage
./scripts/chaos-tests.sh --scenario=argo-events-failure

# Run with custom parameters
./scripts/chaos-tests.sh --duration=60m --failure-rate=0.1
```

**Chaos Test Scenarios:**
- Network partitions and latency
- Pod and node failures
- Database connectivity issues
- Argo Events service failures
- Resource exhaustion
- Configuration corruption

### 🔍 Dependency Testing

Test complex dependency scenarios:

```bash
# Test dependency resolution
./scripts/test-dependencies.sh

# Test circular dependency detection
./scripts/test-dependencies.sh --scenario=circular-deps

# Test dependency validation
./scripts/test-dependencies.sh --scenario=validation

# Test topological sorting
./scripts/test-dependencies.sh --scenario=topological-sort
```

**Dependency Test Cases:**
- Circular dependency detection
- Complex dependency graphs
- Dependency validation
- Topological sorting accuracy
- Sync wave ordering
- Health check dependencies

### 🎭 Sync Wave Testing

Test sync wave orchestration:

```bash
# Test sync wave execution
./scripts/test-sync-waves.sh

# Test specific sync wave scenarios
./scripts/test-sync-waves.sh --scenario=wave-0-infrastructure
./scripts/test-sync-waves.sh --scenario=wave-1-databases
./scripts/test-sync-waves.sh --scenario=wave-2-core-apis
./scripts/test-sync-waves.sh --scenario=wave-3-business-services

# Test sync wave failures and recovery
./scripts/test-sync-waves.sh --scenario=failure-recovery
./scripts/test-sync-waves.sh --scenario=timeout-handling
./scripts/test-sync-waves.sh --scenario=retry-mechanisms
```

**Sync Wave Test Scenarios:**
- Wave execution order
- Health check integration
- Failure handling and recovery
- Timeout management
- Retry mechanisms
- Progress tracking

### 🔧 Argo Events Testing

Test event-driven architecture:

```bash
# Test Argo Events integration
./scripts/test-argo-events.sh

# Test specific event scenarios
./scripts/test-argo-events.sh --scenario=github-webhook
./scripts/test-argo-events.sh --scenario=deployment-trigger
./scripts/test-argo-events.sh --scenario=health-check-event
./scripts/test-argo-events.sh --scenario=rollback-trigger

# Test event processing
./scripts/test-argo-events.sh --scenario=event-processing
./scripts/test-argo-events.sh --scenario=rate-limiting
./scripts/test-argo-events.sh --scenario=retry-strategies
```

**Argo Events Test Cases:**
- GitHub webhook processing
- Event filtering and routing
- Trigger execution
- Rate limiting
- Retry strategies
- Event persistence

### 🏥 Health Check Testing

Test health monitoring systems:

```bash
# Test health check functionality
./scripts/test-health-checks.sh

# Test specific health scenarios
./scripts/test-health-checks.sh --scenario=service-health
./scripts/test-health-checks.sh --scenario=dependency-health
./scripts/test-health-checks.sh --scenario=circuit-breaker
./scripts/test-health-checks.sh --scenario=auto-recovery

# Test health check integration
./scripts/test-health-checks.sh --scenario=integration
./scripts/test-health-checks.sh --scenario=alerting
./scripts/test-health-checks.sh --scenario=metrics
```

**Health Check Test Scenarios:**
- Individual service health
- Dependency health validation
- Circuit breaker patterns
- Auto-recovery mechanisms
- Health check integration
- Alerting and notifications

### 🎪 Multi-Tenant Testing

Test multi-tenant isolation and management:

```bash
# Test multi-tenant scenarios
./scripts/test-multi-tenant.sh

# Test specific tenant scenarios
./scripts/test-multi-tenant.sh --scenario=tenant-isolation
./scripts/test-multi-tenant.sh --scenario=resource-quotas
./scripts/test-multi-tenant.sh --scenario=namespace-separation
./scripts/test-multi-tenant.sh --scenario=tenant-management

# Test tenant operations
./scripts/test-multi-tenant.sh --scenario=tenant-creation
./scripts/test-multi-tenant.sh --scenario=tenant-deletion
./scripts/test-multi-tenant.sh --scenario=tenant-migration
```

**Multi-Tenant Test Cases:**
- Tenant isolation
- Resource quotas and limits
- Namespace separation
- Tenant management operations
- Cross-tenant security
- Tenant-specific configurations

### 📈 Load Testing

Test system performance under load:

```bash
# Run load tests
./scripts/load-tests.sh

# Test specific load scenarios
./scripts/load-tests.sh --scenario=high-concurrency
./scripts/load-tests.sh --scenario=large-deployments
./scripts/load-tests.sh --scenario=rapid-updates
./scripts/load-tests.sh --scenario=resource-intensive

# Run with custom parameters
./scripts/load-tests.sh --users=100 --duration=30m --ramp-up=5m
```

**Load Test Scenarios:**
- High concurrent deployments
- Large microservice deployments
- Rapid configuration updates
- Resource-intensive operations
- API endpoint performance
- Database load handling

### 🔒 Security Testing

Test security aspects of the orchestrator:

```bash
# Run security tests
./scripts/security-tests.sh

# Test specific security scenarios
./scripts/security-tests.sh --scenario=authentication
./scripts/security-tests.sh --scenario=authorization
./scripts/security-tests.sh --scenario=webhook-validation
./scripts/security-tests.sh --scenario=secrets-management

# Run security scans
./scripts/security-tests.sh --scan=dependency-vulnerabilities
./scripts/security-tests.sh --scan=container-vulnerabilities
./scripts/security-tests.sh --scan=code-security
```

**Security Test Areas:**
- Authentication mechanisms
- Authorization and RBAC
- Webhook signature validation
- Secrets management
- Network security
- Container security

### 🧹 Test Data Management

Manage test data and environments:

```bash
# Setup test environment
./scripts/setup-test-env.sh

# Clean test data
./scripts/clean-test-data.sh

# Generate test data
./scripts/generate-test-data.sh --microservices=55 --customers=10

# Reset test environment
./scripts/reset-test-env.sh
```

### 📊 Test Reporting

Generate comprehensive test reports:

```bash
# Generate test reports
./scripts/generate-test-reports.sh

# View test coverage
./scripts/view-coverage.sh

# Export test results
./scripts/export-test-results.sh --format=html
./scripts/export-test-results.sh --format=json
./scripts/export-test-results.sh --format=junit
```

### 🚀 Continuous Testing

Integrate testing into CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: Comprehensive Testing
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '17'
      - name: Run Unit Tests
        run: mvn test
      - name: Run Integration Tests
        run: mvn test -Dtest=*IntegrationTest
      - name: Run E2E Tests
        run: ./scripts/e2e-tests.sh
      - name: Generate Test Report
        run: ./scripts/generate-test-reports.sh
```

### 📋 Test Checklist

Before deploying to production, ensure all tests pass:

- [ ] Unit tests: `mvn test`
- [ ] Integration tests: `mvn test -Dtest=*IntegrationTest`
- [ ] E2E tests: `./scripts/e2e-tests.sh`
- [ ] Performance tests: `./scripts/performance-tests.sh`
- [ ] Chaos engineering: `./scripts/chaos-tests.sh`
- [ ] Security tests: `./scripts/security-tests.sh`
- [ ] Dependency tests: `./scripts/test-dependencies.sh`
- [ ] Sync wave tests: `./scripts/test-sync-waves.sh`
- [ ] Argo Events tests: `./scripts/test-argo-events.sh`
- [ ] Health check tests: `./scripts/test-health-checks.sh`
- [ ] Multi-tenant tests: `./scripts/test-multi-tenant.sh`
- [ ] Load tests: `./scripts/load-tests.sh`

### 🎯 Test Best Practices

1. **Test Isolation**: Each test should be independent and not rely on other tests
2. **Test Data Management**: Use dedicated test data and clean up after tests
3. **Parallel Execution**: Run tests in parallel where possible for faster feedback
4. **Test Coverage**: Aim for >80% code coverage across all components
5. **Performance Baselines**: Establish performance baselines and monitor for regressions
6. **Security Scanning**: Regularly scan for vulnerabilities in dependencies
7. **Chaos Testing**: Regularly test system resilience under failure conditions
8. **Documentation**: Document test scenarios and expected outcomes
9. **Monitoring**: Monitor test execution and report failures promptly
10. **Continuous Improvement**: Regularly review and improve test strategies

## 🚨 Enhanced Troubleshooting

### Common Issues

1. **Sync wave stuck**
   ```bash
   kubectl get syncwaves -n argocd-orchestrator
   kubectl describe syncwave wave-2 -n argocd-orchestrator
   ```

2. **Dependency resolution failure**
   ```bash
   kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator | grep "Dependency"
   ```

3. **Health check failures**
   ```bash
   curl http://localhost:8080/api/v1/health/services
   ```

4. **Circular dependency detected**
   ```bash
   curl http://localhost:8080/api/v1/dependencies/circular
   ```

### Debug Mode

Enable comprehensive debug logging:

```yaml
logging:
  level:
    com.rtte.argocd.orchestrator: DEBUG
    org.springframework.web: DEBUG
    com.rtte.argocd.orchestrator.dependency: DEBUG
    com.rtte.argocd.orchestrator.syncwave: DEBUG
```

### Diagnostic Tools

- **Dependency Graph Visualization**: Web UI for dependency graphs
- **Sync Wave Timeline**: Visual timeline of sync wave execution
- **Health Dashboard**: Real-time health status dashboard
- **Rollback Analysis**: Detailed rollback analysis and recommendations

## 📚 Enhanced Documentation

- [API Documentation](docs/api.md)
- [Configuration Guide](docs/configuration.md)
- [Deployment Guide](docs/deployment.md)
- [Microservice Management](docs/microservices.md)
- [Sync Wave Guide](docs/sync-waves.md)
- [Dependency Management](docs/dependencies.md)
- [Argo Events Integration](docs/argo-events.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Performance Tuning](docs/performance.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add comprehensive tests
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- **Email**: rohit.tambakhe@live.com

---

**Built with ❤️ by the rtte team**

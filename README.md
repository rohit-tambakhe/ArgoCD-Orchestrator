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
│                    Argo Events (EventBus)                      │
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
│  │ CAC Manager     │  │ Dependency      │  │ GitHub Integration│  │
│  │                 │  │ Engine          │  │                 │  │
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
│   ├── cac-configs/
│   ├── microservices/                   # 55 microservice definitions
│   │   ├── user-service/
│   │   ├── auth-service/
│   │   ├── payment-service/
│   │   └── ... (52 more services)
│   └── dependency-graphs/               # Dependency graph examples
│       ├── customer-a-dependencies.yaml
│       └── customer-b-dependencies.yaml
├── scripts/                             # Utility scripts
│   ├── deploy.sh
│   ├── health-check.sh
│   └── rollback.sh
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

# CAC Configuration
cac:
  repository-url: https://github.com/rtte/cac-configs
  branch: main
  config-path: customers
  validation:
    enabled: true
    schema-path: schemas/customer-config.yaml

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

### Enhanced Customer Configuration (CAC)

Customer configurations now include microservice dependencies and sync waves:

```yaml
# customers/customer-a/config.yaml
customer: customer-a
environment: production
sync-waves:
  - wave: 0
    name: infrastructure
    services: [ingress, cert-manager, external-secrets]
  - wave: 1
    name: databases
    services: [postgres, redis, mongodb, elasticsearch]
  - wave: 2
    name: core-apis
    services: [user-service, auth-service, config-service]
  - wave: 3
    name: business-services
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

### Adding a New Customer with 55 Microservices

1. **Create customer configuration**
   ```bash
   mkdir -p cac-configs/customers/new-customer
   ```

2. **Generate microservice definitions**
   ```bash
   ./scripts/generate-microservices.sh new-customer
   ```

3. **Add config.yaml with dependencies**
   ```yaml
   customer: new-customer
   environment: production
   sync-waves:
     - wave: 0
       name: infrastructure
       services: [ingress, cert-manager, external-secrets]
     # ... define all 55 microservices with proper sync waves
   ```

4. **Validate dependencies**
   ```bash
   curl -X POST http://localhost:8080/api/v1/dependencies/validate \
     -H "Content-Type: application/json" \
     -d @cac-configs/customers/new-customer/config.yaml
   ```

5. **Commit and push**
   ```bash
   git add cac-configs/customers/new-customer/
   git commit -m "Add new-customer with 55 microservices"
   git push origin main
   ```

6. **Monitor deployment**
   ```bash
   kubectl get applications -n argocd | grep new-customer
   kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator -f
   ```

### Updating Microservice Dependencies

1. **Update dependency configuration**
   ```bash
   vim cac-configs/customers/customer-a/config.yaml
   ```

2. **Validate dependency changes**
   ```bash
   curl -X POST http://localhost:8080/api/v1/dependencies/validate \
     -H "Content-Type: application/json" \
     -d @cac-configs/customers/customer-a/config.yaml
   ```

3. **Commit changes**
   ```bash
   git commit -m "Update customer-a: add new dependency for payment-service"
   git push origin main
   ```

4. **Monitor sync wave execution**
   ```bash
   kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator -f
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

- **Email**: dev@rtte.com
- **Issues**: [GitHub Issues](https://github.com/rtte/argocd-orchestrator/issues)
- **Documentation**: [Project Wiki](https://github.com/rtte/argocd-orchestrator/wiki)
- **Slack**: [rtte-dev](https://rtte.slack.com/archives/argocd-orchestrator)

---

**Built with ❤️ by the rtte team**

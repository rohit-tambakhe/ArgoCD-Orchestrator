<<<<<<< HEAD
# ArgoCD Orchestrator for rtte

A comprehensive ArgoCD orchestrator with Config as Code (CAC) integration for managing multi-tenant deployments on AWS EKS.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Git Repositories                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │   Helm Charts   │  │  CAC Configs    │  │ Application Code││
│  │   (uqh-chart)   │  │  (customers/)   │  │   (microservices)││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└───────────────────────────┬─────────────────────────────────────┘
                            │ Webhooks
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              ArgoCD Orchestrator (Java + Spring Boot)            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │ CAC Manager     │  │ Decision Engine │  │ GitHub Integration││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │ ApplicationSet  │  │ Helm Processor  │  │ State Manager    ││
│  │   Generator     │  │                 │  │  (StatefulSet)   ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS EKS Cluster                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  Customer A NS  │  │  Customer B NS  │  │ Customer C NS    ││
│  │  (uqh, mongo)   │  │  (uqh, redis)   │  │  (uqh, kafka)   ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## ✨ Key Features

- **Config as Code (CAC)**: Customer configurations stored in Git repositories
- **Multi-tenant Support**: Isolated customer environments with namespace separation
- **StatefulSet Deployment**: Leader election and state persistence
- **Dynamic ApplicationSet Generation**: Automatic ArgoCD ApplicationSet creation
- **GitHub Integration**: Webhook-based deployment triggers
- **Helm Chart Support**: Integration with existing Helm charts (uqh-chart)
- **Monitoring & Observability**: Prometheus metrics and health checks
- **Security**: RBAC, webhook signature validation, and secure secrets management

## 🚀 Quick Start

### Prerequisites

- Java 17+
- Maven 3.8+
- Docker
- Kubernetes cluster (AWS EKS recommended)
- ArgoCD installed
- PostgreSQL database
- Redis instance

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

1. **Create namespace**
   ```bash
   kubectl create namespace argocd-orchestrator
   ```

2. **Create secrets**
   ```bash
   kubectl create secret generic orchestrator-secrets \
     --from-literal=db-username=postgres \
     --from-literal=db-password=$DB_PASSWORD \
     --from-literal=github-token=$GITHUB_TOKEN \
     --from-literal=argocd-password=$ARGOCD_PASSWORD \
     --from-literal=github-webhook-secret=$WEBHOOK_SECRET \
     -n argocd-orchestrator

   kubectl create secret generic git-ssh-key \
     --from-file=ssh-privatekey=/path/to/ssh-key \
     -n argocd-orchestrator
   ```

3. **Deploy the orchestrator**
   ```bash
   kubectl apply -f k8s/statefulset.yaml
   ```

4. **Verify deployment**
   ```bash
   kubectl get pods -n argocd-orchestrator
   kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator
   ```

## 📁 Project Structure

```
argocd-orchestrator/
├── src/main/java/com/rtte/argocd/orchestrator/
│   ├── config/                          # Configuration classes
│   │   ├── ArgoCDProperties.java
│   │   ├── CACProperties.java
│   │   ├── GitHubProperties.java
│   │   └── KubernetesConfig.java
│   ├── controller/                      # REST controllers
│   │   └── EnhancedWebhookController.java
│   ├── service/                         # Business logic services
│   │   ├── CACManagerService.java
│   │   ├── ApplicationSetService.java
│   │   ├── StateManager.java
│   │   └── CACWebhookProcessor.java
│   ├── model/                           # Domain models and DTOs
│   │   ├── domain/
│   │   │   ├── Deployment.java
│   │   │   ├── CustomerConfig.java
│   │   │   └── ApplicationSetSpec.java
│   │   └── dto/
│   │       ├── DeploymentRequest.java
│   │       ├── DeploymentResponse.java
│   │       └── HelmValuesDTO.java
│   ├── repository/                      # Data access layer
│   ├── integration/                     # External integrations
│   └── engine/                          # Business logic engines
├── src/main/resources/
│   ├── application.yml                  # Main configuration
│   └── db/migration/                    # Database migrations
├── k8s/                                 # Kubernetes manifests
│   └── statefulset.yaml
├── examples/                            # Example configurations
│   └── cac-configs/
└── pom.xml
```

## 🔧 Configuration

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

# StatefulSet Configuration
orchestrator:
  leader-election:
    enabled: true
    lease-duration: 15s
  sync:
    interval: 300000 # 5 minutes
```

### Customer Configuration (CAC)

Customer configurations are stored in Git repositories:

```yaml
# customers/customer-a/config.yaml
customer: customer-a
environment: production
applications:
  - name: uqh
    enabled: true
    version: "1.2.0"
    imageRepository: "920349478710.dkr.ecr.us-west-2.amazonaws.com/queryhandler"
    deploymentStrategy: BLUE_GREEN
    replicas: 3
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "2000m"
        memory: "2048Mi"
    configMaps:
      ushurConf: customer-a-ushur-conf
    volumeClaims:
      logs: pvc-customer-a-logs
      data: pvc-customer-a-data
```

## 🔌 API Endpoints

### Webhooks

- `POST /api/v1/webhooks/cac` - CAC configuration webhooks
- `POST /api/v1/webhooks/github` - GitHub application webhooks
- `GET /api/v1/webhooks/health` - Webhook health check

### Management

- `GET /actuator/health` - Application health
- `GET /actuator/metrics` - Prometheus metrics
- `GET /swagger-ui.html` - API documentation

## 🔄 Workflow

### Adding a New Customer

1. **Create customer configuration**
   ```bash
   mkdir -p cac-configs/customers/new-customer/uqh
   ```

2. **Add config.yaml**
   ```yaml
   customer: new-customer
   environment: production
   applications:
     - name: uqh
       enabled: true
       version: "1.0.0"
       # ... configuration
   ```

3. **Commit and push**
   ```bash
   git add cac-configs/customers/new-customer/
   git commit -m "Add new-customer configuration"
   git push origin main
   ```

4. **Verify deployment**
   ```bash
   kubectl get applications -n argocd | grep new-customer
   ```

### Updating Customer Configuration

1. **Update configuration**
   ```bash
   vim cac-configs/customers/customer-a/config.yaml
   ```

2. **Commit changes**
   ```bash
   git commit -m "Update customer-a: increase uqh replicas to 5"
   git push origin main
   ```

3. **Monitor deployment**
   ```bash
   kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator -f
   ```

## 📊 Monitoring

### Metrics

The application exposes Prometheus metrics:

- `argocd_orchestrator_deployments_total` - Total deployments
- `argocd_orchestrator_deployments_active` - Active deployments
- `argocd_orchestrator_cac_sync_duration_seconds` - CAC sync duration
- `argocd_orchestrator_leader_election_status` - Leader election status

### Health Checks

- **Liveness**: `/actuator/health/liveness`
- **Readiness**: `/actuator/health/readiness`
- **Startup**: `/actuator/health/startup`

### Logging

Logs are available at:
- Console: Standard output
- File: `/app/logs/argocd-orchestrator.log`
- Kubernetes: `kubectl logs -n argocd-orchestrator`

## 🔒 Security

### Authentication & Authorization

- **Webhook Security**: GitHub signature validation
- **RBAC**: Kubernetes role-based access control
- **Secrets Management**: Kubernetes secrets for sensitive data

### Network Security

- **Pod Security**: Non-root containers
- **Network Policies**: Isolated customer namespaces
- **TLS**: Encrypted communication

## 🧪 Testing

### Unit Tests

```bash
mvn test
```

### Integration Tests

```bash
mvn test -Dtest=*IntegrationTest
```

### End-to-End Tests

```bash
# Deploy to test environment
kubectl apply -f k8s/statefulset.yaml -n argocd-orchestrator-test

# Run tests
./scripts/e2e-tests.sh
```

## 🚨 Troubleshooting

### Common Issues

1. **Leader election not working**
   ```bash
   kubectl get leases -n argocd-orchestrator
   kubectl describe lease orchestrator-leader -n argocd-orchestrator
   ```

2. **CAC configuration not loading**
   ```bash
   kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator | grep CAC
   ```

3. **ApplicationSet not created**
   ```bash
   kubectl get applicationsets -n argocd
   kubectl describe applicationset customer-a-apps -n argocd
   ```

### Debug Mode

Enable debug logging:

```yaml
logging:
  level:
    com.rtte.argocd.orchestrator: DEBUG
    org.springframework.web: DEBUG
```

## 📚 Documentation

- [API Documentation](docs/api.md)
- [Configuration Guide](docs/configuration.md)
- [Deployment Guide](docs/deployment.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- **Email**: dev@rtte.com
- **Issues**: [GitHub Issues](https://github.com/rtte/argocd-orchestrator/issues)
- **Documentation**: [Project Wiki](https://github.com/rtte/argocd-orchestrator/wiki)

---

**Built with ❤️ by the rtte team** 
=======
# ArgoCD-Orchestrator
>>>>>>> 3c50022d59846bba63b2465b40b8599dfaf3b454

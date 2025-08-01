# Local Testing Guide for ArgoCD Orchestrator

This guide will help you set up and test the complete ArgoCD Orchestrator solution in a local environment to validate the design and functionality.

## Prerequisites

### 1. Local Kubernetes Cluster Setup

```bash
# Install Docker Desktop (if not already installed)
# Download from: https://www.docker.com/products/docker-desktop

# Install kubectl
# Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl/

# Install Helm
# Download from: https://helm.sh/docs/intro/install/

# Install kind (Kubernetes in Docker)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create a local Kubernetes cluster
kind create cluster --name argocd-orchestrator --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
  - containerPort: 30002
    hostPort: 30002
    protocol: TCP
- role: worker
- role: worker
EOF

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### 2. Install Required Tools

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Install Argo Workflows CLI
curl -sLO https://github.com/argoproj/argo-workflows/releases/download/v3.4.8/argo-linux-amd64.gz
gunzip argo-linux-amd64.gz
chmod +x argo-linux-amd64
sudo mv ./argo-linux-amd64 /usr/local/bin/argo

# Install Argo Rollouts CLI
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Install Argo Events CLI
curl -sLO https://github.com/argoproj/argo-events/releases/latest/download/argo-events-linux-amd64
chmod +x argo-events-linux-amd64
sudo mv argo-events-linux-amd64 /usr/local/bin/argo-events
```

### 3. Install Argo Components

```bash
# Create namespace for Argo components
kubectl create namespace argocd
kubectl create namespace argo-events
kubectl create namespace argo-workflows
kubectl create namespace argo-rollouts

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install Argo Events
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install-validating-webhook.yaml

# Install Argo Workflows
kubectl apply -n argo-workflows -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.8/install.yaml

# Install Argo Rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argo-events-controller -n argo-events --timeout=300s
kubectl wait --for=condition=condition=ready pod -l app.kubernetes.io/name=argo-workflows-workflow-controller -n argo-workflows --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argo-rollouts -n argo-rollouts --timeout=300s
```

### 4. Install Supporting Infrastructure

```bash
# Install PostgreSQL (for orchestrator database)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres bitnami/postgresql \
  --namespace default \
  --set auth.postgresPassword=orchestrator123 \
  --set auth.database=argocd_orchestrator \
  --set primary.persistence.size=1Gi

# Install Redis (for caching)
helm install redis bitnami/redis \
  --namespace default \
  --set auth.password=orchestrator123 \
  --set master.persistence.size=1Gi

# Install Prometheus and Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.enabled=true \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=1Gi

# Wait for infrastructure to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n default --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n default --timeout=300s
```

## Step 1: Build and Deploy the ArgoCD Orchestrator

### 1.1 Build the Application

```bash
# Navigate to the project directory
cd "Argo Orchestrator"

# Build the Spring Boot application
./mvnw clean package -DskipTests

# Build Docker image
docker build -t argocd-orchestrator:latest .

# Load image into kind cluster
kind load docker-image argocd-orchestrator:latest --name argocd-orchestrator
```

### 1.2 Deploy the Orchestrator

```bash
# Create namespace for the orchestrator
kubectl create namespace argocd-orchestrator

# Apply the StatefulSet deployment
kubectl apply -f k8s/statefulset.yaml

# Wait for the orchestrator to be ready
kubectl wait --for=condition=ready pod -l app=argocd-orchestrator -n argocd-orchestrator --timeout=300s

# Port forward to access the orchestrator
kubectl port-forward -n argocd-orchestrator svc/argocd-orchestrator 8080:8080 &
```

### 1.3 Verify Orchestrator Deployment

```bash
# Check orchestrator logs
kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator -f

# Test health endpoint
curl http://localhost:8080/actuator/health

# Test API documentation
curl http://localhost:8080/swagger-ui.html
```

## Step 2: Set Up Argo Events Infrastructure

### 2.1 Deploy EventBus

```bash
# Apply EventBus
kubectl apply -f k8s/argo-events/eventbus.yaml

# Wait for EventBus to be ready
kubectl wait --for=condition=ready pod -l app=eventbus-controller -n argo-events --timeout=300s
```

### 2.2 Deploy EventSource

```bash
# Apply EventSource
kubectl apply -f k8s/argo-events/eventsource.yaml

# Wait for EventSource to be ready
kubectl wait --for=condition=ready pod -l app=eventsource-controller -n argo-events --timeout=300s
```

### 2.3 Deploy Sensor

```bash
# Apply Sensor
kubectl apply -f k8s/argo-events/sensor.yaml

# Wait for Sensor to be ready
kubectl wait --for=condition=ready pod -l app=sensor-controller -n argo-events --timeout=300s
```

## Step 3: Set Up Helm Charts and ApplicationSet

### 3.1 Create Git Repository Structure

```bash
# Create a local Git repository for testing
mkdir -p test-git-repo
cd test-git-repo

# Initialize Git repository
git init

# Create the Helm chart structure
mkdir -p helm-charts/customers
mkdir -p helm-charts/base
mkdir -p cac-configs/customers/customer-a

# Copy Helm charts from the project
cp -r ../examples/helm-charts/* helm-charts/
cp -r ../examples/cac-configs/* cac-configs/

# Create initial commit
git add .
git commit -m "Initial commit with Helm charts and CAC configs"

# Create a bare repository for ArgoCD
cd ..
git clone --bare test-git-repo test-git-repo-bare
```

### 3.2 Deploy ApplicationSet

```bash
# Create ApplicationSet for customer-a
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: customer-a-applicationset
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: http://test-git-repo-bare
      revision: HEAD
      directories:
      - path: helm-charts/customers
  template:
    metadata:
      name: '{{name}}-customer-a'
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: http://test-git-repo-bare
        targetRevision: HEAD
        path: '{{path}}'
        helm:
          values: |
            global:
              customerId: customer-a
              namespace: customer-a
              imageTag: v1.0.0
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{metadata.name}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
EOF
```

## Step 4: Deploy Argo Workflows and Rollouts

### 4.1 Deploy Analysis Templates

```bash
# Apply AnalysisTemplates
kubectl apply -f k8s/argo-rollouts/analysis-template.yaml
```

### 4.2 Deploy Workflow

```bash
# Apply the deployment workflow
kubectl apply -f k8s/argo-workflows/deployment-workflow.yaml
```

## Step 5: Test the Complete Workflow

### 5.1 Simulate CI/CD Pipeline

```bash
# Simulate a new build by updating the Git repository
cd test-git-repo

# Update image tag in values.yaml
sed -i 's/imageTag: v1.0.0/imageTag: v1.0.1/' helm-charts/customers/values.yaml

# Update a ConfigMap
sed -i 's/database_url: "postgresql:\/\/localhost:5432\/customer_a"/database_url: "postgresql:\/\/localhost:5432\/customer_a_v2"/' helm-charts/customers/values.yaml

# Commit and push changes
git add .
git commit -m "Update image tag to v1.0.1 and database URL"
git push origin main

# Update the bare repository
cd ../test-git-repo-bare
git fetch
git update-server-info
```

### 5.2 Trigger Argo Events

```bash
# Simulate a GitHub webhook event
curl -X POST http://localhost:30000/webhook/github \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -H "X-Hub-Signature-256: sha256=$(echo -n '{"ref":"refs/heads/main","repository":{"full_name":"test/customer-a"}}' | openssl dgst -sha256 -hmac "webhook-secret" | cut -d' ' -f2)" \
  -d '{
    "ref": "refs/heads/main",
    "repository": {
      "full_name": "test/customer-a"
    },
    "commits": [
      {
        "id": "abc123",
        "message": "Update image tag to v1.0.1"
      }
    ]
  }'
```

### 5.3 Monitor the Deployment Process

```bash
# Watch ArgoCD applications
kubectl get applications -n argocd -w

# Watch Argo Workflows
kubectl get workflows -n argo-workflows -w

# Watch Argo Rollouts
kubectl get rollouts -n customer-a -w

# Watch pods in customer namespace
kubectl get pods -n customer-a -w

# Check orchestrator logs
kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator -f
```

### 5.4 Verify Sync Waves and Dependencies

```bash
# Check sync wave annotations
kubectl get deployments -n customer-a -o yaml | grep -A 5 -B 5 "argocd.argoproj.io/sync-wave"

# Check dependency annotations
kubectl get deployments -n customer-a -o yaml | grep -A 5 -B 5 "argocd.argoproj.io/sync-options"

# Verify dependency graph
curl http://localhost:8080/api/v1/dependencies/graph/customer-a
```

### 5.5 Test Health Checks and Rollbacks

```bash
# Simulate a failed deployment by updating to a non-existent image
cd test-git-repo
sed -i 's/imageTag: v1.0.1/imageTag: v1.0.2-invalid/' helm-charts/customers/values.yaml
git add .
git commit -m "Test rollback with invalid image"
git push origin main

# Watch for rollback
kubectl get rollouts -n customer-a -w

# Check rollback history
kubectl argo rollouts history customer-a-user-service -n customer-a
```

## Step 6: Performance and Load Testing

### 6.1 Test Multiple Customer Deployments

```bash
# Create customer-b configuration
mkdir -p test-git-repo/cac-configs/customers/customer-b
cp test-git-repo/cac-configs/customers/customer-a/config.yaml test-git-repo/cac-configs/customers/customer-b/config.yaml

# Update customer-b config
sed -i 's/customer-a/customer-b/g' test-git-repo/cac-configs/customers/customer-b/config.yaml

# Commit and push
cd test-git-repo
git add .
git commit -m "Add customer-b configuration"
git push origin main

# Watch multiple customer deployments
kubectl get applications -n argocd -w
```

### 6.2 Test Concurrent Deployments

```bash
# Simulate concurrent deployments for multiple customers
for customer in customer-a customer-b customer-c; do
  (
    cd test-git-repo
    sed -i "s/imageTag: v1.0.1/imageTag: v1.0.1-${customer}/" helm-charts/customers/values.yaml
    git add .
    git commit -m "Update ${customer} to v1.0.1-${customer}"
    git push origin main
  ) &
done
wait

# Monitor concurrent deployments
kubectl get workflows -n argo-workflows -w
```

## Step 7: Monitoring and Observability

### 7.1 Access Monitoring Dashboards

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# Access Grafana (admin/prom-operator)
# Open http://localhost:3000 in browser
```

### 7.2 Check Metrics and Logs

```bash
# Check orchestrator metrics
curl http://localhost:8080/actuator/metrics

# Check Prometheus metrics
curl http://localhost:9090/api/v1/query?query=argocd_orchestrator_deployments_total

# Check application logs
kubectl logs -n customer-a -l app=user-service -f
kubectl logs -n customer-a -l app=order-service -f
```

## Step 8: Cleanup

```bash
# Stop port forwards
pkill -f "kubectl port-forward"

# Delete the kind cluster
kind delete cluster --name argocd-orchestrator

# Clean up local files
rm -rf test-git-repo test-git-repo-bare
```

## Expected Test Results

### ✅ Success Criteria

1. **Orchestrator Deployment**: Spring Boot application starts successfully with all services initialized
2. **Database Connectivity**: PostgreSQL connection established, tables created via Flyway
3. **Redis Connectivity**: Caching layer operational
4. **ArgoCD Integration**: ApplicationSet generates applications correctly
5. **Argo Events**: Webhook events trigger sensor actions
6. **Argo Workflows**: Deployment workflow executes successfully
7. **Argo Rollouts**: Progressive deployment strategies work
8. **Sync Waves**: Services deploy in correct order based on dependencies
9. **Health Checks**: Automated health monitoring and rollback on failures
10. **Multi-tenancy**: Multiple customers deploy in isolated namespaces
11. **Monitoring**: Metrics and logs available in Prometheus/Grafana

### 🔍 Validation Points

- **Dependency Resolution**: Circular dependency detection works
- **Sync Wave Ordering**: Services deploy in correct sequence
- **Rollback Mechanism**: Failed deployments automatically rollback
- **Concurrent Deployments**: Multiple customers can deploy simultaneously
- **Resource Management**: CPU/memory limits enforced
- **Security**: RBAC and network policies applied
- **Observability**: Complete trace from Git push to deployment

### 📊 Performance Metrics

- **Deployment Time**: < 5 minutes for 55 microservices
- **Sync Wave Duration**: < 30 seconds per wave
- **Rollback Time**: < 2 minutes
- **Concurrent Deployments**: Support for 10+ customers simultaneously
- **Resource Usage**: < 2GB RAM, < 1 CPU for orchestrator

## Troubleshooting

### Common Issues

1. **Kind Cluster Issues**:
   ```bash
   # Reset cluster
   kind delete cluster --name argocd-orchestrator
   kind create cluster --name argocd-orchestrator
   ```

2. **Image Pull Issues**:
   ```bash
   # Ensure images are loaded into kind
   kind load docker-image argocd-orchestrator:latest --name argocd-orchestrator
   ```

3. **Port Forward Issues**:
   ```bash
   # Check if ports are in use
   netstat -tulpn | grep :8080
   # Kill existing port forwards
   pkill -f "kubectl port-forward"
   ```

4. **Database Connection Issues**:
   ```bash
   # Check PostgreSQL status
   kubectl get pods -l app.kubernetes.io/name=postgresql
   # Check logs
   kubectl logs -l app.kubernetes.io/name=postgresql
   ```

### Debug Commands

```bash
# Check all resources
kubectl get all --all-namespaces

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check ArgoCD server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Check orchestrator logs
kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator

# Check workflow logs
kubectl logs -n argo-workflows -l app=argo-workflows-workflow-controller
```

This comprehensive testing guide will validate that your ArgoCD Orchestrator design is correct and fully functional in a local environment. The test covers all aspects of the system from initial deployment to complex multi-tenant scenarios with proper monitoring and observability. 
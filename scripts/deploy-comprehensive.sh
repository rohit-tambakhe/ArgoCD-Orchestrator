#!/bin/bash

# Comprehensive Deployment Script for ArgoCD Orchestrator
# Supports 55+ microservices with Argo Events and sync waves

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="argocd-orchestrator"
ARGO_EVENTS_NAMESPACE="argo-events"
CUSTOMER_ID="${1:-customer-a}"
ENVIRONMENT="${2:-production}"

echo -e "${BLUE}🚀 Starting Comprehensive ArgoCD Orchestrator Deployment${NC}"
echo -e "${BLUE}Customer: ${CUSTOMER_ID}${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
    
    if ! command_exists kubectl; then
        echo -e "${RED}❌ kubectl is not installed${NC}"
        exit 1
    fi
    
    if ! command_exists helm; then
        echo -e "${RED}❌ helm is not installed${NC}"
        exit 1
    fi
    
    if ! command_exists mvn; then
        echo -e "${RED}❌ Maven is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to create namespaces
create_namespaces() {
    echo -e "${YELLOW}🏗️ Creating namespaces...${NC}"
    
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace ${ARGO_EVENTS_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace ${CUSTOMER_ID} --dry-run=client -o yaml | kubectl apply -f -
    
    echo -e "${GREEN}✅ Namespaces created${NC}"
}

# Function to install Argo Events
install_argo_events() {
    echo -e "${YELLOW}📡 Installing Argo Events...${NC}"
    
    # Add Argo Events Helm repository
    helm repo add argo-events https://argoproj.github.io/argo-events
    helm repo update
    
    # Install Argo Events
    helm upgrade --install argo-events argo-events/argo-events \
        --namespace ${ARGO_EVENTS_NAMESPACE} \
        --create-namespace \
        --set controller.replicaCount=3 \
        --set controller.resources.requests.cpu=100m \
        --set controller.resources.requests.memory=128Mi \
        --set controller.resources.limits.cpu=500m \
        --set controller.resources.limits.memory=512Mi \
        --set eventBus.nats.native.replicas=3 \
        --set eventBus.nats.native.persistence.enabled=true \
        --set eventBus.nats.native.persistence.storageClassName=gp2 \
        --set eventBus.nats.native.persistence.size=10Gi
    
    echo -e "${GREEN}✅ Argo Events installed${NC}"
}

# Function to build and package the application
build_application() {
    echo -e "${YELLOW}🔨 Building application...${NC}"
    
    mvn clean package -DskipTests
    
    echo -e "${GREEN}✅ Application built successfully${NC}"
}

# Function to create secrets
create_secrets() {
    echo -e "${YELLOW}🔐 Creating secrets...${NC}"
    
    # Generate webhook secret
    WEBHOOK_SECRET=$(openssl rand -base64 32)
    
    # Create orchestrator secrets
    kubectl create secret generic orchestrator-secrets \
        --from-literal=db-username=postgres \
        --from-literal=db-password=${DB_PASSWORD:-password} \
        --from-literal=github-token=${GITHUB_TOKEN:-dummy-token} \
        --from-literal=argocd-password=${ARGOCD_PASSWORD:-admin123} \
        --from-literal=github-webhook-secret=${WEBHOOK_SECRET} \
        --from-literal=argo-events-webhook-secret=${WEBHOOK_SECRET} \
        --namespace ${NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create GitHub webhook secret for Argo Events
    kubectl create secret generic github-webhook-secret \
        --from-literal=secret=${WEBHOOK_SECRET} \
        --namespace ${ARGO_EVENTS_NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo -e "${GREEN}✅ Secrets created${NC}"
}

# Function to deploy Argo Events components
deploy_argo_events_components() {
    echo -e "${YELLOW}📡 Deploying Argo Events components...${NC}"
    
    # Apply EventBus
    kubectl apply -f k8s/argo-events/eventbus.yaml
    
    # Apply EventSource
    kubectl apply -f k8s/argo-events/eventsource.yaml
    
    # Apply Sensor
    kubectl apply -f k8s/argo-events/sensor.yaml
    
    echo -e "${GREEN}✅ Argo Events components deployed${NC}"
}

# Function to deploy the orchestrator
deploy_orchestrator() {
    echo -e "${YELLOW}🎯 Deploying ArgoCD Orchestrator...${NC}"
    
    # Apply StatefulSet
    kubectl apply -f k8s/statefulset.yaml
    
    # Wait for orchestrator to be ready
    echo -e "${YELLOW}⏳ Waiting for orchestrator to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=argocd-orchestrator -n ${NAMESPACE} --timeout=300s
    
    echo -e "${GREEN}✅ Orchestrator deployed successfully${NC}"
}

# Function to deploy customer microservices
deploy_customer_microservices() {
    echo -e "${YELLOW}🚀 Deploying customer microservices...${NC}"
    
    # Create customer configuration
    mkdir -p examples/cac-configs/customers/${CUSTOMER_ID}
    cp examples/microservices/55-microservices-config.yaml examples/cac-configs/customers/${CUSTOMER_ID}/config.yaml
    
    # Update customer ID in config
    sed -i "s/customer: customer-a/customer: ${CUSTOMER_ID}/g" examples/cac-configs/customers/${CUSTOMER_ID}/config.yaml
    
    # Trigger deployment via API
    echo -e "${YELLOW}📤 Triggering deployment via API...${NC}"
    
    # Wait for orchestrator to be ready
    kubectl wait --for=condition=ready pod -l app=argocd-orchestrator -n ${NAMESPACE} --timeout=300s
    
    # Get orchestrator service URL
    ORCHESTRATOR_URL=$(kubectl get svc -n ${NAMESPACE} -l app=argocd-orchestrator -o jsonpath='{.items[0].spec.clusterIP}')
    
    # Trigger deployment
    curl -X POST "http://${ORCHESTRATOR_URL}:8080/api/v1/deployments" \
        -H "Content-Type: application/json" \
        -d "{
            \"customerId\": \"${CUSTOMER_ID}\",
            \"environment\": \"${ENVIRONMENT}\",
            \"configPath\": \"examples/cac-configs/customers/${CUSTOMER_ID}/config.yaml\"
        }"
    
    echo -e "${GREEN}✅ Customer microservices deployment triggered${NC}"
}

# Function to verify deployment
verify_deployment() {
    echo -e "${YELLOW}🔍 Verifying deployment...${NC}"
    
    # Check orchestrator pods
    echo -e "${BLUE}Checking orchestrator pods...${NC}"
    kubectl get pods -n ${NAMESPACE}
    
    # Check Argo Events pods
    echo -e "${BLUE}Checking Argo Events pods...${NC}"
    kubectl get pods -n ${ARGO_EVENTS_NAMESPACE}
    
    # Check customer namespace
    echo -e "${BLUE}Checking customer namespace...${NC}"
    kubectl get pods -n ${CUSTOMER_ID}
    
    # Check ArgoCD applications
    echo -e "${BLUE}Checking ArgoCD applications...${NC}"
    kubectl get applications -n argocd | grep ${CUSTOMER_ID} || echo "No applications found yet"
    
    echo -e "${GREEN}✅ Deployment verification completed${NC}"
}

# Function to show deployment status
show_status() {
    echo -e "${BLUE}📊 Deployment Status:${NC}"
    echo ""
    
    echo -e "${YELLOW}Orchestrator Status:${NC}"
    kubectl get pods -n ${NAMESPACE} -o wide
    
    echo ""
    echo -e "${YELLOW}Argo Events Status:${NC}"
    kubectl get pods -n ${ARGO_EVENTS_NAMESPACE} -o wide
    
    echo ""
    echo -e "${YELLOW}Customer Services Status:${NC}"
    kubectl get pods -n ${CUSTOMER_ID} -o wide
    
    echo ""
    echo -e "${YELLOW}Sync Waves Status:${NC}"
    kubectl get syncwaves -n ${NAMESPACE} | grep ${CUSTOMER_ID} || echo "No sync waves found"
    
    echo ""
    echo -e "${YELLOW}Dependency Graph Status:${NC}"
    kubectl get dependencygraphs -n ${NAMESPACE} | grep ${CUSTOMER_ID} || echo "No dependency graphs found"
}

# Function to show useful commands
show_commands() {
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo ""
    echo -e "${YELLOW}View orchestrator logs:${NC}"
    echo "kubectl logs -n ${NAMESPACE} -l app=argocd-orchestrator -f"
    echo ""
    echo -e "${YELLOW}View Argo Events logs:${NC}"
    echo "kubectl logs -n ${ARGO_EVENTS_NAMESPACE} -l app=argo-events -f"
    echo ""
    echo -e "${YELLOW}Check sync wave status:${NC}"
    echo "kubectl get syncwaves -n ${NAMESPACE} -o yaml"
    echo ""
    echo -e "${YELLOW}Check dependency graph:${NC}"
    echo "kubectl get dependencygraphs -n ${NAMESPACE} -o yaml"
    echo ""
    echo -e "${YELLOW}Access orchestrator API:${NC}"
    echo "kubectl port-forward -n ${NAMESPACE} svc/argocd-orchestrator 8080:8080"
    echo ""
    echo -e "${YELLOW}View ArgoCD UI:${NC}"
    echo "kubectl port-forward -n argocd svc/argocd-server 8081:80"
}

# Main deployment flow
main() {
    echo -e "${BLUE}🎯 Starting comprehensive deployment...${NC}"
    echo ""
    
    check_prerequisites
    create_namespaces
    install_argo_events
    build_application
    create_secrets
    deploy_argo_events_components
    deploy_orchestrator
    deploy_customer_microservices
    
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    
    verify_deployment
    show_status
    show_commands
    
    echo ""
    echo -e "${GREEN}✅ Comprehensive ArgoCD Orchestrator deployment completed!${NC}"
    echo -e "${BLUE}📚 Check the README.md for detailed documentation${NC}"
}

# Run main function
main "$@" 
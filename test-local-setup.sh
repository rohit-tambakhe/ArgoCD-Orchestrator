#!/bin/bash

# Local Testing Setup Validation Script
# This script validates that all prerequisites are installed and the local environment is ready for testing

set -e

echo "🔍 ArgoCD Orchestrator - Local Testing Setup Validation"
echo "======================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    fi
}

# Function to check if port is available
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${YELLOW}⚠️  Port $1 is in use${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Port $1 is available${NC}"
        return 0
    fi
}

# Function to check if kind cluster exists
check_kind_cluster() {
    if kind get clusters | grep -q "argocd-orchestrator"; then
        echo -e "${GREEN}✅ Kind cluster 'argocd-orchestrator' exists${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Kind cluster 'argocd-orchestrator' does not exist${NC}"
        return 1
    fi
}

echo -e "\n${BLUE}1. Checking Prerequisites${NC}"
echo "------------------------"

# Check basic tools
echo -e "\n${BLUE}Basic Tools:${NC}"
check_command docker
check_command kubectl
check_command helm
check_command kind
check_command git
check_command curl

echo -e "\n${BLUE}Argo Tools:${NC}"
check_command argocd
check_command argo
check_command kubectl-argo-rollouts
check_command argo-events

echo -e "\n${BLUE}2. Checking Port Availability${NC}"
echo "----------------------------"
check_port 8080  # Orchestrator
check_port 30000 # Argo Events webhook
check_port 30001 # ArgoCD
check_port 30002 # Argo Workflows
check_port 9090  # Prometheus
check_port 3000  # Grafana

echo -e "\n${BLUE}3. Checking Docker${NC}"
echo "-------------------"
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker is running${NC}"
else
    echo -e "${RED}❌ Docker is not running${NC}"
    echo "Please start Docker Desktop or Docker daemon"
fi

echo -e "\n${BLUE}4. Checking Kind Cluster${NC}"
echo "------------------------"
if check_kind_cluster; then
    echo -e "\n${BLUE}Cluster Status:${NC}"
    kubectl cluster-info
    echo -e "\n${BLUE}Nodes:${NC}"
    kubectl get nodes
else
    echo -e "\n${YELLOW}To create the cluster, run:${NC}"
    echo "kind create cluster --name argocd-orchestrator"
fi

echo -e "\n${BLUE}5. Checking Project Structure${NC}"
echo "-------------------------------"

# Check if we're in the right directory
if [ -f "pom.xml" ] && [ -f "src/main/java/com/rtte/argocd/orchestrator/ArgoCDOrchestratorApplication.java" ]; then
    echo -e "${GREEN}✅ Project structure is correct${NC}"
else
    echo -e "${RED}❌ Project structure is incorrect${NC}"
    echo "Please run this script from the ArgoCD Orchestrator project root"
    exit 1
fi

# Check if required files exist
required_files=(
    "k8s/statefulset.yaml"
    "k8s/argo-events/eventbus.yaml"
    "k8s/argo-events/eventsource.yaml"
    "k8s/argo-events/sensor.yaml"
    "k8s/argo-workflows/deployment-workflow.yaml"
    "k8s/argo-rollouts/analysis-template.yaml"
    "examples/helm-charts/customers/values.yaml"
    "examples/helm-charts/customers/templates/_helpers.tpl"
    "LOCAL_TESTING_GUIDE.md"
)

echo -e "\n${BLUE}Required Files:${NC}"
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file (missing)${NC}"
    fi
done

echo -e "\n${BLUE}6. Quick Build Test${NC}"
echo "-------------------"
if [ -f "mvnw" ]; then
    echo -e "${BLUE}Testing Maven build...${NC}"
    if ./mvnw clean compile -q; then
        echo -e "${GREEN}✅ Maven build successful${NC}"
    else
        echo -e "${RED}❌ Maven build failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Maven wrapper not found, skipping build test${NC}"
fi

echo -e "\n${BLUE}7. Docker Build Test${NC}"
echo "---------------------"
if docker build -t argocd-orchestrator:test . >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker build successful${NC}"
    # Clean up test image
    docker rmi argocd-orchestrator:test >/dev/null 2>&1 || true
else
    echo -e "${RED}❌ Docker build failed${NC}"
fi

echo -e "\n${BLUE}8. Summary${NC}"
echo "--------"
echo -e "${GREEN}✅ Setup validation complete!${NC}"
echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Follow the LOCAL_TESTING_GUIDE.md for complete testing"
echo "2. Create kind cluster if not exists: kind create cluster --name argocd-orchestrator"
echo "3. Install Argo components: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
echo "4. Build and deploy the orchestrator"
echo "5. Run the end-to-end tests"

echo -e "\n${BLUE}Useful Commands:${NC}"
echo "• Check cluster: kubectl cluster-info"
echo "• View all resources: kubectl get all --all-namespaces"
echo "• Check ArgoCD: kubectl get pods -n argocd"
echo "• Port forward orchestrator: kubectl port-forward -n argocd-orchestrator svc/argocd-orchestrator 8080:8080"

echo -e "\n${GREEN}🎉 Ready for testing!${NC}" 
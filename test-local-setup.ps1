# Local Testing Setup Validation Script for Windows
# This script validates that all prerequisites are installed and the local environment is ready for testing

param(
    [switch]$SkipBuild
)

Write-Host "ArgoCD Orchestrator - Local Testing Setup Validation" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        Write-Host "✅ $Command is installed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ $Command is not installed" -ForegroundColor Red
        return $false
    }
}

# Function to check if port is available
function Test-Port {
    param([int]$Port)
    
    try {
        $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($connection) {
            Write-Host "WARNING: Port $Port is in use" -ForegroundColor Yellow
            return $false
        } else {
            Write-Host "✅ Port $Port is available" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "✅ Port $Port is available" -ForegroundColor Green
        return $true
    }
}

# Function to check if kind cluster exists
function Test-KindCluster {
    try {
        $clusters = kind get clusters 2>$null
        if ($clusters -contains "argocd-orchestrator") {
            Write-Host "✅ Kind cluster 'argocd-orchestrator' exists" -ForegroundColor Green
            return $true
        } else {
            Write-Host "WARNING: Kind cluster 'argocd-orchestrator' does not exist" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "WARNING: Kind cluster 'argocd-orchestrator' does not exist" -ForegroundColor Yellow
        return $false
    }
}

Write-Host "`n1. Checking Prerequisites" -ForegroundColor Blue
Write-Host "------------------------" -ForegroundColor Blue

# Check basic tools
Write-Host "`nBasic Tools:" -ForegroundColor Blue
$basicTools = @("docker", "kubectl", "helm", "kind", "git")
foreach ($tool in $basicTools) {
    Test-Command $tool
}

Write-Host "`nArgo Tools:" -ForegroundColor Blue
$argoTools = @("argocd", "argo", "kubectl-argo-rollouts", "argo-events")
foreach ($tool in $argoTools) {
    Test-Command $tool
}

Write-Host "`n2. Checking Port Availability" -ForegroundColor Blue
Write-Host "----------------------------" -ForegroundColor Blue
$ports = @(8080, 30000, 30001, 30002, 9090, 3000)
foreach ($port in $ports) {
    Test-Port $port
}

Write-Host "`n3. Checking Docker" -ForegroundColor Blue
Write-Host "-------------------" -ForegroundColor Blue
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop or Docker daemon" -ForegroundColor Yellow
}

Write-Host "`n4. Checking Kind Cluster" -ForegroundColor Blue
Write-Host "------------------------" -ForegroundColor Blue
if (Test-KindCluster) {
    Write-Host "`nCluster Status:" -ForegroundColor Blue
    kubectl cluster-info
    
    Write-Host "`nNodes:" -ForegroundColor Blue
    kubectl get nodes
} else {
    Write-Host "`nTo create the cluster, run:" -ForegroundColor Yellow
    Write-Host "kind create cluster --name argocd-orchestrator" -ForegroundColor White
}

Write-Host "`n5. Checking Project Structure" -ForegroundColor Blue
Write-Host "-------------------------------" -ForegroundColor Blue

# Check if we're in the right directory
if ((Test-Path "pom.xml") -and (Test-Path "src/main/java/com/rtte/argocd/orchestrator/ArgoCDOrchestratorApplication.java")) {
    Write-Host "✅ Project structure is correct" -ForegroundColor Green
} else {
    Write-Host "❌ Project structure is incorrect" -ForegroundColor Red
    Write-Host "Please run this script from the ArgoCD Orchestrator project root" -ForegroundColor Yellow
    exit 1
}

# Check if required files exist
$requiredFiles = @(
    "k8s/statefulset.yaml",
    "k8s/argo-events/eventbus.yaml",
    "k8s/argo-events/eventsource.yaml",
    "k8s/argo-events/sensor.yaml",
    "k8s/argo-workflows/deployment-workflow.yaml",
    "k8s/argo-rollouts/analysis-template.yaml",
    "examples/helm-charts/customers/values.yaml",
    "examples/helm-charts/customers/templates/_helpers.tpl",
    "LOCAL_TESTING_GUIDE.md"
)

Write-Host "`nRequired Files:" -ForegroundColor Blue
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file (missing)" -ForegroundColor Red
    }
}

if (-not $SkipBuild) {
    Write-Host "`n6. Quick Build Test" -ForegroundColor Blue
    Write-Host "-------------------" -ForegroundColor Blue
    if (Test-Path "mvnw.cmd") {
        Write-Host "Testing Maven build..." -ForegroundColor Blue
        try {
            & .\mvnw.cmd clean compile -q
            Write-Host "✅ Maven build successful" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Maven build failed" -ForegroundColor Red
        }
    } else {
        Write-Host "WARNING: Maven wrapper not found, skipping build test" -ForegroundColor Yellow
    }

    Write-Host "`n7. Docker Build Test" -ForegroundColor Blue
    Write-Host "---------------------" -ForegroundColor Blue
    try {
        docker build -t argocd-orchestrator:test . | Out-Null
        Write-Host "✅ Docker build successful" -ForegroundColor Green
        # Clean up test image
        docker rmi argocd-orchestrator:test | Out-Null
    }
    catch {
        Write-Host "❌ Docker build failed" -ForegroundColor Red
    }
}

Write-Host "`n8. Summary" -ForegroundColor Blue
Write-Host "--------" -ForegroundColor Blue
Write-Host "✅ Setup validation complete!" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Blue
Write-Host "1. Follow the LOCAL_TESTING_GUIDE.md for complete testing" -ForegroundColor White
Write-Host "2. Create kind cluster if not exists: kind create cluster --name argocd-orchestrator" -ForegroundColor White
Write-Host "3. Install Argo components: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml" -ForegroundColor White
Write-Host "4. Build and deploy the orchestrator" -ForegroundColor White
Write-Host "5. Run the end-to-end tests" -ForegroundColor White

Write-Host "`nUseful Commands:" -ForegroundColor Blue
Write-Host "• Check cluster: kubectl cluster-info" -ForegroundColor White
Write-Host "• View all resources: kubectl get all --all-namespaces" -ForegroundColor White
Write-Host "• Check ArgoCD: kubectl get pods -n argocd" -ForegroundColor White
Write-Host "• Port forward orchestrator: kubectl port-forward -n argocd-orchestrator svc/argocd-orchestrator 8080:8080" -ForegroundColor White

Write-Host "`nReady for testing!" -ForegroundColor Green 
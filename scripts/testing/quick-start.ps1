# Quick Start Script for ArgoCD Orchestrator - Windows
# This script automates the initial setup and testing process

param(
    [switch]$SkipValidation,
    [switch]$SkipCluster,
    [switch]$SkipArgo,
    [switch]$SkipInfrastructure,
    [switch]$SkipOrchestrator,
    [switch]$SkipTests
)

Write-Host "ArgoCD Orchestrator - Quick Start" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Function to execute command and handle errors
function Invoke-CommandWithErrorHandling {
    param(
        [string]$Command,
        [string]$Description,
        [switch]$ContinueOnError
    )
    
    Write-Host "`n$Description..." -ForegroundColor Blue
    try {
        Invoke-Expression $Command
        Write-Host "✅ $Description completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ $Description failed: $($_.Exception.Message)" -ForegroundColor Red
        if (-not $ContinueOnError) {
            Write-Host "Stopping execution due to error" -ForegroundColor Yellow
            exit 1
        }
        return $false
    }
}

# Function to wait for pods to be ready
function Wait-ForPods {
    param(
        [string]$Namespace,
        [string]$Label,
        [int]$Timeout = 300
    )
    
    Write-Host "Waiting for pods in namespace '$Namespace' with label '$Label'..." -ForegroundColor Blue
    $startTime = Get-Date
    $timeoutTime = $startTime.AddSeconds($Timeout)
    
    while ((Get-Date) -lt $timeoutTime) {
        try {
            $pods = kubectl get pods -n $Namespace -l $Label --no-headers 2>$null
            $readyPods = $pods | Where-Object { $_ -match "Running" }
            $totalPods = ($pods | Measure-Object).Count
            
            if ($totalPods -gt 0 -and $readyPods.Count -eq $totalPods) {
                Write-Host "✅ All pods are ready in namespace '$Namespace'" -ForegroundColor Green
                return $true
            }
            
            Write-Host "Waiting... ($($readyPods.Count)/$totalPods pods ready)" -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
        catch {
            Write-Host "Error checking pods: $($_.Exception.Message)" -ForegroundColor Red
            Start-Sleep -Seconds 10
        }
    }
    
    Write-Host "❌ Timeout waiting for pods in namespace '$Namespace'" -ForegroundColor Red
    return $false
}

# Step 1: Validate environment
if (-not $SkipValidation) {
    Write-Host "`nStep 1: Validating Environment" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta
    
    # Run the validation script
    & .\test-local-setup.ps1 -SkipBuild
}

# Step 2: Create Kind cluster
if (-not $SkipCluster) {
    Write-Host "`nStep 2: Creating Kind Cluster" -ForegroundColor Magenta
    Write-Host "===============================" -ForegroundColor Magenta
    
    # Check if cluster already exists
    $clusters = kind get clusters 2>$null
    if ($clusters -contains "argocd-orchestrator") {
        Write-Host "✅ Kind cluster 'argocd-orchestrator' already exists" -ForegroundColor Green
    } else {
        Invoke-CommandWithErrorHandling -Command "kind create cluster --name argocd-orchestrator" -Description "Creating Kind cluster"
    }
    
    # Verify cluster is running
    Invoke-CommandWithErrorHandling -Command "kubectl cluster-info" -Description "Verifying cluster status"
}

# Step 3: Install Argo components
if (-not $SkipArgo) {
    Write-Host "`nStep 3: Installing Argo Components" -ForegroundColor Magenta
    Write-Host "=====================================" -ForegroundColor Magenta
    
    # Create namespaces
    $namespaces = @("argocd", "argo-events", "argo-workflows", "argo-rollouts")
    foreach ($ns in $namespaces) {
        Invoke-CommandWithErrorHandling -Command "kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -" -Description "Creating namespace $ns"
    }
    
    # Install ArgoCD
    Invoke-CommandWithErrorHandling -Command "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml" -Description "Installing ArgoCD"
    
    # Install Argo Events
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml" -Description "Installing Argo Events"
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install-validating-webhook.yaml" -Description "Installing Argo Events webhook"
    
    # Install Argo Workflows
    Invoke-CommandWithErrorHandling -Command "kubectl apply -n argo-workflows -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.8/install.yaml" -Description "Installing Argo Workflows"
    
    # Install Argo Rollouts
    Invoke-CommandWithErrorHandling -Command "kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml" -Description "Installing Argo Rollouts"
    
    # Wait for Argo components to be ready
    Wait-ForPods -Namespace "argocd" -Label "app.kubernetes.io/name=argocd-server"
    Wait-ForPods -Namespace "argo-events" -Label "app.kubernetes.io/name=argo-events-controller"
    Wait-ForPods -Namespace "argo-workflows" -Label "app.kubernetes.io/name=argo-workflows-workflow-controller"
    Wait-ForPods -Namespace "argo-rollouts" -Label "app.kubernetes.io/name=argo-rollouts"
}

# Step 4: Install supporting infrastructure
if (-not $SkipInfrastructure) {
    Write-Host "`nStep 4: Installing Supporting Infrastructure" -ForegroundColor Magenta
    Write-Host "================================================" -ForegroundColor Magenta
    
    # Add Helm repositories
    Invoke-CommandWithErrorHandling -Command "helm repo add bitnami https://charts.bitnami.com/bitnami" -Description "Adding Bitnami Helm repository"
    Invoke-CommandWithErrorHandling -Command "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts" -Description "Adding Prometheus Helm repository"
    Invoke-CommandWithErrorHandling -Command "helm repo update" -Description "Updating Helm repositories"
    
    # Install PostgreSQL
    Invoke-CommandWithErrorHandling -Command "helm install postgres bitnami/postgresql --namespace default --set auth.postgresPassword=orchestrator123 --set auth.database=argocd_orchestrator --set primary.persistence.size=1Gi" -Description "Installing PostgreSQL"
    
    # Install Redis
    Invoke-CommandWithErrorHandling -Command "helm install redis bitnami/redis --namespace default --set auth.password=orchestrator123 --set master.persistence.size=1Gi" -Description "Installing Redis"
    
    # Install Prometheus and Grafana
    Invoke-CommandWithErrorHandling -Command "helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set grafana.enabled=true --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=1Gi" -Description "Installing Prometheus and Grafana"
    
    # Wait for infrastructure to be ready
    Wait-ForPods -Namespace "default" -Label "app.kubernetes.io/name=postgresql"
    Wait-ForPods -Namespace "default" -Label "app.kubernetes.io/name=redis"
}

# Step 5: Build and deploy the orchestrator
if (-not $SkipOrchestrator) {
    Write-Host "`nStep 5: Building and Deploying Orchestrator" -ForegroundColor Magenta
    Write-Host "=============================================" -ForegroundColor Magenta
    
    # Build the application
    Invoke-CommandWithErrorHandling -Command ".\mvnw.cmd clean package -DskipTests" -Description "Building Spring Boot application"
    
    # Build Docker image
    Invoke-CommandWithErrorHandling -Command "docker build -t argocd-orchestrator:latest ." -Description "Building Docker image"
    
    # Load image into kind cluster
    Invoke-CommandWithErrorHandling -Command "kind load docker-image argocd-orchestrator:latest --name argocd-orchestrator" -Description "Loading Docker image into Kind cluster"
    
    # Create namespace for orchestrator
    Invoke-CommandWithErrorHandling -Command "kubectl create namespace argocd-orchestrator --dry-run=client -o yaml | kubectl apply -f -" -Description "Creating orchestrator namespace"
    
    # Deploy the orchestrator
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f k8s/statefulset.yaml" -Description "Deploying orchestrator StatefulSet"
    
    # Wait for orchestrator to be ready
    Wait-ForPods -Namespace "argocd-orchestrator" -Label "app=argocd-orchestrator"
    
    # Port forward to access the orchestrator
    Write-Host "`nSetting up port forwarding for orchestrator..." -ForegroundColor Blue
    Start-Job -ScriptBlock { kubectl port-forward -n argocd-orchestrator svc/argocd-orchestrator 8080:8080 } | Out-Null
    Start-Sleep -Seconds 5
    
    # Test orchestrator health
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -UseBasicParsing -TimeoutSec 30
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Orchestrator is healthy" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Orchestrator health check returned status $($response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠️  Could not reach orchestrator health endpoint: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 6: Deploy Argo Events infrastructure
if (-not $SkipOrchestrator) {
    Write-Host "`nStep 6: Deploying Argo Events Infrastructure" -ForegroundColor Magenta
    Write-Host "===============================================" -ForegroundColor Magenta
    
    # Deploy EventBus
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f k8s/argo-events/eventbus.yaml" -Description "Deploying EventBus"
    
    # Deploy EventSource
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f k8s/argo-events/eventsource.yaml" -Description "Deploying EventSource"
    
    # Deploy Sensor
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f k8s/argo-events/sensor.yaml" -Description "Deploying Sensor"
    
    # Deploy Analysis Templates
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f k8s/argo-rollouts/analysis-template.yaml" -Description "Deploying Analysis Templates"
    
    # Deploy Workflow
    Invoke-CommandWithErrorHandling -Command "kubectl apply -f k8s/argo-workflows/deployment-workflow.yaml" -Description "Deploying Workflow"
}

# Step 7: Run basic tests
if (-not $SkipTests) {
    Write-Host "`nStep 7: Running Basic Tests" -ForegroundColor Magenta
    Write-Host "============================" -ForegroundColor Magenta
    
    # Test ArgoCD
    try {
        $argocdPods = kubectl get pods -n argocd --no-headers 2>$null
        $runningArgocdPods = $argocdPods | Where-Object { $_ -match "Running" }
        if ($runningArgocdPods.Count -gt 0) {
            Write-Host "✅ ArgoCD is running ($($runningArgocdPods.Count) pods)" -ForegroundColor Green
        } else {
            Write-Host "❌ ArgoCD pods are not running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error checking ArgoCD status" -ForegroundColor Red
    }
    
    # Test Argo Events
    try {
        $argoEventsPods = kubectl get pods -n argo-events --no-headers 2>$null
        $runningArgoEventsPods = $argoEventsPods | Where-Object { $_ -match "Running" }
        if ($runningArgoEventsPods.Count -gt 0) {
            Write-Host "✅ Argo Events is running ($($runningArgoEventsPods.Count) pods)" -ForegroundColor Green
        } else {
            Write-Host "❌ Argo Events pods are not running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error checking Argo Events status" -ForegroundColor Red
    }
    
    # Test Argo Workflows
    try {
        $argoWorkflowsPods = kubectl get pods -n argo-workflows --no-headers 2>$null
        $runningArgoWorkflowsPods = $argoWorkflowsPods | Where-Object { $_ -match "Running" }
        if ($runningArgoWorkflowsPods.Count -gt 0) {
            Write-Host "✅ Argo Workflows is running ($($runningArgoWorkflowsPods.Count) pods)" -ForegroundColor Green
        } else {
            Write-Host "❌ Argo Workflows pods are not running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error checking Argo Workflows status" -ForegroundColor Red
    }
    
    # Test Argo Rollouts
    try {
        $argoRolloutsPods = kubectl get pods -n argo-rollouts --no-headers 2>$null
        $runningArgoRolloutsPods = $argoRolloutsPods | Where-Object { $_ -match "Running" }
        if ($runningArgoRolloutsPods.Count -gt 0) {
            Write-Host "✅ Argo Rollouts is running ($($runningArgoRolloutsPods.Count) pods)" -ForegroundColor Green
        } else {
            Write-Host "❌ Argo Rollouts pods are not running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error checking Argo Rollouts status" -ForegroundColor Red
    }
    
    # Test Infrastructure
    try {
        $postgresPods = kubectl get pods -n default -l app.kubernetes.io/name=postgresql --no-headers 2>$null
        $runningPostgresPods = $postgresPods | Where-Object { $_ -match "Running" }
        if ($runningPostgresPods.Count -gt 0) {
            Write-Host "✅ PostgreSQL is running ($($runningPostgresPods.Count) pods)" -ForegroundColor Green
        } else {
            Write-Host "❌ PostgreSQL pods are not running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error checking PostgreSQL status" -ForegroundColor Red
    }
    
    try {
        $redisPods = kubectl get pods -n default -l app.kubernetes.io/name=redis --no-headers 2>$null
        $runningRedisPods = $redisPods | Where-Object { $_ -match "Running" }
        if ($runningRedisPods.Count -gt 0) {
            Write-Host "✅ Redis is running ($($runningRedisPods.Count) pods)" -ForegroundColor Green
        } else {
            Write-Host "❌ Redis pods are not running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error checking Redis status" -ForegroundColor Red
    }
}

# Summary
Write-Host "`nQuick Start Complete!" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green

Write-Host "`nWhat's Running:" -ForegroundColor Blue
Write-Host "• Kind cluster: argocd-orchestrator" -ForegroundColor White
Write-Host "• ArgoCD: http://localhost:30001 (port-forward needed)" -ForegroundColor White
Write-Host "• Argo Workflows: http://localhost:30002 (port-forward needed)" -ForegroundColor White
Write-Host "• Orchestrator: http://localhost:8080" -ForegroundColor White
Write-Host "• Prometheus: http://localhost:9090 (port-forward needed)" -ForegroundColor White
Write-Host "• Grafana: http://localhost:3000 (port-forward needed)" -ForegroundColor White

Write-Host "`nUseful Commands:" -ForegroundColor Blue
Write-Host "• View all resources: kubectl get all --all-namespaces" -ForegroundColor White
Write-Host "• Check orchestrator logs: kubectl logs -n argocd-orchestrator -l app=argocd-orchestrator -f" -ForegroundColor White
Write-Host "• Port forward ArgoCD: kubectl port-forward -n argocd svc/argocd-server 30001:80" -ForegroundColor White
Write-Host "• Port forward Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Blue
Write-Host "1. Follow LOCAL_TESTING_GUIDE.md for complete end-to-end testing" -ForegroundColor White
Write-Host "2. Set up Git repository with Helm charts" -ForegroundColor White
Write-Host "3. Create ApplicationSet for customer deployments" -ForegroundColor White
Write-Host "4. Test the complete workflow with sample deployments" -ForegroundColor White

Write-Host "`nNote: Some port forwards may need to be set up manually for full access" -ForegroundColor Yellow 
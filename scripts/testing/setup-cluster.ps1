# Setup script for ArgoCD Orchestrator Kind cluster
Write-Host "Setting up ArgoCD Orchestrator Kind cluster..." -ForegroundColor Cyan

# Function to wait for Docker
function Wait-ForDocker {
    Write-Host "Waiting for Docker to be ready..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        try {
            $null = docker version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Docker is ready!" -ForegroundColor Green
                return $true
            }
        } catch {
            # Ignore errors
        }
        
        $attempt++
        Write-Host "Attempt $attempt/$maxAttempts - Docker not ready yet..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
    
    Write-Host "Docker failed to start within timeout" -ForegroundColor Red
    return $false
}

# Function to create Kind cluster with memory allocation
function New-KindClusterWithMemory {
    param(
        [string]$ClusterName = "argocd-orchestrator",
        [string]$Memory = "32Gi"
    )
    
    Write-Host "Creating Kind cluster '$ClusterName' with $Memory memory..." -ForegroundColor Yellow
    
    # Delete existing cluster if it exists
    $existingClusters = kind get clusters 2>$null
    if ($existingClusters -contains $ClusterName) {
        Write-Host "Deleting existing cluster '$ClusterName'..." -ForegroundColor Yellow
        kind delete cluster --name $ClusterName
    }
    
    # Create cluster with Docker memory allocation
    Write-Host "Creating new cluster with $Memory memory allocation..." -ForegroundColor Yellow
    
    # Use Docker run with memory limits to create the Kind cluster
    $env:DOCKER_DEFAULT_PLATFORM = "linux/amd64"
    
    # Create a simple Kind cluster first
    kind create cluster --name $ClusterName --config kind-config-simple.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Kind cluster created successfully!" -ForegroundColor Green
        
        # Set the context
        kubectl config use-context "kind-$ClusterName"
        
        # Verify the cluster
        Write-Host "Verifying cluster..." -ForegroundColor Yellow
        kubectl cluster-info
        
        return $true
    } else {
        Write-Host "Failed to create Kind cluster" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    # Wait for Docker
    if (-not (Wait-ForDocker)) {
        Write-Host "Cannot proceed without Docker" -ForegroundColor Red
        exit 1
    }
    
    # Create the cluster
    if (New-KindClusterWithMemory -ClusterName "argocd-orchestrator" -Memory "32Gi") {
        Write-Host "`nCluster setup completed successfully!" -ForegroundColor Green
        Write-Host "You can now proceed with installing Argo components." -ForegroundColor Green
    } else {
        Write-Host "`nCluster setup failed!" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "Error during setup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 
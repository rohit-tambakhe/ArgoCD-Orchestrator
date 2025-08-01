# Setup script for ArgoCD Orchestrator using Docker Desktop Kubernetes
Write-Host "Setting up ArgoCD Orchestrator with Docker Desktop Kubernetes..." -ForegroundColor Cyan

# Function to enable Docker Desktop Kubernetes
function Enable-DockerKubernetes {
    Write-Host "Enabling Docker Desktop Kubernetes..." -ForegroundColor Yellow
    
    # Check if Docker Desktop is running
    try {
        $dockerVersion = docker version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker Desktop is not running. Please start Docker Desktop first." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Docker Desktop is not running. Please start Docker Desktop first." -ForegroundColor Red
        return $false
    }
    
    Write-Host "Docker Desktop is running. Please enable Kubernetes in Docker Desktop settings:" -ForegroundColor Yellow
    Write-Host "1. Open Docker Desktop" -ForegroundColor White
    Write-Host "2. Go to Settings > Kubernetes" -ForegroundColor White
    Write-Host "3. Check 'Enable Kubernetes'" -ForegroundColor White
    Write-Host "4. Set memory to 32GB" -ForegroundColor White
    Write-Host "5. Click 'Apply & Restart'" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Enter when Kubernetes is enabled..." -ForegroundColor Cyan
    Read-Host
    
    # Wait for Kubernetes to be ready
    Write-Host "Waiting for Kubernetes to be ready..." -ForegroundColor Yellow
    $maxAttempts = 60
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        try {
            $kubectlVersion = kubectl version --client 2>$null
            if ($LASTEXITCODE -eq 0) {
                $clusterInfo = kubectl cluster-info 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Kubernetes is ready!" -ForegroundColor Green
                    return $true
                }
            }
        } catch {
            # Ignore errors
        }
        
        $attempt++
        Write-Host "Attempt $attempt/$maxAttempts - Kubernetes not ready yet..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
    
    Write-Host "Kubernetes failed to start within timeout" -ForegroundColor Red
    return $false
}

# Function to install Argo components
function Install-ArgoComponents {
    Write-Host "Installing Argo components..." -ForegroundColor Yellow
    
    # Create namespaces
    Write-Host "Creating namespaces..." -ForegroundColor Yellow
    kubectl create namespace argocd
    kubectl create namespace argo-events
    kubectl create namespace argo-workflows
    kubectl create namespace argo-rollouts
    kubectl create namespace argocd-orchestrator
    
    # Install ArgoCD
    Write-Host "Installing ArgoCD..." -ForegroundColor Yellow
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Install Argo Events
    Write-Host "Installing Argo Events..." -ForegroundColor Yellow
    kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
    
    # Install Argo Workflows
    Write-Host "Installing Argo Workflows..." -ForegroundColor Yellow
    kubectl apply -n argo-workflows -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.8/install.yaml
    
    # Install Argo Rollouts
    Write-Host "Installing Argo Rollouts..." -ForegroundColor Yellow
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    
    Write-Host "Argo components installation completed!" -ForegroundColor Green
}

# Main execution
try {
    # Enable Docker Kubernetes
    if (Enable-DockerKubernetes) {
        Write-Host "Docker Kubernetes is ready!" -ForegroundColor Green
        
        # Install Argo components
        Install-ArgoComponents
        
        Write-Host "`nSetup completed successfully!" -ForegroundColor Green
        Write-Host "You can now proceed with building and deploying the orchestrator." -ForegroundColor Green
    } else {
        Write-Host "`nSetup failed!" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "Error during setup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 
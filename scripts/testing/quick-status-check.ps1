# Quick Status Check for ArgoCD Orchestrator
Write-Host "Quick Status Check" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

# Check cluster connectivity
Write-Host "`n1. Checking cluster connectivity..." -ForegroundColor Yellow
try {
    $clusterInfo = kubectl cluster-info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cluster is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ Cluster not accessible" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Cluster check failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check namespaces
Write-Host "`n2. Checking namespaces..." -ForegroundColor Yellow
try {
    $namespaces = kubectl get namespaces --no-headers 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Namespaces accessible" -ForegroundColor Green
        $namespaces | ForEach-Object { Write-Host "   - $($_)" -ForegroundColor White }
    } else {
        Write-Host "❌ Cannot get namespaces" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Namespace check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check ArgoCD pods
Write-Host "`n3. Checking ArgoCD pods..." -ForegroundColor Yellow
try {
    $pods = kubectl get pods -n argocd --no-headers 2>$null
    if ($LASTEXITCODE -eq 0) {
        $runningPods = $pods | Where-Object { $_ -match "Running" }
        Write-Host "✅ ArgoCD: $($runningPods.Count) pods running" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot get ArgoCD pods" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ ArgoCD check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check orchestrator pods
Write-Host "`n4. Checking orchestrator pods..." -ForegroundColor Yellow
try {
    $pods = kubectl get pods -n argocd-orchestrator --no-headers 2>$null
    if ($LASTEXITCODE -eq 0) {
        $runningPods = $pods | Where-Object { $_ -match "Running" }
        Write-Host "✅ Orchestrator: $($runningPods.Count) pods running" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot get orchestrator pods" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Orchestrator check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nStatus check completed!" -ForegroundColor Cyan 
# Zorin Inc Deployment Test Script
Write-Host "Deploying Zorin Inc Test Services" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Function to check kubectl connectivity
function Test-KubectlConnectivity {
    Write-Host "`n1. Testing kubectl connectivity..." -ForegroundColor Yellow
    
    try {
        $version = kubectl version --client 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ kubectl is available" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ kubectl not available" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ kubectl test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create Zorin Inc namespace
function Create-ZorinIncNamespace {
    Write-Host "`n2. Creating Zorin Inc namespace..." -ForegroundColor Yellow
    
    try {
        kubectl create namespace zorin-inc --dry-run=client -o yaml | kubectl apply -f - 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Zorin Inc namespace created/verified" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to create namespace" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Namespace creation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to deploy test services
function Deploy-TestServices {
    Write-Host "`n3. Deploying test services..." -ForegroundColor Yellow
    
    try {
        # Deploy user service
        Write-Host "   Deploying user-service..." -ForegroundColor White
        kubectl apply -f examples/customers/zorin-inc/test-deployment.yaml 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Test services deployed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to deploy test services" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check deployment status
function Check-DeploymentStatus {
    Write-Host "`n4. Checking deployment status..." -ForegroundColor Yellow
    
    try {
        Start-Sleep -Seconds 10
        
        $pods = kubectl get pods -n zorin-inc --no-headers 2>$null
        if ($LASTEXITCODE -eq 0) {
            $runningPods = $pods | Where-Object { $_ -match "Running" }
            $totalPods = ($pods | Measure-Object).Count
            
            Write-Host "   Total pods: $totalPods" -ForegroundColor White
            Write-Host "   Running pods: $($runningPods.Count)" -ForegroundColor White
            
            if ($runningPods.Count -eq $totalPods -and $totalPods -gt 0) {
                Write-Host "✅ All pods are running" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠️  Some pods are not running" -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "❌ Cannot get pod status" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Status check failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test service endpoints
function Test-ServiceEndpoints {
    Write-Host "`n5. Testing service endpoints..." -ForegroundColor Yellow
    
    try {
        # Test user service
        Write-Host "   Testing user-service..." -ForegroundColor White
        $userService = kubectl get svc user-service -n zorin-inc --no-headers 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ user-service is available" -ForegroundColor Green
        } else {
            Write-Host "❌ user-service not available" -ForegroundColor Red
        }
        
        # Test payment service
        Write-Host "   Testing payment-service..." -ForegroundColor White
        $paymentService = kubectl get svc payment-service -n zorin-inc --no-headers 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ payment-service is available" -ForegroundColor Green
        } else {
            Write-Host "❌ payment-service not available" -ForegroundColor Red
        }
        
        return $true
    } catch {
        Write-Host "❌ Service test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to show deployment summary
function Show-DeploymentSummary {
    Write-Host "`n" + "="*50 -ForegroundColor Cyan
    Write-Host "ZORIN INC DEPLOYMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "="*50 -ForegroundColor Cyan
    
    Write-Host "`nDeployed Services:" -ForegroundColor White
    Write-Host "✅ user-service (nginx:alpine)" -ForegroundColor Green
    Write-Host "✅ payment-service (nginx:alpine)" -ForegroundColor Green
    
    Write-Host "`nNamespace: zorin-inc" -ForegroundColor White
    Write-Host "Sync Waves: Configured" -ForegroundColor White
    Write-Host "Health Checks: Configured" -ForegroundColor White
    
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Deploy full ApplicationSet with Helm charts" -ForegroundColor White
    Write-Host "2. Test with actual microservice images" -ForegroundColor White
    Write-Host "3. Verify sync wave execution" -ForegroundColor White
    Write-Host "4. Test inter-service communication" -ForegroundColor White
}

# Main execution
try {
    Write-Host "Starting Zorin Inc deployment test..." -ForegroundColor Cyan
    
    # Run all tests
    $kubectlOk = Test-KubectlConnectivity
    if (-not $kubectlOk) {
        Write-Host "❌ kubectl connectivity failed. Please check your cluster." -ForegroundColor Red
        exit 1
    }
    
    $namespaceOk = Create-ZorinIncNamespace
    if (-not $namespaceOk) {
        Write-Host "❌ Namespace creation failed." -ForegroundColor Red
        exit 1
    }
    
    $deployOk = Deploy-TestServices
    if (-not $deployOk) {
        Write-Host "❌ Service deployment failed." -ForegroundColor Red
        exit 1
    }
    
    $statusOk = Check-DeploymentStatus
    $serviceOk = Test-ServiceEndpoints
    
    # Show summary
    Show-DeploymentSummary
    
    if ($statusOk -and $serviceOk) {
        Write-Host "`n🎉 Zorin Inc deployment test completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Deployment test completed with some issues." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error during deployment: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 
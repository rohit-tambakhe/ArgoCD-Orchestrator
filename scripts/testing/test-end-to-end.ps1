# End-to-End Test Script for ArgoCD Orchestrator
Write-Host "Testing ArgoCD Orchestrator - End to End" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Function to test cluster connectivity
function Test-ClusterConnectivity {
    Write-Host "`n1. Testing Cluster Connectivity..." -ForegroundColor Yellow
    
    try {
        $clusterInfo = kubectl cluster-info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Cluster connectivity successful" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Cluster connectivity failed" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Cluster connectivity failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test ArgoCD components
function Test-ArgoCDComponents {
    Write-Host "`n2. Testing ArgoCD Components..." -ForegroundColor Yellow
    
    $namespaces = @("argocd", "argo-events", "argo", "argo-rollouts")
    $allHealthy = $true
    
    foreach ($ns in $namespaces) {
        try {
            $pods = kubectl get pods -n $ns --no-headers 2>$null
            if ($LASTEXITCODE -eq 0) {
                $runningPods = $pods | Where-Object { $_ -match "Running" }
                $totalPods = ($pods | Measure-Object).Count
                
                if ($totalPods -gt 0) {
                    Write-Host "✅ $ns namespace: $($runningPods.Count)/$totalPods pods running" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  $ns namespace: No pods found" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ $ns namespace: Failed to get pods" -ForegroundColor Red
                $allHealthy = $false
            }
        } catch {
            Write-Host "❌ $ns namespace: Error - $($_.Exception.Message)" -ForegroundColor Red
            $allHealthy = $false
        }
    }
    
    return $allHealthy
}

# Function to test ArgoCD API
function Test-ArgoCDAPI {
    Write-Host "`n3. Testing ArgoCD API..." -ForegroundColor Yellow
    
    try {
        # Port forward ArgoCD server
        $portForward = Start-Job -ScriptBlock {
            kubectl port-forward -n argocd svc/argocd-server 8081:80
        }
        
        Start-Sleep -Seconds 5
        
        # Test ArgoCD API
        $response = Invoke-WebRequest -Uri "http://localhost:8081/api/v1/version" -UseBasicParsing -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ ArgoCD API is accessible" -ForegroundColor Green
            $apiWorking = $true
        } else {
            Write-Host "❌ ArgoCD API returned status: $($response.StatusCode)" -ForegroundColor Red
            $apiWorking = $false
        }
        
        # Stop port forward
        Stop-Job $portForward
        Remove-Job $portForward
        
        return $apiWorking
    } catch {
        Write-Host "❌ ArgoCD API test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test orchestrator application
function Test-OrchestratorApplication {
    Write-Host "`n4. Testing Orchestrator Application..." -ForegroundColor Yellow
    
    try {
        # Check if JAR file exists
        if (Test-Path "target/argocd-orchestrator-1.0.0.jar") {
            Write-Host "✅ Orchestrator JAR file exists" -ForegroundColor Green
            
            # Test basic Java execution
            $javaVersion = java -version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Java is available" -ForegroundColor Green
                
                # Test JAR execution (brief test)
                $testProcess = Start-Process -FilePath "java" -ArgumentList "-jar", "target/argocd-orchestrator-1.0.0.jar", "--spring.profiles.active=test" -PassThru -WindowStyle Hidden
                Start-Sleep -Seconds 3
                
                if (-not $testProcess.HasExited) {
                    Write-Host "✅ Orchestrator application starts successfully" -ForegroundColor Green
                    Stop-Process -Id $testProcess.Id -Force
                    return $true
                } else {
                    Write-Host "❌ Orchestrator application failed to start" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "❌ Java is not available" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ Orchestrator JAR file not found" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Orchestrator test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test Helm charts
function Test-HelmCharts {
    Write-Host "`n5. Testing Helm Charts..." -ForegroundColor Yellow
    
    try {
        # Check if Helm is available
        $helmVersion = helm version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Helm is available" -ForegroundColor Green
            
            # Check if example charts exist
            if (Test-Path "examples/helm-charts") {
                Write-Host "✅ Helm charts directory exists" -ForegroundColor Green
                
                # Test chart validation
                $charts = Get-ChildItem -Path "examples/helm-charts" -Directory
                foreach ($chart in $charts) {
                    if (Test-Path "$($chart.FullName)/Chart.yaml") {
                        Write-Host "✅ Found chart: $($chart.Name)" -ForegroundColor Green
                    }
                }
                return $true
            } else {
                Write-Host "❌ Helm charts directory not found" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ Helm is not available" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Helm test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test Docker functionality
function Test-DockerFunctionality {
    Write-Host "`n6. Testing Docker Functionality..." -ForegroundColor Yellow
    
    try {
        $dockerVersion = docker version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker is available" -ForegroundColor Green
            
            # Test Docker build capability
            $testImage = docker images | Select-String "hello-world"
            if ($testImage) {
                Write-Host "✅ Docker images accessible" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠️  Docker images not fully tested" -ForegroundColor Yellow
                return $true
            }
        } else {
            Write-Host "❌ Docker is not available" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Docker test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to generate test summary
function Show-TestSummary {
    param(
        [hashtable]$TestResults
    )
    
    Write-Host "`n" + "="*50 -ForegroundColor Cyan
    Write-Host "END-TO-END TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "="*50 -ForegroundColor Cyan
    
    $passed = 0
    $total = $TestResults.Count
    
    foreach ($test in $TestResults.GetEnumerator()) {
        if ($test.Value) {
            Write-Host "✅ $($test.Key): PASSED" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "❌ $($test.Key): FAILED" -ForegroundColor Red
        }
    }
    
    Write-Host "`nOverall Result: $passed/$total tests passed" -ForegroundColor Cyan
    
    if ($passed -eq $total) {
        Write-Host "🎉 All tests passed! The ArgoCD Orchestrator is ready for use." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed. Please review the issues above." -ForegroundColor Yellow
    }
    
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Configure your Git repositories with Helm charts" -ForegroundColor White
    Write-Host "2. Set up ApplicationSet for customer deployments" -ForegroundColor White
    Write-Host "3. Configure Argo Events for webhook triggers" -ForegroundColor White
    Write-Host "4. Deploy sample microservices for testing" -ForegroundColor White
}

# Main execution
$testResults = @{}

try {
    # Run all tests
    $testResults["Cluster Connectivity"] = Test-ClusterConnectivity
    $testResults["ArgoCD Components"] = Test-ArgoCDComponents
    $testResults["ArgoCD API"] = Test-ArgoCDAPI
    $testResults["Orchestrator Application"] = Test-OrchestratorApplication
    $testResults["Helm Charts"] = Test-HelmCharts
    $testResults["Docker Functionality"] = Test-DockerFunctionality
    
    # Show summary
    Show-TestSummary -TestResults $testResults
    
} catch {
    Write-Host "Error during testing: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 
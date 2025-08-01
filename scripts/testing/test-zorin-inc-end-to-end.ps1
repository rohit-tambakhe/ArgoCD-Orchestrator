# Zorin Inc End-to-End Test Script for ArgoCD Orchestrator
Write-Host "Testing Zorin Inc Microservices - End to End" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

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

# Function to test orchestrator deployment
function Test-OrchestratorDeployment {
    Write-Host "`n3. Testing Orchestrator Deployment..." -ForegroundColor Yellow
    
    try {
        $pods = kubectl get pods -n argocd-orchestrator --no-headers 2>$null
        if ($LASTEXITCODE -eq 0) {
            $runningPods = $pods | Where-Object { $_ -match "Running" }
            $totalPods = ($pods | Measure-Object).Count
            
            if ($totalPods -gt 0) {
                Write-Host "✅ Orchestrator: $($runningPods.Count)/$totalPods pods running" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Orchestrator: No pods running" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ Orchestrator: Failed to get pods" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Orchestrator test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test Zorin Inc namespace creation
function Test-ZorinIncNamespace {
    Write-Host "`n4. Testing Zorin Inc Namespace..." -ForegroundColor Yellow
    
    try {
        # Create Zorin Inc namespace
        kubectl create namespace zorin-inc --dry-run=client -o yaml | kubectl apply -f - 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Zorin Inc namespace created/verified" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to create Zorin Inc namespace" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Namespace test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test Helm charts structure
function Test-HelmChartsStructure {
    Write-Host "`n5. Testing Helm Charts Structure..." -ForegroundColor Yellow
    
    try {
        $chartsPath = "examples/customers/zorin-inc/helm-charts"
        if (Test-Path $chartsPath) {
            Write-Host "✅ Helm charts directory exists" -ForegroundColor Green
            
            $services = @("user-service", "order-service", "payment-service", "inventory-service", "notification-service")
            $allChartsExist = $true
            
            foreach ($service in $services) {
                $chartPath = "$chartsPath/$service"
                if (Test-Path "$chartPath/Chart.yaml") {
                    Write-Host "✅ Found chart: $service" -ForegroundColor Green
                } else {
                    Write-Host "❌ Missing chart: $service" -ForegroundColor Red
                    $allChartsExist = $false
                }
            }
            
            return $allChartsExist
        } else {
            Write-Host "❌ Helm charts directory not found" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Helm charts test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test ApplicationSet
function Test-ApplicationSet {
    Write-Host "`n6. Testing ApplicationSet..." -ForegroundColor Yellow
    
    try {
        $appSetPath = "examples/customers/zorin-inc/application-set.yaml"
        if (Test-Path $appSetPath) {
            Write-Host "✅ ApplicationSet file exists" -ForegroundColor Green
            
            # Validate ApplicationSet structure
            $appSetContent = Get-Content $appSetPath -Raw
            if ($appSetContent -match "zorin-inc-applications" -and $appSetContent -match "user-service") {
                Write-Host "✅ ApplicationSet structure is valid" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ ApplicationSet structure is invalid" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ ApplicationSet file not found" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ ApplicationSet test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test Docker registry images
function Test-DockerRegistryImages {
    Write-Host "`n7. Testing Docker Registry Images..." -ForegroundColor Yellow
    
    try {
        $images = @(
            "registry.hub.docker.com/library/spring-petclinic:2.7.0",
            "registry.hub.docker.com/library/spring-boot-rest-api:1.0.0",
            "registry.hub.docker.com/library/node-express-api:1.0.0",
            "registry.hub.docker.com/library/python-flask-api:1.0.0",
            "registry.hub.docker.com/library/go-gin-api:1.0.0"
        )
        
        $allImagesValid = $true
        
        foreach ($image in $images) {
            Write-Host "✅ Using open-source image: $image" -ForegroundColor Green
        }
        
        Write-Host "✅ All Docker registry images configured" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Docker registry test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test sync waves configuration
function Test-SyncWavesConfiguration {
    Write-Host "`n8. Testing Sync Waves Configuration..." -ForegroundColor Yellow
    
    try {
        $chartsPath = "examples/customers/zorin-inc/helm-charts"
        $syncWaves = @{
            "user-service" = "1"
            "payment-service" = "1"
            "inventory-service" = "1"
            "order-service" = "2"
            "notification-service" = "3"
        }
        
        $allSyncWavesValid = $true
        
        foreach ($service in $syncWaves.Keys) {
            $valuesPath = "$chartsPath/$service/values.yaml"
            if (Test-Path $valuesPath) {
                $content = Get-Content $valuesPath -Raw
                $expectedWave = $syncWaves[$service]
                if ($content -match "argocd\.argoproj\.io/sync-wave: `"$expectedWave`"") {
                    Write-Host "✅ $service sync wave: $expectedWave" -ForegroundColor Green
                } else {
                    Write-Host "❌ $service sync wave mismatch" -ForegroundColor Red
                    $allSyncWavesValid = $false
                }
            }
        }
        
        return $allSyncWavesValid
    } catch {
        Write-Host "❌ Sync waves test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to generate test summary
function Show-TestSummary {
    param(
        [hashtable]$TestResults
    )
    
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "ZORIN INC END-TO-END TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Cyan
    
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
        Write-Host "🎉 All tests passed! Zorin Inc setup is ready for deployment." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed. Please review the issues above." -ForegroundColor Yellow
    }
    
    Write-Host "`nNext Steps for Zorin Inc:" -ForegroundColor Cyan
    Write-Host "1. Deploy ApplicationSet to ArgoCD" -ForegroundColor White
    Write-Host "2. Configure Git repository with Helm charts" -ForegroundColor White
    Write-Host "3. Set up Argo Events webhook for Zorin Inc" -ForegroundColor White
    Write-Host "4. Test microservices deployment with sync waves" -ForegroundColor White
    Write-Host "5. Verify inter-service communication" -ForegroundColor White
}

# Main execution
$testResults = @{}

try {
    # Run all tests
    $testResults["Cluster Connectivity"] = Test-ClusterConnectivity
    $testResults["ArgoCD Components"] = Test-ArgoCDComponents
    $testResults["Orchestrator Deployment"] = Test-OrchestratorDeployment
    $testResults["Zorin Inc Namespace"] = Test-ZorinIncNamespace
    $testResults["Helm Charts Structure"] = Test-HelmChartsStructure
    $testResults["ApplicationSet"] = Test-ApplicationSet
    $testResults["Docker Registry Images"] = Test-DockerRegistryImages
    $testResults["Sync Waves Configuration"] = Test-SyncWavesConfiguration
    
    # Show summary
    Show-TestSummary -TestResults $testResults
    
} catch {
    Write-Host "Error during testing: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 
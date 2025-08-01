package com.rtte.argocd.orchestrator;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Main Spring Boot application class for ArgoCD Orchestrator
 * 
 * This orchestrator provides comprehensive management of ArgoCD applications
 * with Config as Code (CAC) integration, multi-tenant support, and advanced
 * deployment orchestration capabilities.
 */
@SpringBootApplication
@EnableCaching
@EnableAsync
@EnableScheduling
@EnableTransactionManagement
public class ArgoCDOrchestratorApplication {

    public static void main(String[] args) {
        SpringApplication.run(ArgoCDOrchestratorApplication.class, args);
    }
} 
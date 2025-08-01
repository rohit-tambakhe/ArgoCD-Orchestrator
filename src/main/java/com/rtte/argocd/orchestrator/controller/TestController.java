package com.rtte.argocd.orchestrator.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Simple test controller to verify the application is working
 */
@RestController
@RequestMapping("/api/test")
public class TestController {

    @GetMapping("/status")
    public Map<String, Object> getStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("status", "running");
        status.put("application", "ArgoCD Orchestrator");
        status.put("version", "1.0.0");
        status.put("company", "rtte");
        status.put("timestamp", System.currentTimeMillis());
        return status;
    }

    @GetMapping("/health")
    public Map<String, String> getHealth() {
        Map<String, String> health = new HashMap<>();
        health.put("status", "healthy");
        health.put("message", "ArgoCD Orchestrator is running");
        return health;
    }
} 
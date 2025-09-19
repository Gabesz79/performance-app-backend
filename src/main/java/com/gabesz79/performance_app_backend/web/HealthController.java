package com.gabesz79.performance_app_backend.web;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    @GetMapping("/api/healthz")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("ok");
    }
}

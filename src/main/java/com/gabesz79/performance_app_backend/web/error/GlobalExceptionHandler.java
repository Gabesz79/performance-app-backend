package com.gabesz79.performance_app_backend.web.error;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.*;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private Map<String,Object> body(HttpStatus status, String message, HttpServletRequest req) {
        Map<String,Object> m = new LinkedHashMap<>();
        m.put("status", status.value());
        m.put("error", status.getReasonPhrase());
        if (message != null) m.put("message", message);
        if (req != null) m.put("path", req.getRequestURI());
        return m;
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String,Object>> badJson(HttpMessageNotReadableException ex, HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(body(HttpStatus.BAD_REQUEST, "Malformed JSON", req));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String,Object>> bodyValidation(MethodArgumentNotValidException ex, HttpServletRequest req) {
        Map<String,Object> m = body(HttpStatus.BAD_REQUEST, "Validation failed", req);
        List<Map<String,String>> errs = ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> Map.of("field", fe.getField(), "message", String.valueOf(fe.getDefaultMessage())))
            .toList();
        m.put("validationErrors", errs);
        return ResponseEntity.badRequest().body(m);
    }

    @ExceptionHandler(jakarta.validation.ConstraintViolationException.class)
    public ResponseEntity<Map<String,Object>> paramValidation(jakarta.validation.ConstraintViolationException ex, HttpServletRequest req) {
        Map<String,Object> m = body(HttpStatus.BAD_REQUEST, "Validation failed", req);
        List<Map<String,String>> errs = ex.getConstraintViolations().stream()
            .map(v -> Map.of("field", String.valueOf(v.getPropertyPath()), "message", v.getMessage()))
            .toList();
        m.put("validationErrors", errs);
        return ResponseEntity.badRequest().body(m);
    }

    @ExceptionHandler(org.springframework.web.server.ResponseStatusException.class)
    public ResponseEntity<Map<String,Object>> rse(org.springframework.web.server.ResponseStatusException ex, HttpServletRequest req) {
        HttpStatus st = HttpStatus.valueOf(ex.getStatusCode().value());
        return ResponseEntity.status(st).body(body(st, ex.getReason(), req));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String,Object>> any(Exception ex, HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(body(HttpStatus.INTERNAL_SERVER_ERROR, ex.getMessage(), req));
    }
}

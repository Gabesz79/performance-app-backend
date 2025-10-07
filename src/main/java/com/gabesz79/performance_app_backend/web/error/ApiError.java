package com.gabesz79.performance_app_backend.web.error;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Value;
import org.springframework.validation.FieldError;

import java.time.Instant;
import java.util.List;

@Value
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiError {
    Instant timestamp;
    String path;
    int status;
    String error;
    String message;
    List<FieldError> validationErrors;

    @Value
    @Builder
    public static class FieldError {
        String field;
        String message;
    }
}

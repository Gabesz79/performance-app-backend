package com.gabesz79.performance_app_backend.workout;

public record WorkoutSummaryDto (
    long totalSessions,
    long totalMinutes,
    Double avgRpe
) {}

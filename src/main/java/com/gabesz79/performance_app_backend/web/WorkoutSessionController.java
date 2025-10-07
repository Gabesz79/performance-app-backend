package com.gabesz79.performance_app_backend.web;

import com.gabesz79.performance_app_backend.domain.Sport;
import com.gabesz79.performance_app_backend.domain.WorkoutSession;
import com.gabesz79.performance_app_backend.service.WorkoutSessionService;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/workouts")
@RequiredArgsConstructor
public class WorkoutSessionController {
    private final WorkoutSessionService service;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public WorkoutSessionDto create(@RequestBody @jakarta.validation.Valid CreateWorkoutSessionRequest req) {
        var ws = service.create(
            req.getAthleteId(),
            req.getSessionDate(),
            req.getSport(),
            req.getDurationMinutes(),
            req.getRpe(),
            req.getNotes()
        );
        return WorkoutSessionDto.from(ws);
    }

    @GetMapping
    public List<WorkoutSessionDto> list() {
        return service.list().stream().map(WorkoutSessionDto::from).toList();
    }

    @GetMapping("/{id}")
    public WorkoutSessionDto get(@PathVariable Long id) {
        return WorkoutSessionDto.from(service.get(id));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }

    @lombok.Data
    public static class CreateWorkoutSessionRequest {
        @NotNull Long athleteId;
        @NotNull LocalDate sessionDate;
        Sport sport;
        @NotNull @Min(1) Integer durationMinutes;
        @NotNull @Min(1) @Max(10) Short rpe;
        String notes;
    }

    @lombok.Value
    public static class WorkoutSessionDto {
        Long id;
        Long athleteId;
        LocalDate sessionDate;
        com.gabesz79.performance_app_backend.domain.Sport sport;
        Integer durationMinutes;
        Short rpe;
        String notes;
        java.time.Instant createdAt;
        java.time.Instant updatedAt;

        public static WorkoutSessionDto from(com.gabesz79.performance_app_backend.domain.WorkoutSession ws) {
            return new WorkoutSessionDto(
                ws.getId(),
                ws.getAthlete().getId(),
                ws.getSessionDate(),
                ws.getSport(),
                ws.getDurationMinutes(),
                ws.getRpe(),
                ws.getNotes(),
                ws.getCreatedAt(),
                ws.getUpdatedAt()
            );
        }
    }
}

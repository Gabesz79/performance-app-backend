package com.gabesz79.performance_app_backend.web;

import com.gabesz79.performance_app_backend.domain.Sport;
import com.gabesz79.performance_app_backend.domain.WorkoutSession;
import com.gabesz79.performance_app_backend.repository.WorkoutSessionRepository;
import com.gabesz79.performance_app_backend.service.WorkoutSessionService;
import com.gabesz79.performance_app_backend.workout.WorkoutSummaryDto;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/workouts")
public class WorkoutSessionController {

    private final WorkoutSessionService service;

    private final WorkoutSessionRepository repo;

    public WorkoutSessionController(WorkoutSessionService service, WorkoutSessionRepository repo) {
        this.service = service;
        this.repo = repo;
    }

    @GetMapping("/search")
    public List<WorkoutSessionDto> search(
        @RequestParam(required = false) Long athleteId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) Sport sport //ha String az entitásban: String
    ) {
        return repo.search(athleteId, from, to, sport)
            .stream()
            .map(WorkoutSessionDto::from)
            .toList();
    }

    @GetMapping("/summary")
    public WorkoutSummaryDto summary(
        @RequestParam(required = false) Long athleteId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) Sport sport //ha String az entitásban: String
    ) {
        return repo.summarize(athleteId, from, to, sport);
    }

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

    @GetMapping("/{id:\\d+}") //ütközés elkerülése érdekében id számra kényszerítése
    public WorkoutSession get(@PathVariable Long id) {
        return repo.findById(id).orElseThrow();
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

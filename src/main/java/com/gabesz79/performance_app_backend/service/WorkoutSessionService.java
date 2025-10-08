package com.gabesz79.performance_app_backend.service;

import com.gabesz79.performance_app_backend.domain.Athlete;
import com.gabesz79.performance_app_backend.domain.Sport;
import com.gabesz79.performance_app_backend.domain.WorkoutSession;
import com.gabesz79.performance_app_backend.repository.AthleteRepository;
import com.gabesz79.performance_app_backend.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutSessionService {
    private final WorkoutSessionRepository repo;
    private final AthleteRepository athleteRepo;

    public WorkoutSession create(Long athleteId,
                                 LocalDate sessionDate,
                                 Sport sport,
                                 Integer durationMinutes,
                                 Short rpe,
                                 String notes) {
        Athlete athlete = athleteRepo.findById(athleteId)
            .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Athlete not found: " + athleteId));

        WorkoutSession ws = WorkoutSession.builder()
            .athlete(athlete)
            .sessionDate(sessionDate)
            .sport(sport)
            .durationMinutes(durationMinutes)
            .rpe(rpe)
            .notes(notes)
            .build();
        return repo.save(ws);
    }

    @Transactional(readOnly = true)
    public List<WorkoutSession> list() {
        return repo.findAll();
    }

    @Transactional(readOnly = true)
    public WorkoutSession get(Long id) {
        return repo.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("WorkoutSession not found: " + id));
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }

}

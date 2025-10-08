package com.gabesz79.performance_app_backend.repository;

import com.gabesz79.performance_app_backend.domain.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {
    List<WorkoutSession> findByAthlete_id(Long athlete_id);
    List<WorkoutSession> findBySessionDateBetween(LocalDate from, LocalDate to);
}

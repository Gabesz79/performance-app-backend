package com.gabesz79.performance_app_backend.repository;

import com.gabesz79.performance_app_backend.domain.Sport;
import com.gabesz79.performance_app_backend.domain.WorkoutSession;
import com.gabesz79.performance_app_backend.workout.WorkoutSummaryDto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {
    List<WorkoutSession> findByAthlete_id(Long athlete_id);
    List<WorkoutSession> findBySessionDateBetween(LocalDate from, LocalDate to);

    @Query("""
        select ws from WorkoutSession ws
        where ws.athlete.id = coalesce(:athleteId, ws.athlete.id)
            and ws.sessionDate >= coalesce(:from, ws.sessionDate)
            and ws.sessionDate <= coalesce(:to, ws.sessionDate)
            and ws.sport = coalesce(:sport, ws.sport)
        order by ws.sessionDate
    """)
    List<WorkoutSession> search(
        @Param("athleteId") Long athleteId,
        @Param("from") LocalDate from,
        @Param("to") LocalDate to,
        @Param("sport") Sport sport
    );

    @Query("""
    select new com.gabesz79.performance_app_backend.workout.WorkoutSummaryDto(
        count(ws), coalesce(sum(ws.durationMinutes),0), avg(ws.rpe)
    )
    from WorkoutSession ws
        where ws.athlete.id = coalesce(:athleteId, ws.athlete.id)
            and ws.sessionDate >= coalesce(:from, ws.sessionDate)
            and ws.sessionDate <= coalesce(:to, ws.sessionDate)
            and ws.sport = coalesce(:sport, ws.sport)
    """)
    WorkoutSummaryDto summarize(
        @Param("athleteId") Long athleteId,
        @Param("from") LocalDate from,
        @Param("to") LocalDate to,
        @Param("sport") Sport sport
    );
}

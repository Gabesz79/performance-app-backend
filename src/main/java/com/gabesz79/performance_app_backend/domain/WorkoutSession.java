package com.gabesz79.performance_app_backend.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "workout_session")
public class WorkoutSession {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long Id;

    //Foreign Key -> athlete.id
    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "athlete_id", nullable = false)
    private Athlete athlete;

    @Column(name = "session_date", nullable = false)
    private LocalDate sessionDate;

    //Varchar oszlop -> enum névként tároljuk
    @Enumerated(EnumType.STRING)
    @Column(name = "sport", nullable=false, length = 32) //DB-ben charcter varying
    private Sport sport;

    @Column(name = "duration_minutes", nullable = false)
    private Integer durationMinutes;

    //PostgreSQL SMALLINT -> Java short
    @Column(name = "rpe", nullable = false, columnDefinition = "smallint")
    private Short rpe;

    @Column(name = "notes", columnDefinition = "text")
    private String notes;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}

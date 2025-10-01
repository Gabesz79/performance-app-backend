package com.gabesz79.performance_app_backend.repository;

import com.gabesz79.performance_app_backend.domain.Athlete;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AthleteRepository extends JpaRepository<Athlete, Long> {
    boolean existsByEmail(String email);
}

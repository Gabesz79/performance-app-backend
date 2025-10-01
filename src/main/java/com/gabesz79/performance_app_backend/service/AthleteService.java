package com.gabesz79.performance_app_backend.service;

import com.gabesz79.performance_app_backend.domain.Athlete;
import com.gabesz79.performance_app_backend.repository.AthleteRepository;
import jakarta.validation.ConstraintViolationException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AthleteService {
    private final AthleteRepository repo;

    public List<Athlete> findAll() {
        return repo.findAll();
    }

    public Athlete get(Long id) {
        return repo.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Athlete not found"));
    }

    public Athlete create(Athlete req) {
        req.setId(null);
        var now = java.time.Instant.now();
        if (req.getCreatedAt() == null) {
            req.setCreatedAt(now);
        }
        req.setUpdatedAt(now);
        try { //400-as hiba ok
            return repo.save(req);
        } catch (DataIntegrityViolationException e) {
            String msg = e.getMostSpecificCause() != null ? e.getMostSpecificCause().getMessage() : e.getMessage();
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "DB constraint violation: " + msg, e);
        } catch (ConstraintViolationException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Validation failed: " + e.getMessage(), e);
        }
    }

    public Athlete update(Long id, Athlete req) {
        Athlete a = this.get(id);
        if (req.getName() != null) a.setName(req.getName());
        a.setEmail(req.getEmail());
        return repo.save(a);
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }
}

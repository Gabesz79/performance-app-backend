package com.gabesz79.performance_app_backend.web;

import com.gabesz79.performance_app_backend.domain.Athlete;
import com.gabesz79.performance_app_backend.service.AthleteService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/athletes")
@RequiredArgsConstructor
@Tag(name = "Athletes")
@Validated
public class AthleteController {
    private final AthleteService service;

    @GetMapping
    public List<Athlete> all() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public Athlete one(@PathVariable Long id) {
        return service.get(id);
    }

    @PostMapping
    @org.springframework.web.bind.annotation.ResponseStatus(org.springframework.http.HttpStatus.CREATED)
    public Athlete create(@RequestBody Athlete req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    public Athlete update(@PathVariable Long id, @RequestBody Athlete req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}

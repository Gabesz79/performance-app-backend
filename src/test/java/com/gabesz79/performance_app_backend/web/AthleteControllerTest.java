package com.gabesz79.performance_app_backend.web;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gabesz79.performance_app_backend.domain.Athlete;
import com.gabesz79.performance_app_backend.service.AthleteService;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = AthleteController.class)
@AutoConfigureMockMvc(addFilters = false)
public class AthleteControllerTest {

    @Autowired
    MockMvc mockMvc;

    // Lokális mapper a teszthez (nem beanből)
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @MockitoBean
    AthleteService service;

    @Test
    void create_shouldReturn201() throws Exception {
        Athlete req = Athlete.builder()
            .name("Teszt Elek")
            .email("teszt@example.com")
            .build();

        Athlete saved = Athlete.builder()
            .id(1L)
            .name("Teszt Elek")
            .email("teszt@example.com")
            .createdAt(Instant.parse("2025-09-30T10:25:56.935323Z"))
            .updatedAt(Instant.parse("2025-09-30T10:25:56.935323Z"))
            .build();

        Mockito.when(service.create(Mockito.any(Athlete.class))).thenReturn(saved);

        mockMvc.perform(post("/api/athletes")
        .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id", is(1)))
            .andExpect(jsonPath("$.name", is("Teszt Elek")))
            .andExpect(jsonPath("$.email", is("teszt@example.com")))
            .andExpect(jsonPath("$.createdAt", notNullValue()))
            .andExpect(jsonPath("$.updatedAt", notNullValue()));
    }

    @Test
    void list_shouldReturn200_andArray() throws Exception {
        Athlete a = Athlete.builder()
            .id(1L)
            .name("Teszt Elek")
            .email("teszt@example.com")
            .createdAt(Instant.parse("2025-09-30T10:25:56.935323Z"))
            .updatedAt(Instant.parse("2025-09-30T10:25:56.935323Z"))
            .build();

        Mockito.when(service.findAll()).thenReturn(List.of(a));

        mockMvc.perform(get("/api/athletes"))
            .andDo(print())
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", notNullValue()))
            .andExpect(jsonPath("$", hasSize(1)))
            .andExpect(jsonPath("$[0].id", is(1)))
            .andExpect(jsonPath("$[0].name", is("Teszt Elek")))
            .andExpect(jsonPath("$[0].email", is("teszt@example.com")));
    }
}

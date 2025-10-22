package com.gabesz79.performance_app_backend.web;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("local")
public class WorkoutSessionControllerTest {
    @Autowired MockMvc mvc;

    @Test
    void search_all_between_dates_returns_8() throws Exception {
        mvc.perform(get("/api/workouts/search")
                .param("from", "2025-09-28")
                .param("to", "2025-10-05"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(8));
    }

    @Test
    void summary_all_between_dates_ok() throws Exception {
        mvc.perform(get("/api/workouts/summary")
                .param("from", "2025-09-28")
                .param("to", "2025-10-05"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.totalSessions").value(8))
            .andExpect(jsonPath("$.totalMinutes").value(340))
            .andExpect(jsonPath("$.avgRpe").value(5.875));
    }

    @Test
    void search_empty_result_when_outside_range() throws Exception {
        mvc.perform(get("/api/workouts/search")
                .param("from", "2020-01-01")
                .param("to", "2020-01-02"))
            .andExpect(status().isOk())
            .andExpect(content().json("[]"));
    }
}

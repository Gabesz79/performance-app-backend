package com.gabesz79.performance_app_backend.web;

import com.fasterxml.jackson.databind.ObjectMapper;
//DB-vel:
//import com.gabesz79.performance_app_backend.domain.Athlete;
//import com.gabesz79.performance_app_backend.repository.AthleteRepository;
//import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
//import org.springframework.boot.test.context.SpringBootTest;

//DB nélkül:
import com.gabesz79.performance_app_backend.web.error.GlobalExceptionHandler;
import org.springframework.boot.autoconfigure.validation.ValidationAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.ResultHandler;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.annotation.Validated;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import jakarta.validation.constraints.Min;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;

import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

//DB-vel:
//@SpringBootTest
//@AutoConfigureMockMvc
//DB nélkül:
class GlobalExceptionHandlerTest {

    private MockMvc mvc() {
        var objectMapper = new ObjectMapper();
        var validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        return MockMvcBuilders
            .standaloneSetup(new DummyController())
            .setControllerAdvice(new GlobalExceptionHandler())
            .setMessageConverters(new MappingJackson2HttpMessageConverter(objectMapper))
            .setValidator(validator)
            .build();
    }

    //DB-vel:
    //@Autowired AthleteRepository athleteRepository;
    //Long athleteId;

    //DB-vel:
    //@BeforeEach
    //void setup() {
    //    athleteRepository.deleteAll();
    //    athleteId = athleteRepository.save(Athlete.builder()
    //        .name("Err Teszt")
    //        .email("err@test.local")
    //        .build()).getId();
    //}


    //DB nélkül:
    @RestController
    @RequestMapping("/__test")
    @Validated // hogy a @RequestParam @Min(…) tényleg validáljon
    static class DummyController {

        @GetMapping("/notfound")
        public String notFound() {
            throw new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.NOT_FOUND, "nincs ilyen");
        }

        // Szándékosan @RequestBody: rossz JSON -> HttpMessageNotReadableException
        @PostMapping("/badjson")
        public String badJson(@RequestBody DummyBody body) { return "ok"; }

        @PostMapping("/validation")
        public String validation(@RequestBody @jakarta.validation.Valid NumDto dto) {
            return "ok";
        }
        record NumDto(@Min(5) Integer n) {}

        record DummyBody(String any) {}
    }

    //DB nélkül:
    @Test
    void malformedJson_returns400() throws Exception {
        mvc().perform(post("/__test/badjson")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{ invalid"))                 // tényleg hibás JSON
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.error").value("Bad Request"))
            .andExpect(jsonPath("$.path").value("/__test/badjson"));
    }

    @Test
    void validationError_returns400_withFieldList() throws Exception {
        mvc().perform(post("/__test/validation")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"n\":3}"))               // 3 < 5 → 400
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message").value("Validation failed"))
            .andExpect(jsonPath("$.validationErrors").isArray());
    }

    @Test
    void notFound_returns404() throws Exception {
        mvc().perform(get("/__test/notfound"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    //DB-vel:
    //@Test
    //void malformedJson_returns400() throws Exception {
    //  // Félbevágott JSON
    //  String bad = "{\"athleteId\":" + athleteId + ", \"sessionDate\":\"2025-01-01\"";

    //      mockMvc.perform(post("/api/workouts")
    //            .contentType(MediaType.APPLICATION_JSON)
    //          .content(bad))
    //      .andExpect(status().isBadRequest())
    //      .andExpect(jsonPath("$.status").value(400))
    //      .andExpect(jsonPath("$.error").value("Bad Request"))
    //      .andExpect(jsonPath("$.path").value("/api/workouts"));
    //}

    //DB-vel:
    //@Test
    //void validationError_returns400_withFieldList() throws Exception {
    //   // hiányzik rpe, durationMinutes = 0
    //  String body = """
    //    { "athleteId": %d, "sessionDate": "2025-01-01", "sport": "RUN",
    //      "durationMinutes": 0 }
    //    """.formatted(athleteId);

    //    mockMvc.perform(post("/api/workouts")
    //            .contentType(MediaType.APPLICATION_JSON)
    //           .content(body))
    //      .andExpect(status().isBadRequest())
    //      .andExpect(jsonPath("$.message").value("Validation failed"))
    //      .andExpect(jsonPath("$.validationErrors").isArray());
    //}

    //DB-vel:
    //@Test
    //void notFound_returns404() throws Exception {
    //    mockMvc.perform(get("/api/workouts/999999"))
    //        .andExpect(status().isNotFound())
    //        .andExpect(jsonPath("$.status").value(404));
    //}
}

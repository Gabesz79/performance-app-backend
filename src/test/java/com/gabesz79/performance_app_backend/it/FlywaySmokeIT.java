package com.gabesz79.performance_app_backend.it;
import com.gabesz79.performance_app_backend.PerformanceAppBackendApplication;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.containers.PostgreSQLContainer;

import static org.assertj.core.api.Assertions.assertThat;
@SpringBootTest(classes = PerformanceAppBackendApplication.class)
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class FlywaySmokeIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void registerProps(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.flyway.enabled", () -> true);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "none");
    }

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void flywayApplied_andCoreTablesExist() {
        // legalább néhány migrációnak le kellett futnia (V1..V5 nálunk)
        Integer migs = jdbc.queryForObject(
            "select count(*) from flyway_schema_history",
            Integer.class
        );
        assertThat(migs).isNotNull();
        assertThat(migs).isGreaterThanOrEqualTo(3);

        // 'athlete' tábla létezik
        Integer athlete = jdbc.queryForObject(
            "select count(*) from information_schema.tables where table_schema = 'public' and table_name = 'athlete'",
            Integer.class
        );
        assertThat(athlete).isNotNull();
        assertThat(athlete).isEqualTo(1);

        // 'workout_session' tábla is létezik
        Integer workout = jdbc.queryForObject(
            "select count(*) from information_schema.tables where table_schema = 'public' and table_name = 'workout_session'",
            Integer.class
        );
        assertThat(workout).isNotNull();
        assertThat(workout).isEqualTo(1);
    }
}

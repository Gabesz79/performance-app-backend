package hu.performance.it;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace.NONE;

@Testcontainers
@SpringBootTest(classes = com.gabesz79.performance_app_backend.PerformanceAppBackendApplication.class)
@AutoConfigureTestDatabase(replace = NONE)
class FlywaySmokeIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("testdb")
            .withUsername("postgres")
            .withPassword("postgres")
            .withReuse(false);

    @DynamicPropertySource
    static void overrideProps(DynamicPropertyRegistry r) {
        r.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
        r.add("spring.datasource.url", postgres::getJdbcUrl);
        r.add("spring.datasource.username", postgres::getUsername);
        r.add("spring.datasource.password", postgres::getPassword);

        r.add("spring.flyway.url", postgres::getJdbcUrl);
        r.add("spring.flyway.user", postgres::getUsername);
        r.add("spring.flyway.password", postgres::getPassword);
    }

    @Autowired
    Flyway flyway;

    @Autowired
    DataSource dataSource;

    @Test
    void flywayApplied_andUsersTableExists() throws Exception {
        // 1) Flyway állapot: van aktuális verzió, és az V1
        var current = flyway.info().current();
        assertThat(current).as("Flyway current migration should not be null").isNotNull();
        assertThat(current.getVersion()).isNotNull();
        assertThat(current.getVersion().getVersion()).isEqualTo("1");

        // 2) users tábla tényleg létezik
        try (Connection c = dataSource.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "select exists (select 1 from information_schema.tables " +
                     "where table_schema = 'public' and table_name = 'users')")) {
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                boolean exists = rs.getBoolean(1);
                assertTrue(exists, "users table should exist after Flyway migration");
            }
        }
    }
}
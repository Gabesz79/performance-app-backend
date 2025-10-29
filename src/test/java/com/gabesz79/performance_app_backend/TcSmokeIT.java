package com.gabesz79.performance_app_backend;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.AfterAll;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertEquals;

@Testcontainers(disabledWithoutDocker = false)
public class TcSmokeIT {

    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"))
                    .withDatabaseName("perfdb")
                    .withUsername("test")
                    .withPassword("test");

    @BeforeAll
    static void start() {
        postgres.start();
        System.out.println("TC JDBC URL  : " + postgres.getJdbcUrl());
        System.out.println("TC USER/PASS : " + postgres.getUsername() + " / " + postgres.getPassword());
    }

    @AfterAll
    static void stop() {
        postgres.stop();
    }

    @Test
    void canConnectAndSelectOne() throws Exception {
        try (Connection c = DriverManager.getConnection(
                postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword())) {
            try (Statement st = c.createStatement()) {
                try (ResultSet rs = st.executeQuery("SELECT 1")) {
                    rs.next();
                    assertEquals(1, rs.getInt(1));
                }
            }
        }
    }
}

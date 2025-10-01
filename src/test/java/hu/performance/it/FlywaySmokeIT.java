package hu.performance.it;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import javax.sql.DataSource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("local")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@org.junit.jupiter.api.Disabled("obsolete duplicate; replaced by com.gabesz79...it.FlywaySmokeIT")
class FlywaySmokeIT {

    @Autowired
    DataSource dataSource;      // <- ezt injektáljuk

    JdbcTemplate jdbc;          // <- ezt lokálisan hozzuk létre

    @BeforeEach
    void init() {
        this.jdbc = new JdbcTemplate(dataSource);
    }

    @Test
    void flywayApplied_andCoreTablesExist() {
        Integer migs = jdbc.queryForObject("select count(*) from flyway_schema_history", Integer.class);
        assertThat(migs).isNotNull();
        assertThat(migs).isGreaterThanOrEqualTo(5);

        Integer athlete = jdbc.queryForObject("""
            select count(*) from information_schema.tables
            where table_schema='public' and table_name='athlete'
        """, Integer.class);
        assertThat(athlete).isEqualTo(1);

        Integer ws = jdbc.queryForObject("""
            select count(*) from information_schema.tables
            where table_schema='public' and table_name='workout_session'
        """, Integer.class);
        assertThat(ws).isEqualTo(1);
    }
}

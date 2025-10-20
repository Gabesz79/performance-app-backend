package com.gabesz79.performance_app_backend.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    // 1) ACTUATOR lánc: /actuator/health/** nyitott, a többi actuator védett (Basic)
    @Bean
    @Order(1)
    SecurityFilterChain actuatorChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/actuator/**")
            .authorizeHttpRequests(reg -> reg
                .requestMatchers("/actuator/health/**").permitAll() // healthcheckek maradjanak nyitva
                .anyRequest().authenticated()
            )
            .httpBasic(Customizer.withDefaults())
            .csrf(csrf -> csrf.disable());
        return http.build();
    }

    // 2) API lánc: minden más endpoint szabadon elérhető (Swagger amúgy is OFF prodon)
    @Bean
    @Order(2)
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(reg -> reg
                .anyRequest().permitAll()
            )
            .csrf(csrf -> csrf.disable());
        return http.build();
    }
}

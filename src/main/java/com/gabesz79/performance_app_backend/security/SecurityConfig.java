package com.gabesz79.performance_app_backend.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

import org.springframework.boot.actuate.autoconfigure.security.servlet.EndpointRequest;


import static org.springframework.security.config.Customizer.withDefaults;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.RequestMatcher;
import org.springframework.web.servlet.handler.HandlerMappingIntrospector;

@Configuration
@Profile({"local", "portfolio"}) //Actuator lánc definiálva a "local" és a "portfolio" profilhoz is
public class SecurityConfig {

    // 1) ACTUATOR lánc: /actuator/health/** nyitott, a többi actuator védett (Basic)
    @Bean
    @Order(1)
    SecurityFilterChain actuatorChain(HttpSecurity http) throws Exception {
        http
            // csak az actuator endpontokra érvényes
            .securityMatcher(EndpointRequest.toAnyEndpoint())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(EndpointRequest.to("health", "info")).permitAll()
                .anyRequest().hasRole("ACTUATOR")
            )
            .httpBasic(withDefaults())
            // ⬇⬇ CSRF bekapcsolva marad, de az actuator-ra ignoráljuk
            .csrf(csrf -> csrf.ignoringRequestMatchers(EndpointRequest.toAnyEndpoint()));
        return http.build();
    }


    // 2) API lánc: minden más endpoint szabadon elérhető (Swagger amúgy is OFF prodon)
    @Bean
    @Order(2)
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        // PathPattern-alapú matcherek létrehozása builderrel
        RequestMatcher api         = PathPatternRequestMatcher.withDefaults().matcher("/api/**");
        RequestMatcher swaggerUi   = PathPatternRequestMatcher.withDefaults().matcher("/swagger-ui/**");
        RequestMatcher swaggerHtml = PathPatternRequestMatcher.withDefaults().matcher("/swagger-ui.html");
        RequestMatcher openApi     = PathPatternRequestMatcher.withDefaults().matcher("/v3/api-docs/**");

        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/healthz", "/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**").permitAll()
                .anyRequest().permitAll() // ha most minden API nyitott
            )
            // CSRF bekapcsolva marad, de ezekre az útvonalakra ignoráljuk
            .csrf(csrf -> csrf.ignoringRequestMatchers(api, swaggerUi, swaggerHtml, openApi));

        return http.build();
    }

}

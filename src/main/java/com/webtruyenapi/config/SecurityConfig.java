package com.webtruyenapi.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.*;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    // ================= PASSWORD =================
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // ================= CORS =================
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {

        CorsConfiguration config = new CorsConfiguration();

        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET","POST","PUT","DELETE","PATCH","OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization"));
        config.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);

        return source;
    }

    // ================= SECURITY =================
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                .authorizeHttpRequests(auth -> auth


                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // ===== SWAGGER =====
                        .requestMatchers(
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/v3/api-docs/**",
                                "/v3/api-docs.yaml"
                        ).permitAll()

                        // ===== AUTH PUBLIC =====
                        .requestMatchers("/api/Auth/login",
                                "/api/Auth/register",
                                "/api/Auth/request-reset",
                                "/api/Auth/reset-password",
                                "/api/Auth/google-login"
                        ).permitAll()

                        // ===== PUBLIC READ APIs =====
                        .requestMatchers(HttpMethod.GET,
                                "/api/Comics/**",
                                "/api/Chapters/**",
                                "/api/Genres/**"
                        ).permitAll()

                        // ===== FILE UPLOAD PUBLIC =====
                        .requestMatchers("/uploads/**").permitAll()

                        // ===== FOLLOW / PROFILE NEED LOGIN =====
                        .requestMatchers("/api/Follows/**").authenticated()
                        .requestMatchers("/api/Auth/profile").authenticated()
                        .requestMatchers("/api/Auth/upload-avatar").authenticated()

                        // ===== EVERYTHING ELSE =====
                        .anyRequest().authenticated()
                );
//                .addFilterBefore(jwtAuthenticationFilter,
//                        UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
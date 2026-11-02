package com.comodeu.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.time.Duration;
import java.util.List;

/**
 * CORS para o Flutter Web (o app roda no navegador em outra origem/porta).
 *
 * As origens permitidas vêm da propriedade app.cors.allowed-origins
 * (lista separada por vírgula, aceita padrões como http://localhost:*):
 *  - dev:  qualquer porta em localhost/127.0.0.1 (o `flutter run -d chrome` usa porta aleatória)
 *  - prod: variável de ambiente CORS_ALLOWED_ORIGINS (ex.: https://comodeu.app)
 *
 * Aplicado pelo Spring Security via http.cors(...) em {@link SecurityConfig},
 * o que garante que o preflight (OPTIONS) passe antes da autenticação.
 */
@Configuration
public class CorsConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origins:}") List<String> allowedOrigins) {

        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(allowedOrigins.stream()
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .toList());
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept"));
        // Autenticação vai no header Authorization (Basic hoje, JWT depois), não em cookie.
        config.setAllowCredentials(false);
        config.setMaxAge(Duration.ofHours(1));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}

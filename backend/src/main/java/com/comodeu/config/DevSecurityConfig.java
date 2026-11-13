package com.comodeu.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;

/**
 * Libera ferramentas de desenvolvimento apenas no perfil "dev":
 *  - Swagger UI e OpenAPI (/swagger-ui.html, /swagger-ui/**, /v3/api-docs/**)
 *
 * Usa WebSecurityCustomizer (em vez de um SecurityFilterChain) para não
 * substituir a configuração de segurança padrão das demais rotas.
 *
 * As chamadas feitas pelo Swagger ("Try it out") continuam exigindo token:
 * faça POST /auth/login (admin@comodeu.dev / admin123), copie o token e
 * cole no botão "Authorize".
 */
@Configuration
@Profile("dev")
public class DevSecurityConfig {

    @Bean
    public WebSecurityCustomizer devToolsSecurityCustomizer() {
        PathPatternRequestMatcher.Builder path = PathPatternRequestMatcher.withDefaults();
        return web -> web.ignoring().requestMatchers(
                path.matcher("/swagger-ui.html"),
                path.matcher("/swagger-ui/**"),
                path.matcher("/v3/api-docs/**"));
    }
}

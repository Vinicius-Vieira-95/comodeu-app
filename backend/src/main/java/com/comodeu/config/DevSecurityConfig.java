package com.comodeu.config;

import org.springframework.boot.autoconfigure.security.servlet.PathRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;

/**
 * Libera ferramentas de desenvolvimento apenas no perfil "dev":
 *  - console do H2 (/h2-console)
 *  - Swagger UI e OpenAPI (/swagger-ui.html, /swagger-ui/**, /v3/api-docs/**)
 *
 * Usa WebSecurityCustomizer (em vez de um SecurityFilterChain) para não
 * substituir a configuração de segurança padrão das demais rotas.
 * Como o Spring Security ignora essas rotas, o header X-Frame-Options
 * também não é aplicado, permitindo os frames do console do H2.
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
                PathRequest.toH2Console(),
                path.matcher("/swagger-ui.html"),
                path.matcher("/swagger-ui/**"),
                path.matcher("/v3/api-docs/**"));
    }
}

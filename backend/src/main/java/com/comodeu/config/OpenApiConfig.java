package com.comodeu.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Documentação da API (OpenAPI 3 / Swagger UI).
 *
 * Swagger UI: http://localhost:8080/api/swagger-ui.html
 * JSON:       http://localhost:8080/api/v3/api-docs
 *
 * Autenticação JWT no Swagger UI:
 *  1. POST /auth/login e copie o "token" da resposta
 *  2. Clique em "Authorize" e cole só o token (sem "Bearer ")
 */
@Configuration
public class OpenApiConfig {

    private static final String SECURITY_SCHEME = "bearerAuth";

    @Bean
    public OpenAPI comoDeUOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("COMO D'EU API")
                        .description("API de avaliações, evidências e classificações do COMO D'EU.")
                        .version("1.0.0"))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME, new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME));
    }
}

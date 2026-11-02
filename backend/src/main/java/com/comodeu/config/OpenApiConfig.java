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
 * O esquema "basicAuth" habilita o botão "Authorize" do Swagger UI.
 * Quando a autenticação JWT for implementada, troque por um esquema
 * HTTP "bearer" com bearerFormat "JWT".
 */
@Configuration
public class OpenApiConfig {

    private static final String SECURITY_SCHEME = "basicAuth";

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
                                .scheme("basic")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME));
    }
}

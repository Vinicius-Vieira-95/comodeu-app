package com.comodeu.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Configuração de segurança da API REST (todos os perfis).
 *
 * - CSRF desligado: a API não usa sessão nem formulário, então não há cookie
 *   de sessão para ser explorado; com ele ligado, POST/PUT/DELETE são bloqueados.
 * - Stateless: nenhuma sessão HTTP é criada; cada requisição se autentica sozinha.
 * - HTTP Basic: autenticação provisória (no dev: admin / admin) até o JWT
 *   ser implementado. Quando o filtro JWT existir, adicione-o aqui com
 *   http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
 *   e remova o httpBasic.
 *
 * - CORS: origens permitidas definidas em {@link CorsConfig}.
 *
 * As rotas liberadas só no dev (H2 console, Swagger) ficam em {@link DevSecurityConfig}.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain apiSecurityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(Customizer.withDefaults()) // usa o CorsConfigurationSource de CorsConfig
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(Customizer.withDefaults())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/error").permitAll()
                        .anyRequest().authenticated());
        return http.build();
    }
}

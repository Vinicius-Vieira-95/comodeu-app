package com.comodeu.config;

import com.comodeu.security.JwtAuthenticationFilter;
import com.comodeu.security.JwtService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Configuração de segurança da API REST (todos os perfis).
 *
 * - JWT: o cliente faz login em POST /auth/login (ou cadastro em POST /auth/register),
 *   recebe um token e o envia em toda requisição: "Authorization: Bearer <token>".
 *   O {@link JwtAuthenticationFilter} valida o token antes de cada requisição.
 * - Públicas: POST /auth/register, POST /auth/login e /error. O resto exige token.
 * - Sem token válido: 401 (sem o header WWW-Authenticate, para o navegador não abrir popup).
 * - CSRF desligado e stateless: não há sessão nem cookie, a autenticação vai no header.
 * - CORS: origens permitidas definidas em {@link CorsConfig}.
 *
 * As rotas liberadas só no dev (H2 console, Swagger) ficam em {@link DevSecurityConfig}.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain apiSecurityFilterChain(HttpSecurity http,
                                                      JwtService jwtService,
                                                      UserDetailsService userDetailsService) throws Exception {
        http
                .cors(Customizer.withDefaults()) // usa o CorsConfigurationSource de CorsConfig
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .exceptionHandling(ex -> ex.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/auth/register", "/auth/login").permitAll()
                        .requestMatchers("/error").permitAll()
                        .anyRequest().authenticated())
                .addFilterBefore(new JwtAuthenticationFilter(jwtService, userDetailsService),
                        UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /** Hash das senhas. BCrypt é lento de propósito, dificultando ataques de força bruta. */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /** Usado no login: confere e-mail/senha com o AppUserDetailsService + PasswordEncoder. */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}

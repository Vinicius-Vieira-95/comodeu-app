package com.comodeu.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Lê o header "Authorization: Bearer <token>", valida o JWT e autentica a requisição.
 * Sem token (ou com token inválido) a requisição segue como anônima, e o
 * Spring Security responde 401 se a rota exigir login.
 *
 * Não é um @Component de propósito: o Spring Boot registraria o filtro também
 * fora da cadeia do Spring Security. Ele é instanciado em SecurityConfig.
 */
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);

        if (header != null && header.startsWith(BEARER_PREFIX)
                && SecurityContextHolder.getContext().getAuthentication() == null) {
            String token = header.substring(BEARER_PREFIX.length()).trim();

            jwtService.validateAndGetEmail(token).ifPresent(email -> {
                try {
                    // Recarrega do banco: usuário removido perde o acesso mesmo com token válido.
                    UserDetails user = userDetailsService.loadUserByUsername(email);
                    var authentication = new UsernamePasswordAuthenticationToken(
                            user, null, user.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                } catch (UsernameNotFoundException ignored) {
                    // token de um usuário que não existe mais: segue anônimo
                }
            });
        }

        filterChain.doFilter(request, response);
    }
}

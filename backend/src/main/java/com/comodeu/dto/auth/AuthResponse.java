package com.comodeu.dto.auth;

/**
 * Resposta de login/cadastro.
 * O cliente deve enviar o token em todas as requisições:
 *   Authorization: Bearer <token>
 */
public record AuthResponse(
        String token,
        String tokenType,
        long expiresIn,   // validade em segundos
        UserResponse user
) {}

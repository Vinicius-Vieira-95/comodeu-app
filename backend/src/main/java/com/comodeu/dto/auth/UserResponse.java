package com.comodeu.dto.auth;

import com.comodeu.entity.User;

/** Dados públicos do usuário (sem a senha). */
public record UserResponse(Long id, String name, String email, String role) {

    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail(), user.getRole().name());
    }
}

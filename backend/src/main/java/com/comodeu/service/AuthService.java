package com.comodeu.service;

import com.comodeu.dto.auth.AuthResponse;
import com.comodeu.dto.auth.LoginRequest;
import com.comodeu.dto.auth.RegisterRequest;
import com.comodeu.dto.auth.UserResponse;
import com.comodeu.entity.User;
import com.comodeu.repository.UserRepository;
import com.comodeu.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "E-mail já cadastrado");
        }

        User user = userRepository.save(User.builder()
                .name(request.name().trim())
                .email(email)
                .password(passwordEncoder.encode(request.password()))
                .role(User.Role.USER) // cadastro público nunca cria ADMIN
                .build());

        return toAuthResponse(user);
    }

    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.email());
        try {
            // Confere e-mail e senha (BCrypt) via Spring Security.
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, request.password()));
        } catch (AuthenticationException e) {
            // Mesma mensagem para e-mail inexistente e senha errada (não revela quais e-mails existem).
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "E-mail ou senha inválidos");
        }

        User user = userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "E-mail ou senha inválidos"));
        return toAuthResponse(user);
    }

    public UserResponse getCurrentUser(String email) {
        return userRepository.findByEmailIgnoreCase(email)
                .map(UserResponse::from)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Usuário não encontrado"));
    }

    private AuthResponse toAuthResponse(User user) {
        return new AuthResponse(
                jwtService.generateToken(user),
                "Bearer",
                jwtService.getExpirationMs() / 1000,
                UserResponse.from(user));
    }

    private static String normalizeEmail(String email) {
        return email.trim().toLowerCase();
    }
}

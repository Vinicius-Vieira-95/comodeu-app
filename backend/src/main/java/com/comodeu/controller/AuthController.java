package com.comodeu.controller;

import com.comodeu.dto.auth.AuthResponse;
import com.comodeu.dto.auth.LoginRequest;
import com.comodeu.dto.auth.RegisterRequest;
import com.comodeu.dto.auth.UserResponse;
import com.comodeu.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Tag(name = "Autenticação", description = "Cadastro, login e usuário logado (JWT)")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @SecurityRequirements // rota pública: sem cadeado no Swagger
    @Operation(summary = "Cadastra um usuário e já devolve o token")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @PostMapping("/login")
    @SecurityRequirements
    @Operation(summary = "Faz login com e-mail e senha e devolve o token")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @GetMapping("/me")
    @Operation(summary = "Dados do usuário dono do token")
    public ResponseEntity<UserResponse> me(Authentication authentication) {
        return ResponseEntity.ok(authService.getCurrentUser(authentication.getName()));
    }

    /** Erros de negócio (409 e-mail já cadastrado, 401 login inválido) com a mensagem no corpo. */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleStatus(ResponseStatusException e) {
        return ResponseEntity.status(e.getStatusCode()).body(Map.of(
                "status", e.getStatusCode().value(),
                "error", e.getReason() == null ? "Erro" : e.getReason()));
    }

    /** Erros de validação do corpo: 400 com a mensagem de cada campo. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException e) {
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError error : e.getBindingResult().getFieldErrors()) {
            fields.putIfAbsent(error.getField(), error.getDefaultMessage());
        }
        return ResponseEntity.badRequest().body(Map.of(
                "status", 400,
                "error", "Dados inválidos",
                "fields", fields));
    }
}

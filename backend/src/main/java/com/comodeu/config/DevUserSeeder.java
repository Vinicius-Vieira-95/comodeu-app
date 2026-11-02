package com.comodeu.config;

import com.comodeu.entity.User;
import com.comodeu.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Cria um usuário ADMIN ao subir no perfil "dev" (o H2 começa vazio a cada start).
 * Credenciais em app.dev-user.* no application-dev.yml.
 */
@Slf4j
@Component
@Profile("dev")
@RequiredArgsConstructor
public class DevUserSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.dev-user.name:Administrador}")
    private String name;

    @Value("${app.dev-user.email}")
    private String email;

    @Value("${app.dev-user.password}")
    private String password;

    @Override
    public void run(String... args) {
        if (userRepository.existsByEmailIgnoreCase(email)) {
            return;
        }
        userRepository.save(User.builder()
                .name(name)
                .email(email.toLowerCase())
                .password(passwordEncoder.encode(password))
                .role(User.Role.ADMIN)
                .build());
        log.info("Usuário de desenvolvimento criado: {} (ADMIN)", email);
    }
}

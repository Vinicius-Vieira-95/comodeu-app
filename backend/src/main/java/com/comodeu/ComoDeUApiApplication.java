package com.comodeu;

import com.comodeu.service.ComoItemService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class ComoDeUApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(ComoDeUApiApplication.class, args);
    }

    @Bean
    public CommandLineRunner init(ComoItemService comoItemService) {
        return args -> {
            System.out.println("Inicializando itens COMO D'EU...");
            comoItemService.initializeComoItems();
            System.out.println("✓ Itens COMO D'EU carregados com sucesso!");
            System.out.println("API disponível em: http://localhost:8080/api");
        };
    }
}

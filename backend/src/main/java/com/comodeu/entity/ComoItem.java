package com.comodeu.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "como_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ComoItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Integer itemNumber;  // 1-17

    @Column(nullable = false)
    private String name;  // Ex: "Acessibilidade Física"

    @Column(length = 500)
    private String description;

    @Column(nullable = false)
    private String category;  // Acessibilidade, Informação, Experiência, etc

    private String keywords;  // Separado por vírgula para sugestão automática

    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;
}

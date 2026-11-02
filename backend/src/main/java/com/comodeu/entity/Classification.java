package com.comodeu.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "classifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Classification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long evidenceId;  // Foreign key para Evidence

    @Column(nullable = false)
    private Long comoItemId;  // Foreign key para ComoItem

    @Column(length = 2000)
    private String personalAnalysis;  // Interpretação do aluno

    @Column(nullable = false)
    private LocalDateTime classificationTime;

    @PrePersist
    protected void onCreate() {
        classificationTime = LocalDateTime.now();
    }
}

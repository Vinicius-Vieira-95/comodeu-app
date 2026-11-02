package com.comodeu.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "evaluations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Evaluation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String visitorName;

    @Column(nullable = false, length = 200)
    private String culturalSpaceName;

    @Column(length = 50)
    private String spaceType;  // Museu, Galeria, Teatro, etc

    @Column(nullable = false, updatable = false)
    private LocalDateTime visitDate;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column
    private LocalDateTime completedAt;

    @Enumerated(EnumType.STRING)
    private EvaluationStatus status;  // IN_PROGRESS, COMPLETED

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        visitDate = LocalDateTime.now();
        if (status == null) {
            status = EvaluationStatus.IN_PROGRESS;
        }
    }

    public enum EvaluationStatus {
        IN_PROGRESS,
        COMPLETED
    }
}

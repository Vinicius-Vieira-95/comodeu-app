package com.comodeu.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "evidences")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Evidence {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long evaluationId;  // Foreign key para Evaluation

    @Lob
    @Column(columnDefinition = "BYTEA")
    private byte[] photoData;  // Foto em base64 ou arquivo

    @Column(name = "mark_x")
    private Integer markX;

    @Column(name = "mark_y")
    private Integer markY;

    @Column(nullable = false, length = 200)
    private String quickNote;  // Nota rápida durante visita

    @Column(nullable = false, updatable = false)
    private LocalDateTime captureTime;

    @Enumerated(EnumType.STRING)
    private EvidenceStatus status;  // REGISTERED, CLASSIFIED, COMPLETED

    @PrePersist
    protected void onCreate() {
        captureTime = LocalDateTime.now();
        if (status == null) {
            status = EvidenceStatus.REGISTERED;
        }
    }

    public enum EvidenceStatus {
        REGISTERED,
        CLASSIFIED,
        COMPLETED
    }
}

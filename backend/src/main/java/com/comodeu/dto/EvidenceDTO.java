package com.comodeu.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Evidência sem a foto: a imagem é baixada à parte em GET /evidences/{id}/photo,
 * o que deixa as listagens leves.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EvidenceDTO {

    private Long id;
    private Long evaluationId;
    private boolean hasPhoto;
    private Integer markX;
    private Integer markY;
    private String quickNote;
    private LocalDateTime captureTime;
    private String status;  // REGISTERED, CLASSIFIED
}

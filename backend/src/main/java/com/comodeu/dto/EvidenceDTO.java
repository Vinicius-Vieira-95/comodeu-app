package com.comodeu.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EvidenceDTO {

    private Long id;
    private Long evaluationId;
    private String photoDataBase64;  // Photo em base64
    private Integer markX;
    private Integer markY;
    private String quickNote;
    private LocalDateTime captureTime;
    private String status;  // REGISTERED, CLASSIFIED, COMPLETED
}

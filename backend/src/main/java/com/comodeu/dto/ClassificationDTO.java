package com.comodeu.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassificationDTO {

    private Long evidenceId;
    private List<Long> selectedComoItemIds;  // IDs dos itens selecionados
    private String personalAnalysis;
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
class ClassificationResponseDTO {
    private Long id;
    private Long evidenceId;
    private List<ComoItemDTO> selectedItems;
    private String personalAnalysis;
    private LocalDateTime classificationTime;
}

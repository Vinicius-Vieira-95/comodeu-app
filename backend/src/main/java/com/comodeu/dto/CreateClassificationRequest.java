package com.comodeu.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateClassificationRequest(
        @NotNull(message = "evidenceId é obrigatório")
        Long evidenceId,

        @NotNull(message = "comoItemId é obrigatório")
        Long comoItemId,

        @NotBlank(message = "A análise pessoal é obrigatória")
        String personalAnalysis
) {}

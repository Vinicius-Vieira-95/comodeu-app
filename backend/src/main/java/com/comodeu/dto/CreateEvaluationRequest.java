package com.comodeu.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateEvaluationRequest(
        @NotBlank(message = "Nome do visitante é obrigatório")
        @Size(max = 100, message = "Nome do visitante deve ter no máximo 100 caracteres")
        String visitorName,

        @NotBlank(message = "Nome do espaço cultural é obrigatório")
        @Size(max = 200, message = "Nome do espaço deve ter no máximo 200 caracteres")
        String culturalSpaceName,

        @Size(max = 50, message = "Tipo de espaço deve ter no máximo 50 caracteres")
        String spaceType
) {}

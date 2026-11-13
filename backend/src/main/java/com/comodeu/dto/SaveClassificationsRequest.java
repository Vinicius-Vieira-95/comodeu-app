package com.comodeu.dto;

import jakarta.validation.constraints.NotNull;
import java.util.List;

/** Conjunto completo de itens de uma evidência (substitui o anterior). */
public record SaveClassificationsRequest(
        @NotNull(message = "comoItemIds é obrigatório (use [] para remover tudo)")
        List<Long> comoItemIds,

        String personalAnalysis
) {}

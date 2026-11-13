package com.comodeu.service;

import com.comodeu.entity.Classification;
import com.comodeu.entity.Evidence;
import com.comodeu.entity.User;
import com.comodeu.exception.BadRequestException;
import com.comodeu.exception.NotFoundException;
import com.comodeu.repository.ClassificationRepository;
import com.comodeu.repository.ComoItemRepository;
import com.comodeu.security.CurrentUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Classificações de evidências nos itens COMO D'EU.
 *
 * Regra: no máximo UMA classificação por (evidência, item). Salvar de novo
 * atualiza a existente em vez de criar outra.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class ClassificationService {

    private static final int MAX_ANALYSIS_LENGTH = 2000;

    private final ClassificationRepository classificationRepository;
    private final ComoItemRepository comoItemRepository;
    private final EvidenceService evidenceService;
    private final CurrentUserService currentUserService;

    /**
     * Substitui todas as classificações da evidência pelo conjunto informado.
     * Lista vazia remove as classificações e a evidência volta a "REGISTERED".
     */
    public List<Classification> replaceForEvidence(Long evidenceId, List<Long> comoItemIds, String personalAnalysis) {
        evidenceService.getEvidence(evidenceId); // valida acesso
        Set<Long> itemIds = new LinkedHashSet<>(comoItemIds == null ? List.of() : comoItemIds);
        String analysis = normalizeAnalysis(personalAnalysis, !itemIds.isEmpty());
        itemIds.forEach(this::requireItem);

        classificationRepository.deleteByEvidenceId(evidenceId);
        classificationRepository.flush();

        List<Classification> saved = itemIds.stream()
                .map(itemId -> classificationRepository.save(Classification.builder()
                        .evidenceId(evidenceId)
                        .comoItemId(itemId)
                        .personalAnalysis(analysis)
                        .build()))
                .toList();

        evidenceService.setStatus(evidenceId, saved.isEmpty()
                ? Evidence.EvidenceStatus.REGISTERED
                : Evidence.EvidenceStatus.CLASSIFIED);
        return saved;
    }

    /** Cria a classificação, ou atualiza a análise se a evidência já tiver esse item. */
    public Classification createOrUpdate(Long evidenceId, Long comoItemId, String personalAnalysis) {
        evidenceService.getEvidence(evidenceId); // valida acesso
        requireItem(comoItemId);
        String analysis = normalizeAnalysis(personalAnalysis, true);

        Classification classification = classificationRepository
                .findFirstByEvidenceIdAndComoItemId(evidenceId, comoItemId)
                .orElseGet(() -> Classification.builder().evidenceId(evidenceId).comoItemId(comoItemId).build());
        classification.setPersonalAnalysis(analysis);
        Classification saved = classificationRepository.save(classification);

        evidenceService.setStatus(evidenceId, Evidence.EvidenceStatus.CLASSIFIED);
        return saved;
    }

    @Transactional(readOnly = true)
    public List<Classification> getByEvidence(Long evidenceId) {
        evidenceService.getEvidence(evidenceId); // valida acesso
        return classificationRepository.findByEvidenceIdOrderByIdAsc(evidenceId);
    }

    @Transactional(readOnly = true)
    public List<Classification> getByItem(Long comoItemId) {
        requireItem(comoItemId);
        User user = currentUserService.get();
        return CurrentUserService.isAdmin(user)
                ? classificationRepository.findByComoItemId(comoItemId)
                : classificationRepository.findByComoItemIdAndOwner(comoItemId, user.getId());
    }

    @Transactional(readOnly = true)
    public Classification get(Long id) {
        Classification classification = classificationRepository.findById(id)
                .orElseThrow(() -> notFound(id));
        try {
            evidenceService.getEvidence(classification.getEvidenceId());
        } catch (NotFoundException e) {
            throw notFound(id);
        }
        return classification;
    }

    public void delete(Long id) {
        Classification classification = get(id);
        classificationRepository.delete(classification);
        classificationRepository.flush();
        if (classificationRepository.findByEvidenceIdOrderByIdAsc(classification.getEvidenceId()).isEmpty()) {
            evidenceService.setStatus(classification.getEvidenceId(), Evidence.EvidenceStatus.REGISTERED);
        }
    }

    private void requireItem(Long comoItemId) {
        if (comoItemId == null || !comoItemRepository.existsById(comoItemId)) {
            throw new NotFoundException("Item COMO D'EU não encontrado: " + comoItemId);
        }
    }

    private static String normalizeAnalysis(String analysis, boolean required) {
        String value = analysis == null ? "" : analysis.trim();
        if (required && value.isEmpty()) {
            throw new BadRequestException("A análise pessoal é obrigatória");
        }
        if (value.length() > MAX_ANALYSIS_LENGTH) {
            throw new BadRequestException("A análise deve ter no máximo " + MAX_ANALYSIS_LENGTH + " caracteres");
        }
        return value;
    }

    private static NotFoundException notFound(Long id) {
        return new NotFoundException("Classificação não encontrada: " + id);
    }
}

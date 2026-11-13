package com.comodeu.service;

import com.comodeu.dto.EvidenceDTO;
import com.comodeu.entity.Evaluation;
import com.comodeu.entity.Evidence;
import com.comodeu.exception.BadRequestException;
import com.comodeu.exception.NotFoundException;
import com.comodeu.repository.ClassificationRepository;
import com.comodeu.repository.EvidenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Evidências (foto + marcação + nota). O acesso segue o dono da avaliação:
 * se o usuário não pode ver a avaliação, a evidência responde 404.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class EvidenceService {

    private static final int MAX_NOTE_LENGTH = 200;

    private final EvidenceRepository evidenceRepository;
    private final ClassificationRepository classificationRepository;
    private final EvaluationService evaluationService;
    private final PhotoStorageService photoStorageService;

    public EvidenceDTO registerEvidence(Long evaluationId, byte[] photo, Integer markX, Integer markY, String quickNote) {
        Evaluation evaluation = evaluationService.getEvaluation(evaluationId);
        if (evaluation.getStatus() == Evaluation.EvaluationStatus.COMPLETED) {
            throw new BadRequestException("Avaliação já concluída: não é possível adicionar evidências");
        }
        if (quickNote == null || quickNote.isBlank()) {
            throw new BadRequestException("A nota rápida é obrigatória");
        }
        if (quickNote.trim().length() > MAX_NOTE_LENGTH) {
            throw new BadRequestException("A nota rápida deve ter no máximo " + MAX_NOTE_LENGTH + " caracteres");
        }

        String photoPath = photoStorageService.save(photo);
        photoStorageService.deleteOnRollback(photoPath); // não deixa arquivo órfão se o banco falhar
        Evidence evidence = Evidence.builder()
                .evaluationId(evaluationId)
                .photoPath(photoPath)
                .markX(markX)
                .markY(markY)
                .quickNote(quickNote.trim())
                .status(Evidence.EvidenceStatus.REGISTERED)
                .build();
        return toDTO(evidenceRepository.save(evidence));
    }

    @Transactional(readOnly = true)
    public List<EvidenceDTO> getEvidencesByEvaluation(Long evaluationId) {
        evaluationService.getEvaluation(evaluationId); // valida acesso
        return evidenceRepository.findByEvaluationIdOrderByCaptureTimeAsc(evaluationId).stream()
                .map(this::toDTO)
                .toList();
    }

    /** Busca uma evidência que o usuário atual pode acessar (senão, 404). */
    @Transactional(readOnly = true)
    public Evidence getEvidence(Long id) {
        Evidence evidence = evidenceRepository.findById(id)
                .orElseThrow(() -> notFound(id));
        try {
            evaluationService.getEvaluation(evidence.getEvaluationId());
        } catch (NotFoundException e) {
            throw notFound(id);
        }
        return evidence;
    }

    @Transactional(readOnly = true)
    public EvidenceDTO getEvidenceDTO(Long id) {
        return toDTO(getEvidence(id));
    }

    @Transactional(readOnly = true)
    public byte[] getPhoto(Evidence evidence) {
        if (evidence.getPhotoPath() == null) {
            throw new NotFoundException("Evidência sem foto");
        }
        return photoStorageService.load(evidence.getPhotoPath());
    }

    public EvidenceDTO setStatus(Long id, Evidence.EvidenceStatus status) {
        Evidence evidence = getEvidence(id);
        evidence.setStatus(status);
        return toDTO(evidenceRepository.save(evidence));
    }

    public void deleteEvidence(Long id) {
        Evidence evidence = getEvidence(id);
        classificationRepository.deleteByEvidenceId(id);
        evidenceRepository.delete(evidence);
        photoStorageService.deleteAfterCommit(evidence.getPhotoPath());
    }

    public EvidenceDTO toDTO(Evidence evidence) {
        return EvidenceDTO.builder()
                .id(evidence.getId())
                .evaluationId(evidence.getEvaluationId())
                .hasPhoto(evidence.getPhotoPath() != null)
                .markX(evidence.getMarkX())
                .markY(evidence.getMarkY())
                .quickNote(evidence.getQuickNote())
                .captureTime(evidence.getCaptureTime())
                .status(evidence.getStatus().toString())
                .build();
    }

    private static NotFoundException notFound(Long id) {
        return new NotFoundException("Evidência não encontrada: " + id);
    }
}

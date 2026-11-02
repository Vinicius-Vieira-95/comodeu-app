package com.comodeu.service;

import com.comodeu.entity.Evidence;
import com.comodeu.entity.Classification;
import com.comodeu.dto.EvidenceDTO;
import com.comodeu.repository.EvidenceRepository;
import com.comodeu.repository.ClassificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Base64;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class EvidenceService {

    private final EvidenceRepository evidenceRepository;
    private final ClassificationRepository classificationRepository;

    public Evidence registerEvidence(Long evaluationId, String photoBase64, Integer markX, Integer markY, String quickNote) {
        byte[] photoData = photoBase64 != null ? Base64.getDecoder().decode(photoBase64) : null;

        Evidence evidence = Evidence.builder()
                .evaluationId(evaluationId)
                .photoData(photoData)
                .markX(markX)
                .markY(markY)
                .quickNote(quickNote)
                .status(Evidence.EvidenceStatus.REGISTERED)
                .build();

        return evidenceRepository.save(evidence);
    }

    public List<EvidenceDTO> getEvidencesByEvaluation(Long evaluationId) {
        return evidenceRepository.findByEvaluationId(evaluationId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public Evidence getEvidence(Long id) {
        return evidenceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Evidência não encontrada: " + id));
    }

    public Evidence classifyEvidence(Long evidenceId) {
        Evidence evidence = getEvidence(evidenceId);
        evidence.setStatus(Evidence.EvidenceStatus.CLASSIFIED);
        return evidenceRepository.save(evidence);
    }

    public void deleteEvidence(Long id) {
        Evidence evidence = getEvidence(id);

        // Delete associated classifications
        classificationRepository.findByEvidenceId(id)
                .forEach(classificationRepository::delete);

        // Delete evidence
        evidenceRepository.delete(evidence);
    }

    private EvidenceDTO convertToDTO(Evidence evidence) {
        String photoBase64 = null;
        if (evidence.getPhotoData() != null) {
            photoBase64 = Base64.getEncoder().encodeToString(evidence.getPhotoData());
        }

        return EvidenceDTO.builder()
                .id(evidence.getId())
                .evaluationId(evidence.getEvaluationId())
                .photoDataBase64(photoBase64)
                .markX(evidence.getMarkX())
                .markY(evidence.getMarkY())
                .quickNote(evidence.getQuickNote())
                .captureTime(evidence.getCaptureTime())
                .status(evidence.getStatus().toString())
                .build();
    }
}

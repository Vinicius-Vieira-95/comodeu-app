package com.comodeu.service;

import com.comodeu.entity.Evaluation;
import com.comodeu.repository.EvaluationRepository;
import com.comodeu.repository.EvidenceRepository;
import com.comodeu.repository.ClassificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class EvaluationService {

    private final EvaluationRepository evaluationRepository;
    private final EvidenceRepository evidenceRepository;
    private final ClassificationRepository classificationRepository;

    public Evaluation createEvaluation(String visitorName, String culturalSpaceName, String spaceType) {
        Evaluation evaluation = Evaluation.builder()
                .visitorName(visitorName)
                .culturalSpaceName(culturalSpaceName)
                .spaceType(spaceType)
                .status(Evaluation.EvaluationStatus.IN_PROGRESS)
                .build();

        return evaluationRepository.save(evaluation);
    }

    public Evaluation getEvaluation(Long id) {
        return evaluationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Avaliação não encontrada: " + id));
    }

    public List<Evaluation> getAllEvaluations() {
        return evaluationRepository.findAll();
    }

    public List<Evaluation> getInProgressEvaluations() {
        return evaluationRepository.findByStatus(Evaluation.EvaluationStatus.IN_PROGRESS);
    }

    public Evaluation completeEvaluation(Long id) {
        Evaluation evaluation = getEvaluation(id);
        evaluation.setStatus(Evaluation.EvaluationStatus.COMPLETED);
        evaluation.setCompletedAt(LocalDateTime.now());
        return evaluationRepository.save(evaluation);
    }

    public void deleteEvaluation(Long id) {
        // Delete related data first
        evidenceRepository.findByEvaluationId(id).forEach(evidence -> {
            classificationRepository.findByEvidenceId(evidence.getId()).forEach(classificationRepository::delete);
            evidenceRepository.delete(evidence);
        });

        evaluationRepository.deleteById(id);
    }
}

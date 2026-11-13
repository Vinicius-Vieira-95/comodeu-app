package com.comodeu.service;

import com.comodeu.entity.Evaluation;
import com.comodeu.entity.Evidence;
import com.comodeu.entity.User;
import com.comodeu.exception.NotFoundException;
import com.comodeu.repository.ClassificationRepository;
import com.comodeu.repository.EvaluationRepository;
import com.comodeu.repository.EvidenceRepository;
import com.comodeu.security.CurrentUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

/**
 * Avaliações. Cada usuário só enxerga e altera as próprias; ADMIN enxerga todas
 * (inclusive as antigas, sem dono). Uma avaliação de outro usuário responde 404,
 * para não revelar que ela existe.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class EvaluationService {

    private final EvaluationRepository evaluationRepository;
    private final EvidenceRepository evidenceRepository;
    private final ClassificationRepository classificationRepository;
    private final PhotoStorageService photoStorageService;
    private final CurrentUserService currentUserService;

    public Evaluation createEvaluation(String visitorName, String culturalSpaceName, String spaceType) {
        Evaluation evaluation = Evaluation.builder()
                .ownerId(currentUserService.get().getId())
                .visitorName(visitorName.trim())
                .culturalSpaceName(culturalSpaceName.trim())
                .spaceType(spaceType)
                .status(Evaluation.EvaluationStatus.IN_PROGRESS)
                .build();
        return evaluationRepository.save(evaluation);
    }

    /** Busca uma avaliação que o usuário atual pode acessar (senão, 404). */
    @Transactional(readOnly = true)
    public Evaluation getEvaluation(Long id) {
        Evaluation evaluation = evaluationRepository.findById(id)
                .orElseThrow(() -> notFound(id));
        User user = currentUserService.get();
        if (!CurrentUserService.isAdmin(user) && !Objects.equals(evaluation.getOwnerId(), user.getId())) {
            throw notFound(id);
        }
        return evaluation;
    }

    @Transactional(readOnly = true)
    public List<Evaluation> getAllEvaluations() {
        User user = currentUserService.get();
        return CurrentUserService.isAdmin(user)
                ? evaluationRepository.findAllByOrderByCreatedAtDesc()
                : evaluationRepository.findByOwnerIdOrderByCreatedAtDesc(user.getId());
    }

    @Transactional(readOnly = true)
    public List<Evaluation> getInProgressEvaluations() {
        User user = currentUserService.get();
        Evaluation.EvaluationStatus status = Evaluation.EvaluationStatus.IN_PROGRESS;
        return CurrentUserService.isAdmin(user)
                ? evaluationRepository.findByStatusOrderByCreatedAtDesc(status)
                : evaluationRepository.findByOwnerIdAndStatusOrderByCreatedAtDesc(user.getId(), status);
    }

    public Evaluation completeEvaluation(Long id) {
        Evaluation evaluation = getEvaluation(id);
        evaluation.setStatus(Evaluation.EvaluationStatus.COMPLETED);
        evaluation.setCompletedAt(LocalDateTime.now());
        return evaluationRepository.save(evaluation);
    }

    public void deleteEvaluation(Long id) {
        Evaluation evaluation = getEvaluation(id);
        for (Evidence evidence : evidenceRepository.findByEvaluationIdOrderByCaptureTimeAsc(id)) {
            classificationRepository.deleteByEvidenceId(evidence.getId());
            evidenceRepository.delete(evidence);
            photoStorageService.deleteAfterCommit(evidence.getPhotoPath());
        }
        evaluationRepository.delete(evaluation);
    }

    private static NotFoundException notFound(Long id) {
        return new NotFoundException("Avaliação não encontrada: " + id);
    }
}

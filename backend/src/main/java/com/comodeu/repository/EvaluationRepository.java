package com.comodeu.repository;

import com.comodeu.entity.Evaluation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface EvaluationRepository extends JpaRepository<Evaluation, Long> {
    List<Evaluation> findAllByOrderByCreatedAtDesc();
    List<Evaluation> findByOwnerIdOrderByCreatedAtDesc(Long ownerId);
    List<Evaluation> findByStatusOrderByCreatedAtDesc(Evaluation.EvaluationStatus status);
    List<Evaluation> findByOwnerIdAndStatusOrderByCreatedAtDesc(Long ownerId, Evaluation.EvaluationStatus status);
}

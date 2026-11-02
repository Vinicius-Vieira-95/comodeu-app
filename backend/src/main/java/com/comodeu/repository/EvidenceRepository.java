package com.comodeu.repository;

import com.comodeu.entity.Evidence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface EvidenceRepository extends JpaRepository<Evidence, Long> {
    List<Evidence> findByEvaluationId(Long evaluationId);
    List<Evidence> findByEvaluationIdAndStatus(Long evaluationId, Evidence.EvidenceStatus status);
}

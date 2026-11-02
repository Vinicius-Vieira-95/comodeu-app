package com.comodeu.repository;

import com.comodeu.entity.Classification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ClassificationRepository extends JpaRepository<Classification, Long> {
    List<Classification> findByEvidenceId(Long evidenceId);
    List<Classification> findByComoItemId(Long comoItemId);
}

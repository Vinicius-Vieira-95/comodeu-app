package com.comodeu.repository;

import com.comodeu.entity.Evidence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface EvidenceRepository extends JpaRepository<Evidence, Long> {
    List<Evidence> findByEvaluationIdOrderByCaptureTimeAsc(Long evaluationId);

    /** IDs das evidências que ainda têm a foto no banco (formato antigo). */
    @Query("select e.id from Evidence e where e.photoData is not null")
    List<Long> findIdsWithLegacyPhotoData();
}

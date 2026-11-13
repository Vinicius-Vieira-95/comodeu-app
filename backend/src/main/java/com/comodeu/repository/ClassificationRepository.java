package com.comodeu.repository;

import com.comodeu.entity.Classification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ClassificationRepository extends JpaRepository<Classification, Long> {
    List<Classification> findByEvidenceIdOrderByIdAsc(Long evidenceId);
    List<Classification> findByComoItemId(Long comoItemId);
    Optional<Classification> findFirstByEvidenceIdAndComoItemId(Long evidenceId, Long comoItemId);
    void deleteByEvidenceId(Long evidenceId);

    /** Classificações de um item, só das avaliações de um usuário. */
    @Query("""
            select c from Classification c, Evidence e, Evaluation v
            where c.evidenceId = e.id and e.evaluationId = v.id
              and c.comoItemId = :comoItemId and v.ownerId = :ownerId
            """)
    List<Classification> findByComoItemIdAndOwner(@Param("comoItemId") Long comoItemId,
                                                  @Param("ownerId") Long ownerId);
}

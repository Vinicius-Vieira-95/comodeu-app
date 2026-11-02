package com.comodeu.repository;

import com.comodeu.entity.ComoItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ComoItemRepository extends JpaRepository<ComoItem, Long> {
    List<ComoItem> findByCategory(String category);
    ComoItem findByItemNumber(Integer itemNumber);
}

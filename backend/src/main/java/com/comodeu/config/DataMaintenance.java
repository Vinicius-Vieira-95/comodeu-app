package com.comodeu.config;

import com.comodeu.entity.Classification;
import com.comodeu.entity.Evidence;
import com.comodeu.repository.ClassificationRepository;
import com.comodeu.repository.EvidenceRepository;
import com.comodeu.service.PhotoStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Ajustes automáticos de dados antigos, executados a cada inicialização (idempotente):
 *
 * 1. Fotos legadas: evidências com a foto gravada no banco (coluna photo_data)
 *    têm a imagem movida para a pasta de fotos e a coluna limpa.
 * 2. Classificações duplicadas: para cada (evidência, item) repetido, mantém
 *    só a mais recente.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DataMaintenance implements ApplicationRunner {

    private final EvidenceRepository evidenceRepository;
    private final ClassificationRepository classificationRepository;
    private final PhotoStorageService photoStorageService;
    private final TransactionTemplate transactionTemplate;

    @Override
    public void run(ApplicationArguments args) {
        migrateLegacyPhotos();
        removeDuplicateClassifications();
    }

    private void migrateLegacyPhotos() {
        List<Long> ids = evidenceRepository.findIdsWithLegacyPhotoData();
        if (ids.isEmpty()) {
            return;
        }
        log.info("Migrando {} foto(s) do banco para arquivos...", ids.size());
        int migrated = 0;
        for (Long id : ids) {
            try {
                // Uma transação por evidência: um erro não desfaz as já migradas.
                Boolean ok = transactionTemplate.execute(status -> {
                    Evidence evidence = evidenceRepository.findById(id).orElse(null);
                    if (evidence == null || evidence.getPhotoData() == null) {
                        return false;
                    }
                    if (evidence.getPhotoPath() == null) {
                        String filename = photoStorageService.save(evidence.getPhotoData());
                        photoStorageService.deleteOnRollback(filename);
                        evidence.setPhotoPath(filename);
                    }
                    evidence.setPhotoData(null);
                    evidenceRepository.save(evidence);
                    return true;
                });
                if (Boolean.TRUE.equals(ok)) {
                    migrated++;
                }
            } catch (RuntimeException e) {
                log.warn("Não foi possível migrar a foto da evidência {}: {}", id, e.getMessage());
            }
        }
        log.info("Fotos migradas: {} de {}", migrated, ids.size());
    }

    private void removeDuplicateClassifications() {
        Integer removed = transactionTemplate.execute(status -> {
            Map<String, List<Classification>> groups = classificationRepository.findAll().stream()
                    .collect(Collectors.groupingBy(c -> c.getEvidenceId() + ":" + c.getComoItemId()));
            List<Classification> duplicates = new ArrayList<>();
            for (List<Classification> group : groups.values()) {
                if (group.size() > 1) {
                    group.sort(Comparator.comparing(Classification::getId).reversed());
                    duplicates.addAll(group.subList(1, group.size())); // mantém a mais recente
                }
            }
            classificationRepository.deleteAll(duplicates);
            return duplicates.size();
        });
        if (removed != null && removed > 0) {
            log.info("Classificações duplicadas removidas: {}", removed);
        }
    }
}

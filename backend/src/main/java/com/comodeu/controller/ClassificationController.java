package com.comodeu.controller;

import com.comodeu.entity.Classification;
import com.comodeu.repository.ClassificationRepository;
import com.comodeu.repository.ComoItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/classifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ClassificationController {

    private final ClassificationRepository classificationRepository;
    private final ComoItemRepository comoItemRepository;

    @PostMapping
    public ResponseEntity<Classification> createClassification(
            @RequestBody Map<String, Object> request) {

        Long evidenceId = Long.parseLong(request.get("evidenceId").toString());
        Long comoItemId = Long.parseLong(request.get("comoItemId").toString());
        String personalAnalysis = (String) request.get("personalAnalysis");

        // Validar que o item existe
        comoItemRepository.findById(comoItemId)
                .orElseThrow(() -> new RuntimeException("Item COMO D'EU não encontrado"));

        Classification classification = Classification.builder()
                .evidenceId(evidenceId)
                .comoItemId(comoItemId)
                .personalAnalysis(personalAnalysis)
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(classificationRepository.save(classification));
    }

    @GetMapping("/evidence/{evidenceId}")
    public ResponseEntity<List<Classification>> getClassificationsByEvidence(@PathVariable Long evidenceId) {
        return ResponseEntity.ok(classificationRepository.findByEvidenceId(evidenceId));
    }

    @GetMapping("/item/{comoItemId}")
    public ResponseEntity<List<Classification>> getClassificationsByItem(@PathVariable Long comoItemId) {
        return ResponseEntity.ok(classificationRepository.findByComoItemId(comoItemId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Classification> getClassification(@PathVariable Long id) {
        return ResponseEntity.ok(classificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Classificação não encontrada")));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteClassification(@PathVariable Long id) {
        classificationRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

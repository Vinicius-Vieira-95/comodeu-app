package com.comodeu.controller;

import com.comodeu.dto.CreateClassificationRequest;
import com.comodeu.entity.Classification;
import com.comodeu.service.ClassificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Classificações avulsas. Para salvar a classificação completa de uma evidência,
 * prefira PUT /evidences/{id}/classifications.
 */
@RestController
@RequestMapping("/classifications")
@RequiredArgsConstructor
public class ClassificationController {

    private final ClassificationService classificationService;

    /** Cria; se a evidência já tiver esse item, só atualiza a análise (não duplica). */
    @PostMapping
    public ResponseEntity<Classification> createClassification(@Valid @RequestBody CreateClassificationRequest request) {
        Classification classification = classificationService.createOrUpdate(
                request.evidenceId(), request.comoItemId(), request.personalAnalysis());
        return ResponseEntity.status(HttpStatus.CREATED).body(classification);
    }

    @GetMapping("/evidence/{evidenceId}")
    public ResponseEntity<List<Classification>> getClassificationsByEvidence(@PathVariable Long evidenceId) {
        return ResponseEntity.ok(classificationService.getByEvidence(evidenceId));
    }

    @GetMapping("/item/{comoItemId}")
    public ResponseEntity<List<Classification>> getClassificationsByItem(@PathVariable Long comoItemId) {
        return ResponseEntity.ok(classificationService.getByItem(comoItemId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Classification> getClassification(@PathVariable Long id) {
        return ResponseEntity.ok(classificationService.get(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteClassification(@PathVariable Long id) {
        classificationService.delete(id);
        return ResponseEntity.noContent().build();
    }
}

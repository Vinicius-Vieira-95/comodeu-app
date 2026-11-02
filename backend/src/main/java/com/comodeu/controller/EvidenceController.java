package com.comodeu.controller;

import com.comodeu.entity.Evidence;
import com.comodeu.dto.EvidenceDTO;
import com.comodeu.service.EvidenceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/evidences")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class EvidenceController {

    private final EvidenceService evidenceService;

    @PostMapping
    public ResponseEntity<Evidence> registerEvidence(
            @RequestBody Map<String, Object> request) {

        Long evaluationId = Long.parseLong(request.get("evaluationId").toString());
        String photoBase64 = (String) request.get("photoBase64");
        Integer markX = request.get("markX") != null ? Integer.parseInt(request.get("markX").toString()) : null;
        Integer markY = request.get("markY") != null ? Integer.parseInt(request.get("markY").toString()) : null;
        String quickNote = (String) request.get("quickNote");

        Evidence evidence = evidenceService.registerEvidence(evaluationId, photoBase64, markX, markY, quickNote);
        return ResponseEntity.status(HttpStatus.CREATED).body(evidence);
    }

    @GetMapping("/evaluation/{evaluationId}")
    public ResponseEntity<List<EvidenceDTO>> getEvidencesByEvaluation(@PathVariable Long evaluationId) {
        return ResponseEntity.ok(evidenceService.getEvidencesByEvaluation(evaluationId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<EvidenceDTO> getEvidence(@PathVariable Long id) {
        Evidence evidence = evidenceService.getEvidence(id);
        return ResponseEntity.ok(convertToDTO(evidence));
    }

    @PutMapping("/{id}/classify")
    public ResponseEntity<Evidence> classifyEvidence(@PathVariable Long id) {
        return ResponseEntity.ok(evidenceService.classifyEvidence(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvidence(@PathVariable Long id) {
        evidenceService.deleteEvidence(id);
        return ResponseEntity.noContent().build();
    }

    private EvidenceDTO convertToDTO(Evidence evidence) {
        String photoBase64 = null;
        if (evidence.getPhotoData() != null) {
            photoBase64 = java.util.Base64.getEncoder().encodeToString(evidence.getPhotoData());
        }

        return EvidenceDTO.builder()
                .id(evidence.getId())
                .evaluationId(evidence.getEvaluationId())
                .photoDataBase64(photoBase64)
                .markX(evidence.getMarkX())
                .markY(evidence.getMarkY())
                .quickNote(evidence.getQuickNote())
                .captureTime(evidence.getCaptureTime())
                .status(evidence.getStatus().toString())
                .build();
    }
}

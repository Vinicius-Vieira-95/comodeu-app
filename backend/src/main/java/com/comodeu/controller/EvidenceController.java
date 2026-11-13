package com.comodeu.controller;

import com.comodeu.dto.EvidenceDTO;
import com.comodeu.dto.SaveClassificationsRequest;
import com.comodeu.entity.Classification;
import com.comodeu.entity.Evidence;
import com.comodeu.exception.BadRequestException;
import com.comodeu.service.ClassificationService;
import com.comodeu.service.EvidenceService;
import com.comodeu.service.PhotoStorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.Duration;
import java.util.List;

/** Evidências: registro com upload da foto, download da foto e classificações. */
@RestController
@RequestMapping("/evidences")
@RequiredArgsConstructor
public class EvidenceController {

    private final EvidenceService evidenceService;
    private final ClassificationService classificationService;

    /**
     * Registra uma evidência. Envio em multipart/form-data:
     * evaluationId, quickNote, markX (opcional), markY (opcional) e o arquivo "photo".
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<EvidenceDTO> registerEvidence(
            @RequestParam Long evaluationId,
            @RequestParam String quickNote,
            @RequestParam(required = false) Integer markX,
            @RequestParam(required = false) Integer markY,
            @RequestPart("photo") MultipartFile photo) {
        if (photo.isEmpty()) {
            throw new BadRequestException("A foto é obrigatória");
        }
        byte[] bytes;
        try {
            bytes = photo.getBytes();
        } catch (IOException e) {
            throw new UncheckedIOException("Erro ao ler a foto enviada", e);
        }
        EvidenceDTO evidence = evidenceService.registerEvidence(evaluationId, bytes, markX, markY, quickNote);
        return ResponseEntity.status(HttpStatus.CREATED).body(evidence);
    }

    @GetMapping("/evaluation/{evaluationId}")
    public ResponseEntity<List<EvidenceDTO>> getEvidencesByEvaluation(@PathVariable Long evaluationId) {
        return ResponseEntity.ok(evidenceService.getEvidencesByEvaluation(evaluationId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<EvidenceDTO> getEvidence(@PathVariable Long id) {
        return ResponseEntity.ok(evidenceService.getEvidenceDTO(id));
    }

    /** Bytes da imagem. A foto de uma evidência nunca muda, então pode ficar em cache no cliente. */
    @GetMapping("/{id}/photo")
    public ResponseEntity<byte[]> getPhoto(@PathVariable Long id) {
        Evidence evidence = evidenceService.getEvidence(id);
        byte[] bytes = evidenceService.getPhoto(evidence);
        return ResponseEntity.ok()
                .contentType(PhotoStorageService.mediaTypeOf(evidence.getPhotoPath()))
                .cacheControl(CacheControl.maxAge(Duration.ofDays(7)).cachePrivate())
                .body(bytes);
    }

    @GetMapping("/{id}/classifications")
    public ResponseEntity<List<Classification>> getClassifications(@PathVariable Long id) {
        return ResponseEntity.ok(classificationService.getByEvidence(id));
    }

    /**
     * Salva a classificação completa da evidência: substitui os itens anteriores
     * (não cria duplicados). Lista vazia remove a classificação.
     */
    @PutMapping("/{id}/classifications")
    public ResponseEntity<List<Classification>> saveClassifications(
            @PathVariable Long id, @Valid @RequestBody SaveClassificationsRequest request) {
        return ResponseEntity.ok(classificationService.replaceForEvidence(
                id, request.comoItemIds(), request.personalAnalysis()));
    }

    @PutMapping("/{id}/classify")
    public ResponseEntity<EvidenceDTO> classifyEvidence(@PathVariable Long id) {
        return ResponseEntity.ok(evidenceService.setStatus(id, Evidence.EvidenceStatus.CLASSIFIED));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvidence(@PathVariable Long id) {
        evidenceService.deleteEvidence(id);
        return ResponseEntity.noContent().build();
    }
}

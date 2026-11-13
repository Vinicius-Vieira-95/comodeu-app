package com.comodeu.controller;

import com.comodeu.dto.CreateEvaluationRequest;
import com.comodeu.entity.Evaluation;
import com.comodeu.service.EvaluationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Avaliações do usuário logado (ADMIN vê todas). */
@RestController
@RequestMapping("/evaluations")
@RequiredArgsConstructor
public class EvaluationController {

    private final EvaluationService evaluationService;

    @PostMapping
    public ResponseEntity<Evaluation> createEvaluation(@Valid @RequestBody CreateEvaluationRequest request) {
        Evaluation evaluation = evaluationService.createEvaluation(
                request.visitorName(), request.culturalSpaceName(), request.spaceType());
        return ResponseEntity.status(HttpStatus.CREATED).body(evaluation);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Evaluation> getEvaluation(@PathVariable Long id) {
        return ResponseEntity.ok(evaluationService.getEvaluation(id));
    }

    @GetMapping
    public ResponseEntity<List<Evaluation>> getAllEvaluations() {
        return ResponseEntity.ok(evaluationService.getAllEvaluations());
    }

    @GetMapping("/status/in-progress")
    public ResponseEntity<List<Evaluation>> getInProgressEvaluations() {
        return ResponseEntity.ok(evaluationService.getInProgressEvaluations());
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<Evaluation> completeEvaluation(@PathVariable Long id) {
        return ResponseEntity.ok(evaluationService.completeEvaluation(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEvaluation(@PathVariable Long id) {
        evaluationService.deleteEvaluation(id);
        return ResponseEntity.noContent().build();
    }
}

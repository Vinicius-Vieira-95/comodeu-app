package com.comodeu.controller;

import com.comodeu.entity.ComoItem;
import com.comodeu.service.ComoItemService;
import com.comodeu.service.SuggestionService;
import com.comodeu.dto.ComoItemDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/como-items")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ComoItemController {

    private final ComoItemService comoItemService;
    private final SuggestionService suggestionService;

    @PostMapping("/initialize")
    public ResponseEntity<String> initializeItems() {
        comoItemService.initializeComoItems();
        return ResponseEntity.ok("Itens COMO D'EU inicializados com sucesso!");
    }

    @GetMapping
    public ResponseEntity<List<ComoItemDTO>> getAllItems() {
        List<ComoItem> items = comoItemService.getAllItems();
        List<ComoItemDTO> dtos = items.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ComoItemDTO> getItem(@PathVariable Long id) {
        ComoItem item = comoItemService.getItem(id);
        return ResponseEntity.ok(convertToDTO(item));
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<List<ComoItemDTO>> getItemsByCategory(@PathVariable String category) {
        List<ComoItem> items = comoItemService.getItemsByCategory(category);
        List<ComoItemDTO> dtos = items.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @PostMapping("/suggest")
    public ResponseEntity<List<ComoItemDTO>> suggestItems(@RequestBody Map<String, String> request) {
        String quickNote = request.get("quickNote");
        List<ComoItem> suggestions = suggestionService.suggestItems(quickNote);
        List<ComoItemDTO> dtos = suggestions.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    private ComoItemDTO convertToDTO(ComoItem item) {
        return ComoItemDTO.builder()
                .id(item.getId())
                .itemNumber(item.getItemNumber())
                .name(item.getName())
                .description(item.getDescription())
                .category(item.getCategory())
                .keywords(item.getKeywords())
                .build();
    }
}

package com.comodeu.service;

import com.comodeu.entity.ComoItem;
import com.comodeu.repository.ComoItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SuggestionService {

    private final ComoItemRepository comoItemRepository;

    /**
     * Sugere itens COMO D'EU baseado em keywords da nota rápida
     * Retorna os top 3 itens mais relevantes
     */
    public List<ComoItem> suggestItems(String quickNote) {
        if (quickNote == null || quickNote.isEmpty()) {
            return new ArrayList<>();
        }

        String[] words = quickNote.toLowerCase().split("\\s+");
        Map<ComoItem, Integer> itemScores = new HashMap<>();

        List<ComoItem> allItems = comoItemRepository.findAll();

        for (ComoItem item : allItems) {
            int score = calculateScore(item, words);
            if (score > 0) {
                itemScores.put(item, score);
            }
        }

        // Ordenar por score decrescente e retornar top 3
        return itemScores.entrySet().stream()
                .sorted((e1, e2) -> e2.getValue().compareTo(e1.getValue()))
                .limit(3)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());
    }

    /**
     * Calcula score de relevância para um item baseado em keywords
     */
    private int calculateScore(ComoItem item, String[] words) {
        if (item.getKeywords() == null || item.getKeywords().isEmpty()) {
            return 0;
        }

        String[] itemKeywords = item.getKeywords().toLowerCase().split(",");
        int score = 0;

        for (String word : words) {
            String cleanWord = word.replaceAll("[.,!?]", "");
            for (String keyword : itemKeywords) {
                String cleanKeyword = keyword.trim();

                // Correspondência exata
                if (cleanWord.equals(cleanKeyword)) {
                    score += 5;
                }
                // Contém a palavra
                else if (cleanKeyword.contains(cleanWord) && cleanWord.length() > 2) {
                    score += 2;
                }
            }
        }

        return score;
    }
}

package com.comodeu.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ComoItemDTO {

    private Long id;
    private Integer itemNumber;
    private String name;
    private String description;
    private String category;
    private String keywords;
}

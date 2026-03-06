package com.webtruyenapi.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class ComicSummaryDTO {

    private String comicId;
    private String name;
    private String thumbUrl;
    private String chaptersLatest;
    private LocalDateTime updatedAt;

}
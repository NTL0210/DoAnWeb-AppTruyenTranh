package com.webtruyenapi.dto;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class ComicDetailDTO {

    private String comicId;
    private String name;
    private String slug;
    private String originName;
    private String status;
    private String thumbUrl;
    private String chaptersLatest;
    private LocalDateTime updatedAt;

    private List<ChapterDTO> chapters;

}

package com.webtruyenapi.dto;


import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ChapterDTO {

    private Integer id;
    private String chapterName;
    private String chapterTitle;
    private Integer chapterIndex;

}
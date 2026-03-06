package com.webtruyenapi.controller;

import com.webtruyenapi.entity.Chapter;
import com.webtruyenapi.repository.ChapterRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping(value = "/api/Chapters")
@Slf4j
public class ChapterController {
    private final ChapterRepository chapterRepository;

    public ChapterController(ChapterRepository chapterRepository) {
        this.chapterRepository = chapterRepository;
    }

    @GetMapping(value = "/Comic/{comicId}")
    public ResponseEntity<List<Chapter>> getChaptersByComicId(@PathVariable String comicId) {
        List<Chapter> chapters = chapterRepository.findByComicIdOrderByChapterIndexAsc(comicId);
        return ResponseEntity.ok(chapters);
    }
}

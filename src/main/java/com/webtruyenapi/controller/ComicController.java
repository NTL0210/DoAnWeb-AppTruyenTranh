//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by FernFlower decompiler)
//

package com.webtruyenapi.controller;

import com.webtruyenapi.dto.ChapterDTO;
import com.webtruyenapi.dto.ComicDetailDTO;
import com.webtruyenapi.dto.ComicSummaryDTO;
import com.webtruyenapi.entity.Comic;
import com.webtruyenapi.repository.ChapterRepository;
import com.webtruyenapi.repository.ComicRepository;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping({"/api/Comics"})
public class ComicController {
    private static final Logger log = LoggerFactory.getLogger(ComicController.class);
    private final ComicRepository comicRepository;
    private final ChapterRepository chapterRepository;
    private static final int PAGE_SIZE = 20;

    public ComicController(ComicRepository comicRepository, ChapterRepository chapterRepository) {
        this.comicRepository = comicRepository;
        this.chapterRepository = chapterRepository;
    }

    @GetMapping({"/page"})
    public ResponseEntity<Page<ComicSummaryDTO>> getComicsByPage(@RequestParam(defaultValue = "1") int page) {
        Pageable pageable = PageRequest.of(page - 1, 20);
        Page<ComicSummaryDTO> comics = this.comicRepository.findComicPage(pageable);
        return ResponseEntity.ok(comics);
    }

    @GetMapping({"/search"})
    public ResponseEntity<List<ComicSummaryDTO>> searchComics(@RequestParam String keyword) {
        List<ComicSummaryDTO> comics = this.comicRepository.searchComic(keyword);
        return ResponseEntity.ok(comics);
    }

    @GetMapping({"/{comicId}"})
    public ResponseEntity<ComicDetailDTO> getComicDetail(@PathVariable String comicId) {
        Optional<Comic> comicOpt = this.comicRepository.findById(comicId);
        if (comicOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        } else {
            Comic comic = (Comic)comicOpt.get();
            List<ChapterDTO> chapters = this.chapterRepository.findChapterDTOByComicId(comicId);
            ComicDetailDTO dto = new ComicDetailDTO();
            dto.setComicId(comic.getComicId());
            dto.setName(comic.getName());
            dto.setSlug(comic.getSlug());
            dto.setOriginName(comic.getOriginName());
            dto.setStatus(comic.getStatus());
            dto.setThumbUrl(comic.getThumbUrl());
            dto.setChaptersLatest(comic.getChaptersLatest());
            dto.setUpdatedAt(comic.getUpdatedAt());
            dto.setChapters(chapters);
            return ResponseEntity.ok(dto);
        }
    }

    @GetMapping({"/Genre/{genreId}"})
    public ResponseEntity<List<ComicSummaryDTO>> getComicsByGenre(@PathVariable String genreId) {
        List<ComicSummaryDTO> comics = this.comicRepository.findComicByGenre(genreId);
        return ResponseEntity.ok(comics);
    }
}

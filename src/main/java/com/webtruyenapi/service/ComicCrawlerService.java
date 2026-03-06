package com.webtruyenapi.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.webtruyenapi.dto.OTruyenDtos.*;
import com.webtruyenapi.entity.*;
import com.webtruyenapi.repository.*;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
public class ComicCrawlerService {
    private final OTruyenApiClient apiClient;
    private final ComicRepository comicRepository;
    private final ChapterRepository chapterRepository;
    private final GenreRepository genreRepository;
    private final ComicGenreRepository comicGenreRepository;
    private final ObjectMapper objectMapper;

    public ComicCrawlerService(OTruyenApiClient apiClient, ComicRepository comicRepository,
                             ChapterRepository chapterRepository, GenreRepository genreRepository,
                             ComicGenreRepository comicGenreRepository, ObjectMapper objectMapper) {
        this.apiClient = apiClient;
        this.comicRepository = comicRepository;
        this.chapterRepository = chapterRepository;
        this.genreRepository = genreRepository;
        this.comicGenreRepository = comicGenreRepository;
        this.objectMapper = objectMapper;
    }

    @Data
    public static class CrawlSummary {
        public int comicsTouched;
        public int comicsCreated;
        public int comicsUpdated;
        public int chaptersCreated;
        public int chaptersUpdated;
        public int genresCreated;
        public String sqlFilePath;
    }

    public CrawlSummary crawlLatestAsync(int page) {
        CrawlSummary summary = new CrawlSummary();
        
        try {
            ApiListResponse listResponse = apiClient.getComicListAsync(page);
            
            if (!"success".equalsIgnoreCase(listResponse.getStatus())) {
                throw new RuntimeException("Could not crawl comic list: " + listResponse.getMessage());
            }

            String cdnPrefix = normalizeCdn(listResponse.getData().getImageCdn());

            for (OTruyenComicSummary comicSummary : listResponse.getData().getItems()) {
                try {
                    ApiDetailResponse detailResponse = apiClient.getComicDetailAsync(comicSummary.getSlug());
                    
                    if (!"success".equalsIgnoreCase(detailResponse.getStatus())) {
                        continue;
                    }

                    OTruyenComicDetail detail = detailResponse.getData().getItem();
                    if (detail == null) continue;

                    Comic existingComic = comicRepository.findBySlug(detail.getSlug()).orElse(null);
                    
                    String originName = String.join(", ", 
                        detail.getOriginName() != null ? 
                        detail.getOriginName().stream()
                            .filter(name -> name != null && !name.trim().isEmpty())
                            .map(String::trim)
                            .collect(Collectors.toList())
                        : new ArrayList<>());
                    
                    String thumbUrl = buildAbsoluteUrl(
                        cdnPrefix != null ? cdnPrefix : detailResponse.getData().getImageCdn(),
                        detail.getThumbUrl() != null ? detail.getThumbUrl() : comicSummary.getThumbUrl());

                    Comic comic;
                    if (existingComic == null) {
                        comic = new Comic();
                        comic.setComicId(detail.getId());
                        summary.comicsCreated++;
                    } else {
                        comic = existingComic;
                        summary.comicsUpdated++;
                    }

                    comic.setName(detail.getName());
                    comic.setSlug(detail.getSlug());
                    comic.setOriginName(originName);
                    comic.setStatus(detail.getStatus());
                    comic.setThumbUrl(thumbUrl);
                    comic.setSubDocquyen(detail.isSubDocQuyen());
                    comic.setUpdatedAt(LocalDateTime.now());

                    if (comic.getCreatedAt() == null) {
                        comic.setCreatedAt(LocalDateTime.now());
                    }

                    Comic savedComic = comicRepository.save(comic);
                    summary.comicsTouched++;

                    // Process genres
                    if (detail.getCategories() != null) {
                        for (OTruyenCategory category : detail.getCategories()) {
                            Genre genre = genreRepository.findById(category.getId())
                                    .orElseGet(() -> {
                                        Genre newGenre = new Genre();
                                        newGenre.setGenreId(category.getId());
                                        newGenre.setName(category.getName());
                                        summary.genresCreated++;
                                        return genreRepository.save(newGenre);
                                    });

                            if (!(existingComic != null) && existingComic.getComicGenres().stream()
                                    .anyMatch(cg -> cg.getGenreId().equals(genre.getGenreId()))) {
                                ComicGenre comicGenre = new ComicGenre();
                                comicGenre.setComicId(savedComic.getComicId());
                                comicGenre.setGenreId(genre.getGenreId());
                                comicGenreRepository.save(comicGenre);
                            }
                        }
                    }

                    // Process chapters
                    if (detail.getChapters() != null) {
                        for (OTruyenChapter chapterData : detail.getChapters()) {
                            Chapter existingChapter = chapterRepository.findByComicIdAndSlug(
                                    savedComic.getComicId(), chapterData.getSlug());
                            
                            Chapter chapter = existingChapter != null ? existingChapter : new Chapter();
                            chapter.setComicId(savedComic.getComicId());
                            chapter.setSlug(chapterData.getSlug());
                            chapter.setServerName(chapterData.getServerName());
                            chapter.setServerIndex(chapterData.getServerIndex());
                            chapter.setChapterIndex(chapterData.getChapterIndex());
                            chapter.setChapterName(chapterData.getName());
                            chapter.setFilename(chapterData.getFilename());
                            chapter.setUpdatedAt(LocalDateTime.now());

                            if (chapter.getCreatedAt() == null) {
                                chapter.setCreatedAt(LocalDateTime.now());
                                summary.chaptersCreated++;
                            } else {
                                summary.chaptersUpdated++;
                            }

                            chapterRepository.save(chapter);
                        }
                    }
                } catch (Exception e) {
                    log.error("Error processing comic: {}", comicSummary.getSlug(), e);
                }
            }
        } catch (Exception e) {
            log.error("Error crawling comics", e);
        }

        return summary;
    }

    private String normalizeCdn(String cdn) {
        if (cdn == null) return null;
        return cdn.endsWith("/") ? cdn.substring(0, cdn.length() - 1) : cdn;
    }

    private String buildAbsoluteUrl(String cdnPrefix, String path) {
        if (path == null || path.startsWith("http")) {
            return path;
        }
        return cdnPrefix != null ? cdnPrefix + path : path;
    }
}

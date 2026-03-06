package com.webtruyenapi.controller;

import com.webtruyenapi.service.ComicCrawlerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/Crawl")
@Slf4j
public class CrawlController {
    private final ComicCrawlerService crawlerService;

    public CrawlController(ComicCrawlerService crawlerService) {
        this.crawlerService = crawlerService;
    }

    @PostMapping("/latest")
    public ResponseEntity<ComicCrawlerService.CrawlSummary> crawlLatest(
            @RequestParam(defaultValue = "1") int page) {
        log.info("Starting crawl for page: {}", page);
        ComicCrawlerService.CrawlSummary summary = crawlerService.crawlLatestAsync(page);
        return ResponseEntity.ok(summary);
    }
}

package com.webtruyenapi.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.webtruyenapi.dto.OTruyenDtos.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
@Slf4j
public class OTruyenApiClient {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private static final String BASE_URL = "https://api.otruyenapi.com/v1/api";

    public OTruyenApiClient(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    public ApiListResponse getComicListAsync(int page) {
        try {
            String url = String.format("%s/v2/danh-sach/truyen?page=%d", BASE_URL, page);
            log.info("Fetching comics from: {}", url);
            
            ApiListResponse response = restTemplate.getForObject(url, ApiListResponse.class);
            return response;
        } catch (Exception e) {
            log.error("Error fetching comic list", e);
            throw new RuntimeException("Could not fetch comic list", e);
        }
    }

    public ApiDetailResponse getComicDetailAsync(String slug) {
        try {
            String url = String.format("%s/truyen/%s", BASE_URL, slug);
            log.info("Fetching comic detail from: {}", url);
            
            ApiDetailResponse response = restTemplate.getForObject(url, ApiDetailResponse.class);
            return response;
        } catch (Exception e) {
            log.error("Error fetching comic detail", e);
            throw new RuntimeException("Could not fetch comic detail", e);
        }
    }
}

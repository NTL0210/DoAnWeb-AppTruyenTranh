package com.webtruyenapi.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

public class OTruyenDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OTruyenComicSummary {
        private String id;
        private String name;
        private String slug;
        private String thumbUrl;
        private String status;
        private LocalDateTime updatedAt;
        private List<OTruyenLatestChapter> chaptersLatest;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OTruyenLatestChapter {
        private String id;
        private String name;
        private String slug;
        private LocalDateTime updatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OTruyenComicDetail {
        private String id;
        private String name;
        private String slug;
        private List<String> originName;
        private String status;
        private String thumbUrl;
        private boolean subDocQuyen;
        private LocalDateTime updatedAt;
        private List<OTruyenCategory> categories;
        private List<OTruyenChapter> chapters;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OTruyenCategory {
        private String id;
        private String name;
        private String slug;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OTruyenChapter {
        private String id;
        private String name;
        private String slug;
        private String serverName;
        private int serverIndex;
        private int chapterIndex;
        private String filename;
        private LocalDateTime updatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiListResponse {
        private String status;
        private String message;
        private ApiListData data;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiListData {
        private List<OTruyenComicSummary> items;
        private String imageCdn;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiDetailResponse {
        private String status;
        private String message;
        private ApiDetailData data;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiDetailData {
        private OTruyenComicDetail item;
        private String imageCdn;
    }
}

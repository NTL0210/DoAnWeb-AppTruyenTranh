package com.webtruyenapi.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class FollowDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateFollowRequest {
        private String followedId;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FollowResponse {
        private String followId;
        private String accountId;
        private String followedId;
        private String createdAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ComicFollowRequest {
        private String comicId;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ComicFollowResponse {
        private String comicFollowId;
        private String accountId;
        private String comicId;
        private String createdAt;
    }
}

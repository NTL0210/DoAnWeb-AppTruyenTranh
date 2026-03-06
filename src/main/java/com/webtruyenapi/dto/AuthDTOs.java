package com.webtruyenapi.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class AuthDTOs {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RegisterRequest {
        private String email;
        private String userName;
        private String password;
        private String image;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginRequest {
        private String loginName; // email hoặc userName
        private String password;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ForgotPasswordRequest {
        private String mail;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResetPasswordRequest {
        private String mail;
        private String otp;
        private String newPassword;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UploadAvatarRequest {
        private String createdDate;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginResponse {
        private String token;
        private AccountInfo user;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AccountInfo {
        private String accountId;
        private String userName;
        private String mail;
        private String image;
        private Boolean position;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GoogleAuthRequest {
        private String token;
    }
}

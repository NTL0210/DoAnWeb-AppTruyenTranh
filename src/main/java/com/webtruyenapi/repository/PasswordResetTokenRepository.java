package com.webtruyenapi.repository;

import com.webtruyenapi.entity.PasswordResetToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, String> {
    Optional<PasswordResetToken> findByEmailAndOtp(String email, String otp);
    void deleteByEmail(String email);
}

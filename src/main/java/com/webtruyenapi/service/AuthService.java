package com.webtruyenapi.service;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.webtruyenapi.entity.Account;

import java.util.Date;

@Service
@Slf4j
public class AuthService {
    private final BCryptPasswordEncoder passwordEncoder;

    @Value("${jwt.key}")
    private String jwtKey;

    @Value("${jwt.issuer}")
    private String issuer;

    @Value("${jwt.expiration}")
    private Long jwtExpiration;

    public AuthService() {
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    public String hashPassword(String password) {
        return passwordEncoder.encode(password);
    }

    public boolean verifyPassword(String password, String hash) {
        return passwordEncoder.matches(password, hash);
    }

    public String generateJwtToken(Account account) {
        try {
            long now = System.currentTimeMillis();
            
            return Jwts.builder()
                    .claim("accountId", account.getAccountId())
                    .claim("email", account.getMail())
                    .setIssuer(issuer)
                    .setAudience(issuer)
                    .setIssuedAt(new Date(now))
                    .setExpiration(new Date(now + jwtExpiration))
                    .signWith(Keys.hmacShaKeyFor(jwtKey.getBytes()), SignatureAlgorithm.HS256)
                    .compact();
        } catch (Exception e) {
            log.error("Error generating JWT token", e);
            throw new RuntimeException("Could not generate JWT token", e);
        }
    }
}

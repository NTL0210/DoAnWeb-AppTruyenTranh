package com.webtruyenapi.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

@Component
@Slf4j
public class JwtTokenProvider {
    @Value("${jwt.key}")
    private String jwtKey;

    @Value("${jwt.issuer}")
    private String issuer;

    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .setSigningKey(Keys.hmacShaKeyFor(jwtKey.getBytes(StandardCharsets.UTF_8)))
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            log.error("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }

    public String getAccountIdFromToken(String token) {
        return getClaimFromToken(token, "accountId", String.class);
    }

    public String getEmailFromToken(String token) {
        return getClaimFromToken(token, "email", String.class);
    }

    private <T> T getClaimFromToken(String token, String claimName, Class<T> claimType) {
        try {
            Claims claims = Jwts.parser()
                    .setSigningKey(Keys.hmacShaKeyFor(jwtKey.getBytes(StandardCharsets.UTF_8)))
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
            return claims.get(claimName, claimType);
        } catch (Exception e) {
            log.error("Error getting claim from token", e);
            return null;
        }
    }
}

package com.webtruyenapi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "follows")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Follow {
    @Id
    @Column(name = "follow_id", length = 36)
    private String followId;

    @Column(name = "account_id", length = 36)
    private String accountId;

    @Column(name = "followed_id", length = 36)
    private String followedId;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", insertable = false, updatable = false)
    private Account account;

    @PrePersist
    protected void onCreate() {
        if (this.followId == null) {
            this.followId = UUID.randomUUID().toString();
        }
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }
}

package com.webtruyenapi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "comic_follows")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ComicFollow {
    @Id
    @Column(name = "comic_follow_id", length = 36)
    private String comicFollowId;

    @Column(name = "account_id", length = 36)
    private String accountId;

    @Column(name = "comic_id", length = 36)
    private String comicId;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "comic_id", insertable = false, updatable = false)
    private Comic comic;

    @PrePersist
    protected void onCreate() {
        if (this.comicFollowId == null) {
            this.comicFollowId = UUID.randomUUID().toString();
        }
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }
}

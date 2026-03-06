package com.webtruyenapi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonIgnore;

@Entity
@Table(name = "chapters")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Chapter {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Integer id;

    @Column(name = "comic_id", length = 36)
    private String comicId;

    @Column(name = "slug")
    private String slug;

    @Column(name = "server_name")
    private String serverName;

    @Column(name = "server_index")
    private Integer serverIndex;

    @Column(name = "chapter_index")
    private Integer chapterIndex;

    @Column(name = "filename")
    private String filename;

    @Column(name = "chapter_name")
    private String chapterName;

    @Column(name = "chapter_title")
    private String chapterTitle;

    @Column(name = "chapter_api_data", columnDefinition = "TEXT")
    private String chapterApiData;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "comic_id", insertable = false, updatable = false)
    @JsonIgnore
    private Comic comic;

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.updatedAt == null) {
            this.updatedAt = LocalDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}

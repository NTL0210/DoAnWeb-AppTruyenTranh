package com.webtruyenapi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import com.fasterxml.jackson.annotation.JsonIgnore;

@Entity
@Table(name = "comics")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Comic {
    @Id
    @Column(name = "comic_id", length = 36)
    private String comicId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "slug", nullable = false)
    private String slug;

    @Column(name = "origin_name")
    private String originName;

    @Column(name = "status")
    private String status;

    @Column(name = "thumb_url", columnDefinition = "TEXT")
    private String thumbUrl;

    @Column(name = "sub_docquyen")
    private Boolean subDocquyen = false;

    @Column(name = "chapters_latest", columnDefinition = "TEXT")
    private String chaptersLatest;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "modified_at")
    private LocalDateTime modifiedAt;

    @OneToMany(mappedBy = "comic", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Chapter> chapters = new ArrayList<>();

    @OneToMany(mappedBy = "comic", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<ComicGenre> comicGenres = new ArrayList<>();

    @OneToMany(mappedBy = "comic", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<ComicFollow> comicFollows = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.updatedAt == null) {
            this.updatedAt = LocalDateTime.now();
        }
        if (this.subDocquyen == null) {
            this.subDocquyen = false;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.modifiedAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
}

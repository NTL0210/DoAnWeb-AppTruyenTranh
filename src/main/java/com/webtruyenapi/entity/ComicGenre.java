package com.webtruyenapi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "comic_genres")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ComicGenre {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Integer id;

    @Column(name = "comic_id", length = 36)
    private String comicId;

    @Column(name = "genre_id", length = 36)
    private String genreId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "comic_id", insertable = false, updatable = false)
    private Comic comic;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "genre_id", insertable = false, updatable = false)
    private Genre genre;
}

package com.webtruyenapi.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "genres")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Genre {
    @Id
    @Column(name = "genre_id", length = 36)
    private String genreId;

    @Column(name = "name", nullable = false)
    private String name;

    @OneToMany(mappedBy = "genre")
    @JsonIgnore
    private List<ComicGenre> comicGenres;

    @PrePersist
    protected void onCreate() {
        if (this.genreId == null) {
            this.genreId = UUID.randomUUID().toString();
        }
    }
}

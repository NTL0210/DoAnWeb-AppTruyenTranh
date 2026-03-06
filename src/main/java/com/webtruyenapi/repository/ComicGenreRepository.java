package com.webtruyenapi.repository;

import com.webtruyenapi.entity.ComicGenre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ComicGenreRepository extends JpaRepository<ComicGenre, Integer> {
}

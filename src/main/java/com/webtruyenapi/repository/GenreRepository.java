package com.webtruyenapi.repository;

import com.webtruyenapi.entity.Genre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GenreRepository extends JpaRepository<Genre, String> {
    Optional<Genre> findByName(String name);
}

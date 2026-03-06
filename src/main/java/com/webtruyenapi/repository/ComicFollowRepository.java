package com.webtruyenapi.repository;

import com.webtruyenapi.entity.ComicFollow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ComicFollowRepository extends JpaRepository<ComicFollow, String> {
    List<ComicFollow> findByAccountId(String accountId);
    boolean existsByAccountIdAndComicId(String accountId, String comicId);
    void deleteByAccountIdAndComicId(String accountId, String comicId);
}

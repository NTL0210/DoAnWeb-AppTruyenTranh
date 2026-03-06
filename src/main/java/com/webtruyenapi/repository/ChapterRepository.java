package com.webtruyenapi.repository;

import com.webtruyenapi.dto.ChapterDTO;
import com.webtruyenapi.entity.Chapter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChapterRepository extends JpaRepository<Chapter, Integer> {
    List<Chapter> findByComicIdOrderByChapterIndexAsc(String comicId);
    Chapter findByComicIdAndSlug(String comicId, String slug);

    @Query("""
SELECT new com.webtruyenapi.dto.ChapterDTO(
    c.id,
    c.chapterName,
    c.chapterTitle,
    c.chapterIndex
)
FROM Chapter c
WHERE c.comic.comicId = :comicId
ORDER BY c.chapterIndex ASC
""")
    List<ChapterDTO> findChapterDTOByComicId(@Param("comicId") String comicId);
}

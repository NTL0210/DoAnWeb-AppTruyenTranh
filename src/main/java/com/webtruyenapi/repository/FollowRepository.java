package com.webtruyenapi.repository;

import com.webtruyenapi.entity.Follow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FollowRepository extends JpaRepository<Follow, String> {
    List<Follow> findByAccountId(String accountId);
    boolean existsByAccountIdAndFollowedId(String accountId, String followedId);
    void deleteByAccountIdAndFollowedId(String accountId, String followedId);
}

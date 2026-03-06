package com.webtruyenapi.controller;

import com.webtruyenapi.dto.FollowDtos.*;
import com.webtruyenapi.entity.ComicFollow;
import com.webtruyenapi.entity.Follow;
import com.webtruyenapi.repository.ComicFollowRepository;
import com.webtruyenapi.repository.FollowRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping(value = "/api/Follows")
@Slf4j
public class FollowController {
    private final FollowRepository followRepository;
    private final ComicFollowRepository comicFollowRepository;

    public FollowController(FollowRepository followRepository, ComicFollowRepository comicFollowRepository) {
        this.followRepository = followRepository;
        this.comicFollowRepository = comicFollowRepository;
    }

    @PostMapping("/user")
    public ResponseEntity<Object> followUser(@RequestBody CreateFollowRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Not authenticated"));
        }

        String accountId = (String) auth.getPrincipal();
        
        if (followRepository.existsByAccountIdAndFollowedId(accountId, req.getFollowedId())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("message", "You are already following this user"));
        }

        Follow follow = new Follow();
        follow.setFollowId(UUID.randomUUID().toString());
        follow.setAccountId(accountId);
        follow.setFollowedId(req.getFollowedId());
        follow.setCreatedAt(LocalDateTime.now());

        Follow savedFollow = followRepository.save(follow);

        FollowResponse response = new FollowResponse(
                savedFollow.getFollowId(),
                savedFollow.getAccountId(),
                savedFollow.getFollowedId(),
                savedFollow.getCreatedAt().toString()
        );

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/user/{followedId}")
    public ResponseEntity<Void> unfollowUser(@PathVariable String followedId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String accountId = (String) auth.getPrincipal();
        followRepository.deleteByAccountIdAndFollowedId(accountId, followedId);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<List<Follow>> getFollows() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String accountId = (String) auth.getPrincipal();
        List<Follow> follows = followRepository.findByAccountId(accountId);
        return ResponseEntity.ok(follows);
    }

    @PostMapping("/comic")
    public ResponseEntity<Object> followComic(@RequestBody ComicFollowRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Not authenticated"));
        }

        String accountId = (String) auth.getPrincipal();
        
        if (comicFollowRepository.existsByAccountIdAndComicId(accountId, req.getComicId())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("message", "You are already following this comic"));
        }

        ComicFollow comicFollow = new ComicFollow();
        comicFollow.setComicFollowId(UUID.randomUUID().toString());
        comicFollow.setAccountId(accountId);
        comicFollow.setComicId(req.getComicId());
        comicFollow.setCreatedAt(LocalDateTime.now());

        ComicFollow savedComicFollow = comicFollowRepository.save(comicFollow);

        ComicFollowResponse response = new ComicFollowResponse(
                savedComicFollow.getComicFollowId(),
                savedComicFollow.getAccountId(),
                savedComicFollow.getComicId(),
                savedComicFollow.getCreatedAt().toString()
        );

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/comic/{comicId}")
    public ResponseEntity<Void> unfollowComic(@PathVariable String comicId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String accountId = (String) auth.getPrincipal();
        comicFollowRepository.deleteByAccountIdAndComicId(accountId, comicId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/comics")
    public ResponseEntity<List<ComicFollow>> getFollowedComics() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String accountId = (String) auth.getPrincipal();
        List<ComicFollow> comicFollows = comicFollowRepository.findByAccountId(accountId);
        return ResponseEntity.ok(comicFollows);
    }
}

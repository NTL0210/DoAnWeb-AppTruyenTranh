package com.webtruyenapi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "account")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Account {
    @Id
    @Column(name = "account_id", length = 36)
    private String accountId;

    @Column(name = "mail", nullable = false, unique = true)
    private String mail;

    @Column(name = "password", nullable = false, columnDefinition = "TEXT")
    private String password;

    @Column(name = "user_name")
    private String userName;

    @Column(name = "image")
    private String image;

    @Column(name = "position")
    private Boolean position = false;

    @OneToMany(mappedBy = "account", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Follow> follows = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        if (this.accountId == null) {
            this.accountId = UUID.randomUUID().toString();
        }
        if (this.position == null) {
            this.position = false;
        }
    }
}

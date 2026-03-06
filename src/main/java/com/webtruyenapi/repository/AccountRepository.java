package com.webtruyenapi.repository;

import com.webtruyenapi.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AccountRepository extends JpaRepository<Account, String> {
    Optional<Account> findByMail(String mail);
    Optional<Account> findByUserName(String userName);
    boolean existsByMail(String mail);
}

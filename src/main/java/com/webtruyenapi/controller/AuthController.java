package com.webtruyenapi.controller;

import com.webtruyenapi.dto.AuthDTOs.*;
import com.webtruyenapi.entity.Account;
import com.webtruyenapi.entity.PasswordResetToken;
import com.webtruyenapi.repository.AccountRepository;
import com.webtruyenapi.repository.PasswordResetTokenRepository;
import com.webtruyenapi.service.AuthService;
import com.webtruyenapi.service.EmailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Random;

@RestController
@RequestMapping("/api/Auth")
@Slf4j
public class AuthController {
    private final AccountRepository accountRepository;
    private final AuthService authService;
    private final EmailService emailService;
    private final PasswordResetTokenRepository passwordResetTokenRepository;

    public AuthController(AccountRepository accountRepository, AuthService authService, 
                        EmailService emailService, PasswordResetTokenRepository passwordResetTokenRepository) {
        this.accountRepository = accountRepository;
        this.authService = authService;
        this.emailService = emailService;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody RegisterRequest req) {
        if (accountRepository.existsByMail(req.getEmail())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("message", "Email đã tồn tại"));
        }

        Account account = new Account();
        account.setMail(req.getEmail());
        account.setUserName(req.getUserName());
        account.setPassword(authService.hashPassword(req.getPassword()));
        account.setImage(req.getImage() != null ? req.getImage() : "default_avatar.png");
        account.setPosition(false);

        Account savedAccount = accountRepository.save(account);

        AccountInfo accountInfo = new AccountInfo(
                savedAccount.getAccountId(),
                savedAccount.getUserName(),
                savedAccount.getMail(),
                savedAccount.getImage(),
                savedAccount.getPosition()
        );

        return ResponseEntity.ok(Map.of(
                "message", "Đăng ký thành công",
                "account", accountInfo
        ));
    }

    @PostMapping("/login")
    public ResponseEntity<Object> login(@RequestBody LoginRequest req) {
        Optional<Account> accountOpt = accountRepository.findByMail(req.getLoginName());
        
        if (accountOpt.isEmpty()) {
            accountOpt = accountRepository.findByUserName(req.getLoginName());
        }

        if (accountOpt.isEmpty() || !authService.verifyPassword(req.getPassword(), accountOpt.get().getPassword())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Sai email hoặc mật khẩu"));
        }

        Account account = accountOpt.get();
        String token = authService.generateJwtToken(account);

        AccountInfo accountInfo = new AccountInfo(
                account.getAccountId(),
                account.getUserName(),
                account.getMail(),
                account.getImage(),
                account.getPosition()
        );

        LoginResponse response = new LoginResponse(token, accountInfo);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/request-reset")
    public ResponseEntity<Object> requestPasswordReset(@RequestBody ForgotPasswordRequest req) {
        Optional<Account> accountOpt = accountRepository.findByMail(req.getMail());
        
        if (accountOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Email không tồn tại"));
        }

        String otp = String.format("%06d", new Random().nextInt(1000000));
        
        PasswordResetToken token = new PasswordResetToken();
        token.setEmail(req.getMail());
        token.setOtp(otp);
        token.setExpiredAt(LocalDateTime.now().plusMinutes(5));
        passwordResetTokenRepository.save(token);

        String emailBody = String.format("Mã OTP của bạn là: %s. Mã này sẽ hết hạn sau 5 phút.", otp);
        emailService.sendEmailAsync(req.getMail(), "Mã đặt lại mật khẩu", emailBody);

        return ResponseEntity.ok(Map.of("message", "Mã OTP đã được gửi đến email của bạn."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Object> resetPassword(@RequestBody ResetPasswordRequest req) {
        Optional<PasswordResetToken> tokenOpt = passwordResetTokenRepository.findByEmailAndOtp(req.getMail(), req.getOtp());

        if (tokenOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("message", "Mã OTP không hợp lệ"));
        }

        PasswordResetToken token = tokenOpt.get();
        if (token.getExpiredAt().isBefore(LocalDateTime.now())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("message", "Mã OTP đã hết hạn"));
        }

        Optional<Account> accountOpt = accountRepository.findByMail(req.getMail());
        if (accountOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Không tìm thấy tài khoản"));
        }

        Account account = accountOpt.get();
        account.setPassword(authService.hashPassword(req.getNewPassword()));
        accountRepository.save(account);

        passwordResetTokenRepository.delete(token);

        return ResponseEntity.ok(Map.of("message", "Mật khẩu của bạn đã được thay đổi thành công."));
    }

    @GetMapping("/me")
    public ResponseEntity<Object> getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Not authenticated"));
        }

        String accountId = (String) auth.getPrincipal();
        Optional<Account> accountOpt = accountRepository.findById(accountId);

        if (accountOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Tài khoản không tìm thấy"));
        }

        Account account = accountOpt.get();
        AccountInfo accountInfo = new AccountInfo(
                account.getAccountId(),
                account.getUserName(),
                account.getMail(),
                account.getImage(),
                account.getPosition()
        );

        return ResponseEntity.ok(accountInfo);
    }
}

package com.banking.transaction.controller;

import com.banking.transaction.dto.AccountInsightsDTO;
import com.banking.transaction.dto.BeneficiaryDTO;
import com.banking.transaction.dto.BeneficiaryRequestDTO;
import com.banking.transaction.dto.TransferRequestDTO;
import com.banking.transaction.entity.Transaction;
import com.banking.transaction.service.TransactionService;
import com.banking.transaction.security.JwtTokenProvider;
import org.springframework.http.ResponseEntity;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
public class HealthController {

    private final TransactionService transactionService;
    private final JwtTokenProvider jwtTokenProvider;

    public HealthController(TransactionService transactionService, JwtTokenProvider jwtTokenProvider) {
        this.transactionService = transactionService;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @GetMapping("/")
    public Map<String, String> health() {
        Map<String, String> response = new HashMap<>();
        response.put("service", "Transaction Service");
        response.put("status", "UP");
        response.put("port", "8082");
        return response;
    }

    @GetMapping("/health")
    public Map<String, String> healthCheck() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        return response;
    }

    @GetMapping("/api/transactions/health")
    public Map<String, String> transactionsHealthCheck() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Transaction Service");
        return response;
    }

    @PostMapping("/api/transactions/transfer")
    public ResponseEntity<String> transferFunds(
            @Valid @RequestBody TransferRequestDTO transferRequest,
            HttpServletRequest request) {

        // Extract JWT token from request header
        String token = getJwtFromRequest(request);
        if (token == null) {
            return ResponseEntity.status(401).body("Missing or invalid authentication token");
        }

        // Extract userId from token
        Long userId = jwtTokenProvider.getUserIdFromToken(token);
        if (userId == null) {
            return ResponseEntity.status(401).body("Invalid token: userId not found");
        }

        // Call service with userId for authorization check
        String result = transactionService.transferFunds(transferRequest, userId);
        return ResponseEntity.ok(result);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring("Bearer ".length());
        }
        return null;
    }

    @GetMapping("/api/transactions/account/{accountNumber}")
    public ResponseEntity<List<Transaction>> getTransactionHistory(
            @PathVariable String accountNumber,
            HttpServletRequest request,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime toDate) {
        String token = getJwtFromRequest(request);
        if (token == null) {
            return ResponseEntity.status(401).build();
        }

        Long userId = jwtTokenProvider.getUserIdFromToken(token);
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        List<Transaction> transactions = transactionService.getTransactionsByAccountFiltered(
                accountNumber,
                userId,
                status,
                fromDate,
                toDate);
        return ResponseEntity.ok(transactions);
    }

    @GetMapping("/api/transactions/account/{accountNumber}/insights")
    public ResponseEntity<AccountInsightsDTO> getAccountInsights(
            @PathVariable String accountNumber,
            HttpServletRequest request) {
        String token = getJwtFromRequest(request);
        if (token == null) {
            return ResponseEntity.status(401).build();
        }

        Long userId = jwtTokenProvider.getUserIdFromToken(token);
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        return ResponseEntity.ok(transactionService.getAccountInsights(accountNumber, userId));
    }

    @GetMapping("/api/transactions/beneficiaries")
    public ResponseEntity<List<BeneficiaryDTO>> getBeneficiaries(HttpServletRequest request) {
        String token = getJwtFromRequest(request);
        if (token == null) {
            return ResponseEntity.status(401).build();
        }
        Long userId = jwtTokenProvider.getUserIdFromToken(token);
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }
        return ResponseEntity.ok(transactionService.getBeneficiaries(userId));
    }

    @PostMapping("/api/transactions/beneficiaries")
    public ResponseEntity<BeneficiaryDTO> addBeneficiary(
            @Valid @RequestBody BeneficiaryRequestDTO request,
            HttpServletRequest httpRequest) {
        String token = getJwtFromRequest(httpRequest);
        if (token == null) {
            return ResponseEntity.status(401).build();
        }
        Long userId = jwtTokenProvider.getUserIdFromToken(token);
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        BeneficiaryDTO response = transactionService.addBeneficiary(userId, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/api/transactions/beneficiaries/{beneficiaryId}")
    public ResponseEntity<Void> deleteBeneficiary(
            @PathVariable Long beneficiaryId,
            HttpServletRequest request) {
        String token = getJwtFromRequest(request);
        if (token == null) {
            return ResponseEntity.status(401).build();
        }
        Long userId = jwtTokenProvider.getUserIdFromToken(token);
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        transactionService.deleteBeneficiary(userId, beneficiaryId);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/api/transactions/beneficiaries/{beneficiaryId}/favorite")
    public ResponseEntity<BeneficiaryDTO> setBeneficiaryFavorite(
            @PathVariable Long beneficiaryId,
            @RequestParam boolean favorite,
            HttpServletRequest request) {
        String token = getJwtFromRequest(request);
        if (token == null) {
            return ResponseEntity.status(401).build();
        }
        Long userId = jwtTokenProvider.getUserIdFromToken(token);
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        return ResponseEntity.ok(transactionService.setBeneficiaryFavorite(userId, beneficiaryId, favorite));
    }
}

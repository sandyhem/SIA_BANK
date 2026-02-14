package com.banking.transaction.controller;

import com.banking.transaction.dto.TransferRequestDTO;
import com.banking.transaction.entity.Transaction;
import com.banking.transaction.service.TransactionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
public class HealthController {

    private final TransactionService transactionService;

    public HealthController(TransactionService transactionService) {
        this.transactionService = transactionService;
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
    public ResponseEntity<String> transferFunds(@Valid @RequestBody TransferRequestDTO transferRequest) {
        String result = transactionService.transferFunds(transferRequest);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/api/transactions/account/{accountNumber}")
    public ResponseEntity<List<Transaction>> getTransactionHistory(@PathVariable String accountNumber) {
        List<Transaction> transactions = transactionService.getTransactionsByAccount(accountNumber);
        return ResponseEntity.ok(transactions);
    }
}

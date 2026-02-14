package com.banking.account.controller;

import com.banking.account.dto.AccountDTO;
import com.banking.account.dto.CreditRequestDTO;
import com.banking.account.dto.DebitRequestDTO;
import com.banking.account.dto.CreateAccountRequestDTO;
import com.banking.account.exception.AccountNotFoundException;
import com.banking.account.exception.AccountInactiveException;
import com.banking.account.exception.InsufficientBalanceException;
import com.banking.account.service.AccountService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Account Service is UP");
    }

    @GetMapping("/{accountNumber}")
    public ResponseEntity<AccountDTO> getAccount(@PathVariable String accountNumber) {
        AccountDTO accountDTO = accountService.getAccountByAccountNumber(accountNumber);
        return ResponseEntity.ok(accountDTO);
    }

    @PutMapping("/{accountNumber}/debit")
    public ResponseEntity<String> debitAccount(@PathVariable String accountNumber,
            @Valid @RequestBody DebitRequestDTO debitRequest) {
        accountService.debitAccount(accountNumber, debitRequest);
        return ResponseEntity.ok("Debit successful");
    }

    @PutMapping("/{accountNumber}/credit")
    public ResponseEntity<String> creditAccount(@PathVariable String accountNumber,
            @Valid @RequestBody CreditRequestDTO creditRequest) {
        accountService.creditAccount(accountNumber, creditRequest);
        return ResponseEntity.ok("Credit successful");
    }

    @PostMapping
    public ResponseEntity<AccountDTO> createAccount(@Valid @RequestBody CreateAccountRequestDTO createRequest) {
        AccountDTO accountDTO = accountService.createAccount(createRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(accountDTO);
    }

    @GetMapping
    public ResponseEntity<java.util.List<AccountDTO>> getAllAccounts() {
        java.util.List<AccountDTO> accounts = accountService.getAllAccounts();
        return ResponseEntity.ok(accounts);
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<java.util.List<AccountDTO>> getAccountsByCustomer(@PathVariable Long customerId) {
        java.util.List<AccountDTO> accounts = accountService.getAccountsByCustomerId(customerId);
        return ResponseEntity.ok(accounts);
    }
}
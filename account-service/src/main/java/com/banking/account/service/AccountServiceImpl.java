package com.banking.account.service;

import com.banking.account.dto.AccountDTO;
import com.banking.account.dto.CreditRequestDTO;
import com.banking.account.dto.DebitRequestDTO;
import com.banking.account.dto.CreateAccountRequestDTO;
import com.banking.account.entity.Account;
import com.banking.account.entity.AccountStatus;
import com.banking.account.exception.AccountInactiveException;
import com.banking.account.exception.AccountNotFoundException;
import com.banking.account.exception.InsufficientBalanceException;
import com.banking.account.repository.AccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@Transactional
public class AccountServiceImpl implements AccountService {

    private final AccountRepository accountRepository;

    public AccountServiceImpl(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    @Override
    public AccountDTO getAccountByAccountNumber(String accountNumber) {
        Account account = accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new AccountNotFoundException("Account not found: " + accountNumber));
        return mapToDTO(account);
    }

    @Override
    public void debitAccount(String accountNumber, DebitRequestDTO debitRequest) {
        Account account = accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new AccountNotFoundException("Account not found: " + accountNumber));

        if (account.getStatus() != AccountStatus.ACTIVE) {
            throw new AccountInactiveException("Account is not active");
        }

        if (account.getBalance().compareTo(debitRequest.getAmount()) < 0) {
            throw new InsufficientBalanceException("Insufficient balance");
        }

        account.setBalance(account.getBalance().subtract(debitRequest.getAmount()));
        accountRepository.save(account);
    }

    @Override
    public void creditAccount(String accountNumber, CreditRequestDTO creditRequest) {
        Account account = accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new AccountNotFoundException("Account not found: " + accountNumber));

        if (account.getStatus() != AccountStatus.ACTIVE) {
            throw new AccountInactiveException("Account is not active");
        }

        account.setBalance(account.getBalance().add(creditRequest.getAmount()));
        accountRepository.save(account);
    }

    @Override
    public AccountDTO createAccount(CreateAccountRequestDTO createRequest) {
        String accountNumber = "ACC" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        
        Account account = new Account();
        account.setAccountNumber(accountNumber);
        account.setCustomerId(createRequest.getCustomerId());
        account.setBalance(createRequest.getInitialBalance());
        account.setStatus(AccountStatus.ACTIVE);
        account.setCreatedAt(LocalDateTime.now());
        account.setUpdatedAt(LocalDateTime.now());
        
        Account savedAccount = accountRepository.save(account);
        return mapToDTO(savedAccount);
    }

    @Override
    public java.util.List<AccountDTO> getAllAccounts() {
        return accountRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(java.util.stream.Collectors.toList());
    }

    private AccountDTO mapToDTO(Account account) {
        return AccountDTO.builder()
                .accountNumber(account.getAccountNumber())
                .customerId(account.getCustomerId())
                .balance(account.getBalance())
                .status(account.getStatus().toString())
                .createdAt(account.getCreatedAt())
                .updatedAt(account.getUpdatedAt())
                .build();
    }
}

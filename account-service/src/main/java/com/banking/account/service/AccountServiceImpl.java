package com.banking.account.service;

import com.banking.account.client.CustomerServiceClient;
import com.banking.account.dto.AccountDTO;
import com.banking.account.dto.CreditRequestDTO;
import com.banking.account.dto.DebitRequestDTO;
import com.banking.account.dto.CreateAccountRequestDTO;
import com.banking.account.dto.CustomerStatusDTO;
import com.banking.account.entity.Account;
import com.banking.account.entity.AccountStatus;
import com.banking.account.exception.AccountInactiveException;
import com.banking.account.exception.AccountNotFoundException;
import com.banking.account.exception.InsufficientBalanceException;
import com.banking.account.exception.CustomerNotActiveException;
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
    private final CustomerServiceClient customerServiceClient;

    public AccountServiceImpl(AccountRepository accountRepository, CustomerServiceClient customerServiceClient) {
        this.accountRepository = accountRepository;
        this.customerServiceClient = customerServiceClient;
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
        /**
         * STANDARD BANKING FLOW:
         * 1. User must be registered (authentication level)
         * 2. Customer CIF must be created
         * 3. KYC must be VERIFIED
         * 4. Customer status must be ACTIVE
         * Only then can account be opened
         */

        CustomerStatusDTO customer;
        try {
            customer = customerServiceClient.getCustomerByUserId(createRequest.getUserId());
        } catch (feign.FeignException.NotFound ex) {
            throw new CustomerNotActiveException(
                    "Customer profile not found. Please create your customer profile (CIF) first before opening an account.");
        } catch (feign.FeignException ex) {
            throw new CustomerNotActiveException(
                    "Unable to verify customer status. Please try again later.");
        }

        // Check if Customer is ACTIVE (KYC must be VERIFIED for this)
        if (!"ACTIVE".equalsIgnoreCase(customer.getCustomerStatus())) {
            throw new CustomerNotActiveException(
                    String.format("Customer account is %s. Only ACTIVE customers can open bank accounts. " +
                            "Current KYC Status: %s. Please complete KYC verification.",
                            customer.getCustomerStatus(), customer.getKycStatus()));
        }

        // Double check KYC status
        if (!"VERIFIED".equalsIgnoreCase(customer.getKycStatus())) {
            throw new CustomerNotActiveException(
                    "KYC verification is required. Current status: " + customer.getKycStatus() +
                            ". Please complete your KYC verification before opening an account.");
        }

        // Generate account number
        String accountNumber = "ACC" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // Create account with ACTIVE status and initial balance
        Account account = new Account();
        account.setAccountNumber(accountNumber);
        account.setAccountName(createRequest.getAccountName());
        account.setAccountType(createRequest.getAccountType());
        account.setCustomerCif(customer.getCifNumber());
        account.setUserId(createRequest.getUserId());
        account.setBalance(
                createRequest.getInitialBalance() != null ? createRequest.getInitialBalance() : BigDecimal.ZERO);
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

    @Override
    public java.util.List<AccountDTO> getAccountsByCustomerId(Long customerId) {
        // Legacy method - customerId now refers to userId in new architecture
        return getAccountsByUserId(customerId);
    }

    public java.util.List<AccountDTO> getAccountsByUserId(Long userId) {
        return accountRepository.findByUserId(userId).stream()
                .map(this::mapToDTO)
                .collect(java.util.stream.Collectors.toList());
    }

    private AccountDTO mapToDTO(Account account) {
        return AccountDTO.builder()
                .accountNumber(account.getAccountNumber())
                .accountName(account.getAccountName())
                .accountType(account.getAccountType())
                .customerCif(account.getCustomerCif())
                .userId(account.getUserId())
                .balance(account.getBalance())
                .status(account.getStatus().toString())
                .createdAt(account.getCreatedAt())
                .updatedAt(account.getUpdatedAt())
                .build();
    }
}

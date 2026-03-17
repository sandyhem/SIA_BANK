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
import com.banking.account.exception.DuplicateAccountTypeException;
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
        activateIfEligible(account);
        return mapToDTO(account);
    }

    @Override
    public void debitAccount(String accountNumber, DebitRequestDTO debitRequest) {
        Account account = accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new AccountNotFoundException("Account not found: " + accountNumber));

        activateIfEligible(account);

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

        activateIfEligible(account);

        if (account.getStatus() != AccountStatus.ACTIVE) {
            throw new AccountInactiveException("Account is not active");
        }

        account.setBalance(account.getBalance().add(creditRequest.getAmount()));
        accountRepository.save(account);
    }

    @Override
    public AccountDTO createAccount(CreateAccountRequestDTO createRequest) {
        /**
         * Banking onboarding flow:
         * 1. User must be registered
         * 2. Customer CIF profile must exist
         * 3. Account can be created before KYC verification
         * 4. Account stays INACTIVE until admin verifies KYC and customer is ACTIVE
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

        final String requestedType = createRequest.getAccountType() == null
                ? "SAVINGS"
                : createRequest.getAccountType().trim();

        if (accountRepository.existsByUserIdAndAccountTypeIgnoreCase(createRequest.getUserId(), requestedType)) {
            throw new DuplicateAccountTypeException(
                    "Account type '" + requestedType.toUpperCase() + "' already exists for this user. "
                            + "Only one account per type is allowed per person.");
        }

        // Generate account number
        String accountNumber = "ACC" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        final boolean isCustomerActive = "ACTIVE".equalsIgnoreCase(customer.getCustomerStatus())
                && "VERIFIED".equalsIgnoreCase(customer.getKycStatus());

        // Create account. Keep INACTIVE until KYC is verified.
        Account account = new Account();
        account.setAccountNumber(accountNumber);
        account.setAccountName(createRequest.getAccountName());
        account.setAccountType(requestedType.toUpperCase());
        account.setCustomerCif(customer.getCifNumber());
        account.setUserId(createRequest.getUserId());
        account.setBalance(
                createRequest.getInitialBalance() != null ? createRequest.getInitialBalance() : BigDecimal.ZERO);
        account.setStatus(isCustomerActive ? AccountStatus.ACTIVE : AccountStatus.INACTIVE);
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
                .map(account -> {
                    activateIfEligible(account);
                    return mapToDTO(account);
                })
                .collect(java.util.stream.Collectors.toList());
    }

    private void activateIfEligible(Account account) {
        if (account.getStatus() == AccountStatus.ACTIVE) {
            return;
        }

        try {
            CustomerStatusDTO customer = customerServiceClient.getCustomerByUserId(account.getUserId());
            boolean eligible = "ACTIVE".equalsIgnoreCase(customer.getCustomerStatus())
                    && "VERIFIED".equalsIgnoreCase(customer.getKycStatus());

            if (eligible) {
                account.setStatus(AccountStatus.ACTIVE);
                accountRepository.save(account);
            }
        } catch (Exception ignored) {
            // Keep current status when customer service is unavailable.
        }
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

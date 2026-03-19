package com.banking.transaction.service;

import com.banking.transaction.client.AccountServiceClient;
import com.banking.transaction.dto.AccountInsightsDTO;
import com.banking.transaction.dto.BeneficiaryDTO;
import com.banking.transaction.dto.BeneficiaryRequestDTO;
import com.banking.transaction.dto.CreditRequestDTO;
import com.banking.transaction.dto.DebitRequestDTO;
import com.banking.transaction.dto.TransferRequestDTO;
import com.banking.transaction.entity.Beneficiary;
import com.banking.transaction.entity.Transaction;
import com.banking.transaction.repository.BeneficiaryRepository;
import com.banking.transaction.repository.TransactionRepository;
import com.banking.transaction.exception.UnauthorizedException;
import feign.FeignException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class TransactionService {

    private final AccountServiceClient accountServiceClient;
    private final TransactionRepository transactionRepository;
    private final BeneficiaryRepository beneficiaryRepository;

    public TransactionService(
            AccountServiceClient accountServiceClient,
            TransactionRepository transactionRepository,
            BeneficiaryRepository beneficiaryRepository) {
        this.accountServiceClient = accountServiceClient;
        this.transactionRepository = transactionRepository;
        this.beneficiaryRepository = beneficiaryRepository;
    }

    public String transferFunds(TransferRequestDTO transferRequest, Long authenticatedUserId) {
        // Verify that the authenticated user owns the source account
        verifyAccountOwnership(transferRequest.getFromAccountNumber(), authenticatedUserId);

        String transactionId = "TXN" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
        String description = transferRequest.getDescription();
        if (description == null || description.isBlank()) {
            description = "Transfer from " + transferRequest.getFromAccountNumber() + " to "
                    + transferRequest.getToAccountNumber();
        }

        try {
            // Debit from source account
            DebitRequestDTO debitRequest = DebitRequestDTO.builder()
                    .senderAccount(transferRequest.getFromAccountNumber())
                    .amount(transferRequest.getAmount())
                    .description(description)
                    .build();
            accountServiceClient.debitAccount(transferRequest.getFromAccountNumber(), debitRequest);

            // Credit to destination account
            CreditRequestDTO creditRequest = CreditRequestDTO.builder()
                    .senderAccount(transferRequest.getFromAccountNumber())
                    .amount(transferRequest.getAmount())
                    .description(description)
                    .build();
            accountServiceClient.creditAccount(transferRequest.getToAccountNumber(), creditRequest);

            // Log successful transaction
            Transaction transaction = new Transaction();
            transaction.setTransactionId(transactionId);
            transaction.setFromAccountNumber(transferRequest.getFromAccountNumber());
            transaction.setToAccountNumber(transferRequest.getToAccountNumber());
            transaction.setAmount(transferRequest.getAmount());
            transaction.setDescription(description);
            transaction.setStatus("SUCCESS");
            transactionRepository.save(transaction);

            return "Transfer successful. Transaction ID: " + transactionId;
        } catch (FeignException e) {
            // Preserve downstream status/message (400/403/404, etc.) instead of masking as
            // 500.
            Transaction transaction = new Transaction();
            transaction.setTransactionId(transactionId);
            transaction.setFromAccountNumber(transferRequest.getFromAccountNumber());
            transaction.setToAccountNumber(transferRequest.getToAccountNumber());
            transaction.setAmount(transferRequest.getAmount());
            transaction.setDescription(description);
            transaction.setStatus("FAILED");
            transactionRepository.save(transaction);

            throw e;
        } catch (Exception e) {
            // Log failed transaction
            Transaction transaction = new Transaction();
            transaction.setTransactionId(transactionId);
            transaction.setFromAccountNumber(transferRequest.getFromAccountNumber());
            transaction.setToAccountNumber(transferRequest.getToAccountNumber());
            transaction.setAmount(transferRequest.getAmount());
            transaction.setDescription(description);
            transaction.setStatus("FAILED");
            transactionRepository.save(transaction);

            throw new RuntimeException("Transfer failed: " + e.getMessage());
        }
    }

    public List<Transaction> getTransactionsByAccount(String accountNumber) {
        return transactionRepository.findByFromAccountNumberOrToAccountNumberOrderByCreatedAtDesc(accountNumber,
                accountNumber);
    }

    public List<Transaction> getTransactionsByAccountFiltered(
            String accountNumber,
            Long authenticatedUserId,
            String status,
            LocalDateTime fromDate,
            LocalDateTime toDate) {
        verifyAccountOwnership(accountNumber, authenticatedUserId);

        List<Transaction> transactions = transactionRepository
                .findByFromAccountNumberOrToAccountNumberOrderByCreatedAtDesc(accountNumber, accountNumber)
                .stream()
                .filter(t -> status == null || status.isBlank() || t.getStatus().equalsIgnoreCase(status))
                .filter(t -> fromDate == null || !t.getCreatedAt().isBefore(fromDate))
                .filter(t -> toDate == null || !t.getCreatedAt().isAfter(toDate))
                .collect(Collectors.toList());

        enrichSenderNames(transactions);
        return transactions;
    }

    public AccountInsightsDTO getAccountInsights(String accountNumber, Long authenticatedUserId) {
        verifyAccountOwnership(accountNumber, authenticatedUserId);

        List<Transaction> transactions = getTransactionsByAccount(accountNumber);
        BigDecimal totalSent = BigDecimal.ZERO;
        BigDecimal totalReceived = BigDecimal.ZERO;
        BigDecimal totalSuccessSent = BigDecimal.ZERO;
        BigDecimal totalSuccessReceived = BigDecimal.ZERO;
        LocalDateTime lastTransactionAt = null;

        for (Transaction t : transactions) {
            boolean isSent = accountNumber.equals(t.getFromAccountNumber());
            boolean isSuccess = "SUCCESS".equalsIgnoreCase(t.getStatus())
                    || "COMPLETED".equalsIgnoreCase(t.getStatus());
            BigDecimal amt = t.getAmount() == null ? BigDecimal.ZERO : t.getAmount();

            if (isSent) {
                totalSent = totalSent.add(amt);
                if (isSuccess) {
                    totalSuccessSent = totalSuccessSent.add(amt);
                }
            } else {
                totalReceived = totalReceived.add(amt);
                if (isSuccess) {
                    totalSuccessReceived = totalSuccessReceived.add(amt);
                }
            }

            if (lastTransactionAt == null
                    || (t.getCreatedAt() != null && t.getCreatedAt().isAfter(lastTransactionAt))) {
                lastTransactionAt = t.getCreatedAt();
            }
        }

        return AccountInsightsDTO.builder()
                .accountNumber(accountNumber)
                .totalTransactions(transactions.size())
                .totalSent(totalSent)
                .totalReceived(totalReceived)
                .totalSuccessSent(totalSuccessSent)
                .totalSuccessReceived(totalSuccessReceived)
                .lastTransactionAt(lastTransactionAt)
                .build();
    }

    public List<BeneficiaryDTO> getBeneficiaries(Long userId) {
        return beneficiaryRepository.findByUserIdOrderByFavoriteDescCreatedAtDesc(userId)
                .stream()
                .map(this::toBeneficiaryDTO)
                .collect(Collectors.toList());
    }

    public BeneficiaryDTO addBeneficiary(Long userId, BeneficiaryRequestDTO request) {
        Beneficiary beneficiary = beneficiaryRepository
                .findByUserIdAndAccountNumber(userId, request.getAccountNumber())
                .orElseGet(Beneficiary::new);

        beneficiary.setUserId(userId);
        beneficiary.setNickname(request.getNickname().trim());
        beneficiary.setAccountNumber(request.getAccountNumber().trim());
        beneficiary.setBankName(request.getBankName().trim());
        beneficiary.setIfscCode(request.getIfscCode() == null ? null : request.getIfscCode().trim());

        return toBeneficiaryDTO(beneficiaryRepository.save(beneficiary));
    }

    public void deleteBeneficiary(Long userId, Long beneficiaryId) {
        Beneficiary beneficiary = beneficiaryRepository.findByIdAndUserId(beneficiaryId, userId)
                .orElseThrow(() -> new UnauthorizedException("Beneficiary not found"));
        if (beneficiary.getId() == null) {
            throw new UnauthorizedException("Beneficiary id is missing");
        }
        beneficiaryRepository.deleteById(beneficiary.getId());
    }

    public BeneficiaryDTO setBeneficiaryFavorite(Long userId, Long beneficiaryId, boolean favorite) {
        Beneficiary beneficiary = beneficiaryRepository.findByIdAndUserId(beneficiaryId, userId)
                .orElseThrow(() -> new UnauthorizedException("Beneficiary not found"));
        beneficiary.setFavorite(favorite);
        return toBeneficiaryDTO(beneficiaryRepository.save(beneficiary));
    }

    private BeneficiaryDTO toBeneficiaryDTO(Beneficiary beneficiary) {
        return BeneficiaryDTO.builder()
                .id(beneficiary.getId())
                .nickname(beneficiary.getNickname())
                .accountNumber(beneficiary.getAccountNumber())
                .bankName(beneficiary.getBankName())
                .ifscCode(beneficiary.getIfscCode())
                .favorite(beneficiary.isFavorite())
                .createdAt(beneficiary.getCreatedAt())
                .build();
    }

    private void enrichSenderNames(List<Transaction> transactions) {
        Map<String, String> senderNameByAccount = new HashMap<>();
        for (Transaction transaction : transactions) {
            String fromAccount = transaction.getFromAccountNumber();
            if (fromAccount == null || fromAccount.isBlank()) {
                continue;
            }

            String cached = senderNameByAccount.get(fromAccount);
            if (cached != null) {
                transaction.setSenderName(cached);
                continue;
            }

            String resolvedName = fromAccount;
            try {
                var details = accountServiceClient.getAccountDetails(fromAccount);
                if (details != null && details.getAccountName() != null && !details.getAccountName().isBlank()) {
                    resolvedName = details.getAccountName();
                }
            } catch (Exception ignored) {
                // Keep account number fallback when account lookup fails.
            }

            senderNameByAccount.put(fromAccount, resolvedName);
            transaction.setSenderName(resolvedName);
        }
    }

    /**
     * Verifies that the given account number belongs to the authenticated user.
     * Throws UnauthorizedException if the user does not own the account.
     */
    private void verifyAccountOwnership(String accountNumber, Long userId) {
        try {
            var account = accountServiceClient.getAccountDetails(accountNumber);
            if (account == null || !account.getUserId().equals(userId)) {
                throw new UnauthorizedException("You do not have permission to perform transactions on this account");
            }
        } catch (FeignException.NotFound ex) {
            throw new UnauthorizedException("Account not found or you do not have access to this account");
        } catch (UnauthorizedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new RuntimeException("Unable to verify account ownership: " + ex.getMessage());
        }
    }
}

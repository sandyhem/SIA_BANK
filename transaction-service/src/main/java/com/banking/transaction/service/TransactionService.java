package com.banking.transaction.service;

import com.banking.transaction.client.AccountServiceClient;
import com.banking.transaction.dto.CreditRequestDTO;
import com.banking.transaction.dto.DebitRequestDTO;
import com.banking.transaction.dto.TransferRequestDTO;
import com.banking.transaction.entity.Transaction;
import com.banking.transaction.repository.TransactionRepository;
import com.banking.transaction.exception.UnauthorizedException;
import feign.FeignException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class TransactionService {

    private final AccountServiceClient accountServiceClient;
    private final TransactionRepository transactionRepository;

    public TransactionService(AccountServiceClient accountServiceClient, TransactionRepository transactionRepository) {
        this.accountServiceClient = accountServiceClient;
        this.transactionRepository = transactionRepository;
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
        return transactionRepository.findByFromAccountNumberOrToAccountNumber(accountNumber, accountNumber);
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

package com.banking.transaction.service;

import com.banking.transaction.client.AccountServiceClient;
import com.banking.transaction.dto.CreditRequestDTO;
import com.banking.transaction.dto.DebitRequestDTO;
import com.banking.transaction.dto.TransferRequestDTO;
import com.banking.transaction.entity.Transaction;
import com.banking.transaction.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
    
    public String transferFunds(TransferRequestDTO transferRequest) {
        String transactionId = "TXN" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
        
        try {
            // Debit from source account
            DebitRequestDTO debitRequest = DebitRequestDTO.builder()
                    .senderAccount(transferRequest.getFromAccountNumber())
                    .amount(transferRequest.getAmount())
                    .description(transferRequest.getDescription())
                    .build();
            accountServiceClient.debitAccount(transferRequest.getFromAccountNumber(), debitRequest);
            
            // Credit to destination account
            CreditRequestDTO creditRequest = CreditRequestDTO.builder()
                    .senderAccount(transferRequest.getFromAccountNumber())
                    .amount(transferRequest.getAmount())
                    .description(transferRequest.getDescription())
                    .build();
            accountServiceClient.creditAccount(transferRequest.getToAccountNumber(), creditRequest);
            
            // Log successful transaction
            Transaction transaction = new Transaction();
            transaction.setTransactionId(transactionId);
            transaction.setFromAccountNumber(transferRequest.getFromAccountNumber());
            transaction.setToAccountNumber(transferRequest.getToAccountNumber());
            transaction.setAmount(transferRequest.getAmount());
            transaction.setDescription(transferRequest.getDescription());
            transaction.setStatus("SUCCESS");
            transactionRepository.save(transaction);
            
            return "Transfer successful. Transaction ID: " + transactionId;
        } catch (Exception e) {
            // Log failed transaction
            Transaction transaction = new Transaction();
            transaction.setTransactionId(transactionId);
            transaction.setFromAccountNumber(transferRequest.getFromAccountNumber());
            transaction.setToAccountNumber(transferRequest.getToAccountNumber());
            transaction.setAmount(transferRequest.getAmount());
            transaction.setDescription(transferRequest.getDescription());
            transaction.setStatus("FAILED");
            transactionRepository.save(transaction);
            
            throw new RuntimeException("Transfer failed: " + e.getMessage());
        }
    }
}

package com.banking.transaction.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class AccountInsightsDTO {
    private String accountNumber;
    private long totalTransactions;
    private BigDecimal totalSent;
    private BigDecimal totalReceived;
    private BigDecimal totalSuccessSent;
    private BigDecimal totalSuccessReceived;
    private LocalDateTime lastTransactionAt;
}

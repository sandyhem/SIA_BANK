package com.banking.transaction.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class BeneficiaryDTO {
    private Long id;
    private String nickname;
    private String accountNumber;
    private String bankName;
    private String ifscCode;
    private boolean favorite;
    private LocalDateTime createdAt;
}

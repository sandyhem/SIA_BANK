package com.banking.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserKycDTO {
    private Long userId;
    private String username;
    private String kycStatus;
    private String customerId;
}

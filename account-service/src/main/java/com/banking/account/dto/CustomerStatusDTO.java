package com.banking.account.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerStatusDTO {
    private Long id;
    private String cifNumber;
    private Long userId;
    private String username;
    private String fullName;
    private String kycStatus;
    private String customerStatus;
}

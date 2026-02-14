package com.banking.auth.dto;

import lombok.Data;

@Data
public class UpdateKycStatusDTO {
    private String kycStatus; // PENDING, UNDER_REVIEW, VERIFIED, REJECTED
    private String verifiedBy; // Admin username
    private String remarks;
}

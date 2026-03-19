package com.banking.transaction.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BeneficiaryRequestDTO {

    @NotBlank
    private String nickname;

    @NotBlank
    private String accountNumber;

    @NotBlank
    private String bankName;

    private String ifscCode;
}

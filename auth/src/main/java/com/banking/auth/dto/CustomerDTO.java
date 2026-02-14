package com.banking.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDTO {
    private Long id;
    private String cifNumber;
    private Long userId;
    private String username;
    private String fullName;
    private String phone;
    private String address;
    private String city;
    private String state;
    private String postalCode;
    private String country;
    private String panNumber;
    private String aadhaarNumber;
    private String kycStatus;
    private String customerStatus;
    private String kycVerifiedAt;
    private String kycVerifiedBy;
}

package com.banking.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponseDTO {
    private String token;
    private String type = "Bearer";
    private Long userId;
    private String username;
    private String email;
    private String name;
    private String firstName;
    private String lastName;
    private String phone;
    private String customerId;
    private String kycStatus;
    private String role;

    public AuthResponseDTO(String token, Long userId, String username, String email, String name,
            String firstName, String lastName, String phone,
            String customerId, String kycStatus, String role) {
        this.token = token;
        this.userId = userId;
        this.username = username;
        this.email = email;
        this.name = name;
        this.firstName = firstName;
        this.lastName = lastName;
        this.phone = phone;
        this.customerId = customerId;
        this.kycStatus = kycStatus;
        this.role = role;
    }
}

package com.banking.auth.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Customer Information File (CIF) Entity
 * Represents the banking customer identity separate from authentication user
 */
@Entity
@Table(name = "customers")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cif_number", unique = true, nullable = false)
    private String cifNumber; // Customer Information File Number (e.g., CIF2026-XXXX)

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "phone", nullable = false)
    private String phone;

    @Column(name = "address")
    private String address;

    @Column(name = "city")
    private String city;

    @Column(name = "state")
    private String state;

    @Column(name = "postal_code")
    private String postalCode;

    @Column(name = "country")
    private String country;

    @Column(name = "date_of_birth")
    private LocalDateTime dateOfBirth;

    @Column(name = "pan_number")
    private String panNumber; // Permanent Account Number (India)

    @Column(name = "aadhaar_number")
    private String aadhaarNumber; // Aadhaar (India)

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false)
    private KycStatus kycStatus = KycStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "customer_status", nullable = false)
    private CustomerStatus customerStatus = CustomerStatus.INACTIVE;

    @Column(name = "kyc_verified_at")
    private LocalDateTime kycVerifiedAt;

    @Column(name = "kyc_verified_by")
    private String kycVerifiedBy; // Admin username who verified

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (cifNumber == null || cifNumber.isEmpty()) {
            cifNumber = generateCifNumber();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    private String generateCifNumber() {
        // Format: CIF2026-XXXX (year + random 4 digits)
        int year = LocalDateTime.now().getYear();
        int random = (int) (Math.random() * 9000) + 1000;
        return "CIF" + year + "-" + random;
    }

    public enum KycStatus {
        PENDING, // Initial state - documents not submitted
        UNDER_REVIEW, // Documents submitted, admin reviewing
        VERIFIED, // KYC approved
        REJECTED // KYC rejected
    }

    public enum CustomerStatus {
        INACTIVE, // CIF created but KYC not verified
        ACTIVE, // KYC verified, can open accounts
        SUSPENDED, // Temporarily suspended
        CLOSED // Customer relationship ended
    }
}

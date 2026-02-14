package com.banking.auth.controller;

import com.banking.auth.dto.CreateCustomerRequestDTO;
import com.banking.auth.dto.CustomerDTO;
import com.banking.auth.dto.UpdateKycStatusDTO;
import com.banking.auth.service.CustomerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;

    /**
     * Get all customers
     */
    @GetMapping
    public ResponseEntity<java.util.List<CustomerDTO>> getAllCustomers() {
        java.util.List<CustomerDTO> customers = customerService.getAllCustomers();
        return ResponseEntity.ok(customers);
    }

    /**
     * Create Customer Profile (CIF Generation)
     * Step 2 in banking flow: User → Customer
     */
    @PostMapping
    public ResponseEntity<CustomerDTO> createCustomer(
            @Valid @RequestBody CreateCustomerRequestDTO request,
            @RequestParam Long userId) {
        CustomerDTO customer = customerService.createCustomer(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(customer);
    }

    /**
     * Get customer by user ID
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<CustomerDTO> getCustomerByUserId(@PathVariable Long userId) {
        CustomerDTO customer = customerService.getCustomerByUserId(userId);
        return ResponseEntity.ok(customer);
    }

    /**
     * Get customer by CIF number
     */
    @GetMapping("/cif/{cifNumber}")
    public ResponseEntity<CustomerDTO> getCustomerByCif(@PathVariable String cifNumber) {
        CustomerDTO customer = customerService.getCustomerByCifNumber(cifNumber);
        return ResponseEntity.ok(customer);
    }

    /**
     * Update KYC Status (Admin endpoint)
     * Step 3 in banking flow: KYC Verification
     */
    @PutMapping("/cif/{cifNumber}/kyc")
    public ResponseEntity<CustomerDTO> updateKycStatus(
            @PathVariable String cifNumber,
            @Valid @RequestBody UpdateKycStatusDTO updateRequest,
            @RequestParam(required = false) String adminUsername) {

        String admin = adminUsername != null ? adminUsername : "SYSTEM";
        CustomerDTO customer = customerService.updateKycStatus(cifNumber, updateRequest, admin);
        return ResponseEntity.ok(customer);
    }

    /**
     * Check if customer is active and can open accounts
     */
    @GetMapping("/user/{userId}/active")
    public ResponseEntity<Map<String, Boolean>> isCustomerActive(@PathVariable Long userId) {
        boolean isActive = customerService.isCustomerActive(userId);
        return ResponseEntity.ok(Map.of("active", isActive, "canOpenAccounts", isActive));
    }
}

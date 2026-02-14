package com.banking.auth.service;

import com.banking.auth.dto.CreateCustomerRequestDTO;
import com.banking.auth.dto.CustomerDTO;
import com.banking.auth.dto.UpdateKycStatusDTO;

import java.util.List;

public interface CustomerService {
    CustomerDTO createCustomer(Long userId, CreateCustomerRequestDTO request);

    CustomerDTO getCustomerByUserId(Long userId);

    CustomerDTO getCustomerByCifNumber(String cifNumber);

    CustomerDTO updateKycStatus(String cifNumber, UpdateKycStatusDTO updateRequest, String adminUsername);

    boolean isCustomerActive(Long userId);

    List<CustomerDTO> getAllCustomers();
}

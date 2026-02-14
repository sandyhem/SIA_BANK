package com.banking.auth.service;

import com.banking.auth.dto.CreateCustomerRequestDTO;
import com.banking.auth.dto.CustomerDTO;
import com.banking.auth.dto.UpdateKycStatusDTO;
import com.banking.auth.entity.Customer;
import com.banking.auth.entity.User;
import com.banking.auth.repository.CustomerRepository;
import com.banking.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
@Transactional
public class CustomerServiceImpl implements CustomerService {

    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;

    @Override
    public CustomerDTO createCustomer(Long userId, CreateCustomerRequestDTO request) {
        // Check if user exists
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));

        // Check if customer already exists for this user
        if (customerRepository.existsByUserId(userId)) {
            throw new RuntimeException("Customer profile already exists for this user");
        }

        Customer customer = new Customer();
        customer.setUser(user);
        customer.setFullName(request.getFullName());
        customer.setPhone(request.getPhone());
        customer.setAddress(request.getAddress());
        customer.setCity(request.getCity());
        customer.setState(request.getState());
        customer.setPostalCode(request.getPostalCode());
        customer.setCountry(request.getCountry());

        if (request.getDateOfBirth() != null) {
            customer.setDateOfBirth(LocalDateTime.parse(request.getDateOfBirth() + "T00:00:00"));
        }

        customer.setPanNumber(request.getPanNumber());
        customer.setAadhaarNumber(request.getAadhaarNumber());
        customer.setKycStatus(Customer.KycStatus.PENDING);
        customer.setCustomerStatus(Customer.CustomerStatus.INACTIVE);

        Customer savedCustomer = customerRepository.save(customer);
        return mapToDTO(savedCustomer);
    }

    @Override
    public CustomerDTO getCustomerByUserId(Long userId) {
        Customer customer = customerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Customer not found for user ID: " + userId));
        return mapToDTO(customer);
    }

    @Override
    public CustomerDTO getCustomerByCifNumber(String cifNumber) {
        Customer customer = customerRepository.findByCifNumber(cifNumber)
                .orElseThrow(() -> new RuntimeException("Customer not found with CIF: " + cifNumber));
        return mapToDTO(customer);
    }

    @Override
    public CustomerDTO updateKycStatus(String cifNumber, UpdateKycStatusDTO updateRequest, String adminUsername) {
        Customer customer = customerRepository.findByCifNumber(cifNumber)
                .orElseThrow(() -> new RuntimeException("Customer not found with CIF: " + cifNumber));

        Customer.KycStatus newKycStatus = Customer.KycStatus.valueOf(updateRequest.getKycStatus().toUpperCase());
        customer.setKycStatus(newKycStatus);

        // If KYC is verified, activate customer
        if (newKycStatus == Customer.KycStatus.VERIFIED) {
            customer.setCustomerStatus(Customer.CustomerStatus.ACTIVE);
            customer.setKycVerifiedAt(LocalDateTime.now());
            customer.setKycVerifiedBy(adminUsername);
        } else if (newKycStatus == Customer.KycStatus.REJECTED) {
            customer.setCustomerStatus(Customer.CustomerStatus.INACTIVE);
        }

        Customer updatedCustomer = customerRepository.save(customer);
        return mapToDTO(updatedCustomer);
    }

    @Override
    public boolean isCustomerActive(Long userId) {
        return customerRepository.findByUserId(userId)
                .map(customer -> customer.getCustomerStatus() == Customer.CustomerStatus.ACTIVE &&
                        customer.getKycStatus() == Customer.KycStatus.VERIFIED)
                .orElse(false);
    }

    @Override
    public java.util.List<CustomerDTO> getAllCustomers() {
        return customerRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(java.util.stream.Collectors.toList());
    }

    private CustomerDTO mapToDTO(Customer customer) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        return CustomerDTO.builder()
                .id(customer.getId())
                .cifNumber(customer.getCifNumber())
                .userId(customer.getUser().getId())
                .username(customer.getUser().getUsername())
                .fullName(customer.getFullName())
                .phone(customer.getPhone())
                .address(customer.getAddress())
                .city(customer.getCity())
                .state(customer.getState())
                .postalCode(customer.getPostalCode())
                .country(customer.getCountry())
                .panNumber(customer.getPanNumber())
                .aadhaarNumber(customer.getAadhaarNumber())
                .kycStatus(customer.getKycStatus().name())
                .customerStatus(customer.getCustomerStatus().name())
                .kycVerifiedAt(
                        customer.getKycVerifiedAt() != null ? customer.getKycVerifiedAt().format(formatter) : null)
                .kycVerifiedBy(customer.getKycVerifiedBy())
                .build();
    }
}

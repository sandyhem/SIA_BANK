package com.banking.auth.repository;

import com.banking.auth.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    Optional<Customer> findByCifNumber(String cifNumber);

    Optional<Customer> findByUserId(Long userId);

    Optional<Customer> findByUserUsername(String username);

    boolean existsByUserId(Long userId);
}

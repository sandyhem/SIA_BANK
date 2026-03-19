package com.banking.transaction.repository;

import com.banking.transaction.entity.Beneficiary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BeneficiaryRepository extends JpaRepository<Beneficiary, Long> {
    List<Beneficiary> findByUserIdOrderByFavoriteDescCreatedAtDesc(Long userId);

    Optional<Beneficiary> findByIdAndUserId(Long id, Long userId);

    Optional<Beneficiary> findByUserIdAndAccountNumber(Long userId, String accountNumber);
}

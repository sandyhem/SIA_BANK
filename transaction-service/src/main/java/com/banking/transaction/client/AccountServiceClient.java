package com.banking.transaction.client;

import com.banking.transaction.dto.CreditRequestDTO;
import com.banking.transaction.dto.DebitRequestDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(name = "account-service", url = "${account-service.url}")
public interface AccountServiceClient {
    
    @PutMapping("/api/accounts/{accountNumber}/debit")
    String debitAccount(@PathVariable("accountNumber") String accountNumber, @RequestBody DebitRequestDTO debitRequest);
    
    @PutMapping("/api/accounts/{accountNumber}/credit")
    String creditAccount(@PathVariable("accountNumber") String accountNumber, @RequestBody CreditRequestDTO creditRequest);

}

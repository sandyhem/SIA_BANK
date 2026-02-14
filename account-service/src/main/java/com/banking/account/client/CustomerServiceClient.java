package com.banking.account.client;

import com.banking.account.dto.CustomerStatusDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "customer-service", url = "${auth.service.url:http://localhost:8083}")
public interface CustomerServiceClient {

    @GetMapping("/auth/api/customers/user/{userId}")
    CustomerStatusDTO getCustomerByUserId(@PathVariable("userId") Long userId);
}

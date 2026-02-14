package com.banking.account.client;

import com.banking.account.dto.UserKycDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "auth-service", url = "${auth.service.url:http://localhost:8083}")
public interface AuthServiceClient {

    @GetMapping("/auth/api/auth/user/{userId}/kyc-status")
    UserKycDTO getUserKycStatus(@PathVariable("userId") Long userId);
}

package com.banking.auth.service;

import com.banking.auth.dto.AuthResponseDTO;
import com.banking.auth.dto.LoginRequestDTO;
import com.banking.auth.dto.RegisterRequestDTO;
import com.banking.auth.dto.UserKycDTO;

import java.util.Map;

public interface AuthService {
    AuthResponseDTO register(RegisterRequestDTO registerRequest);

    AuthResponseDTO login(LoginRequestDTO loginRequest);

    Boolean validateToken(String token);

    UserKycDTO getUserKycStatus(Long userId);

    Map<String, Object> getCurrentUserSummary(String username);
}

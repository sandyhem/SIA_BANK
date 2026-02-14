package com.banking.auth.service;

import com.banking.auth.dto.AuthResponseDTO;
import com.banking.auth.dto.LoginRequestDTO;
import com.banking.auth.dto.RegisterRequestDTO;
import com.banking.auth.dto.UserKycDTO;
import com.banking.auth.entity.User;
import com.banking.auth.exception.UserAlreadyExistsException;
import com.banking.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final UnifiedJwtService unifiedJwtService;

    @Override
    @Transactional
    public AuthResponseDTO register(RegisterRequestDTO registerRequest) {
        if (userRepository.existsByUsername(registerRequest.getUsername())) {
            throw new UserAlreadyExistsException("Username already exists");
        }

        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            throw new UserAlreadyExistsException("Email already exists");
        }

        User user = new User();
        user.setUsername(registerRequest.getUsername());
        user.setEmail(registerRequest.getEmail());
        user.setFirstName(registerRequest.getFirstName());
        user.setLastName(registerRequest.getLastName());
        user.setPhone(registerRequest.getPhone());
        user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        user.setRole(registerRequest.getRole());
        user.setKycStatus("pending");
        user.setEnabled(true);

        userRepository.save(user);

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        registerRequest.getUsername(),
                        registerRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = unifiedJwtService.generateToken(authentication);

        return new AuthResponseDTO(jwt, user.getId(), user.getUsername(), user.getEmail(),
                user.getName(), user.getFirstName(), user.getLastName(),
                user.getPhone(), user.getCustomerId(), user.getKycStatus(),
                user.getRole().name());
    }

    @Override
    @Transactional
    public AuthResponseDTO login(LoginRequestDTO loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginRequest.getUsername(),
                        loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = unifiedJwtService.generateToken(authentication);

        User user = userRepository.findByUsername(loginRequest.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return new AuthResponseDTO(jwt, user.getId(), user.getUsername(), user.getEmail(),
                user.getName(), user.getFirstName(), user.getLastName(),
                user.getPhone(), user.getCustomerId(), user.getKycStatus(),
                user.getRole().name());
    }

    @Override
    public Boolean validateToken(String token) {
        return unifiedJwtService.validateToken(token);
    }

    @Override
    public UserKycDTO getUserKycStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));

        return UserKycDTO.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .kycStatus(user.getKycStatus())
                .customerId(user.getCustomerId())
                .build();
    }
}

package com.banking.auth.service;

import com.banking.auth.dto.AuthResponseDTO;
import com.banking.auth.dto.LoginRequestDTO;
import com.banking.auth.dto.RegisterRequestDTO;
import com.banking.auth.dto.UserKycDTO;
import com.banking.auth.entity.Customer;
import com.banking.auth.entity.Role;
import com.banking.auth.entity.User;
import com.banking.auth.exception.UserAlreadyExistsException;
import com.banking.auth.repository.CustomerRepository;
import com.banking.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

        private final UserRepository userRepository;
        private final CustomerRepository customerRepository;
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
                user.setRole(registerRequest.getRole() != null ? registerRequest.getRole() : Role.USER);
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
                final String loginId = loginRequest.getUsername() == null
                                ? ""
                                : loginRequest.getUsername().trim();

                User user = userRepository.findByUsername(loginId)
                                .or(() -> userRepository.findByEmail(loginId.toLowerCase(Locale.ROOT)))
                                .orElseThrow(() -> new RuntimeException("User not found"));

                Authentication authentication = authenticationManager.authenticate(
                                new UsernamePasswordAuthenticationToken(
                                                user.getUsername(),
                                                loginRequest.getPassword()));

                SecurityContextHolder.getContext().setAuthentication(authentication);
                String jwt = unifiedJwtService.generateToken(authentication);

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

                customerRepository.findByUserId(userId).ifPresent(customer -> {
                        final String customerKyc = customer.getKycStatus() == null
                                        ? null
                                        : customer.getKycStatus().name();
                        if (customerKyc != null && !customerKyc.equalsIgnoreCase(user.getKycStatus())) {
                                user.setKycStatus(customerKyc);
                                userRepository.save(user);
                        }
                });

                return UserKycDTO.builder()
                                .userId(user.getId())
                                .username(user.getUsername())
                                .kycStatus(user.getKycStatus())
                                .customerId(user.getCustomerId())
                                .build();
        }

        @Override
        public Map<String, Object> getCurrentUserSummary(String username) {
                User user = userRepository.findByUsername(username)
                                .orElseThrow(() -> new RuntimeException("User not found with username: " + username));

                Map<String, Object> summary = new HashMap<>();
                summary.put("userId", user.getId());
                summary.put("username", user.getUsername());
                summary.put("role", user.getRole() == null ? "USER" : user.getRole().name());
                summary.put("kycStatus", user.getKycStatus());
                return summary;
        }
}

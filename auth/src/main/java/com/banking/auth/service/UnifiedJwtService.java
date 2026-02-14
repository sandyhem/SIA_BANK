package com.banking.auth.service;

import com.banking.auth.security.JwtTokenProvider;
import com.banking.auth.security.PQJwtTokenProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

/**
 * Unified JWT service that delegates to either standard or PQ JWT provider
 * based on configuration.
 */
@Service
public class UnifiedJwtService {

    @Autowired
    private JwtTokenProvider standardProvider;

    @Autowired
    private PQJwtTokenProvider pqProvider;

    @Value("${jwt.use-post-quantum:false}")
    private boolean usePostQuantum;

    public String generateToken(Authentication authentication) {
        if (usePostQuantum) {
            return pqProvider.generateToken(authentication);
        } else {
            return standardProvider.generateToken(authentication);
        }
    }

    public String generateToken(String username, Long userId) {
        if (usePostQuantum) {
            return pqProvider.generateToken(username, userId);
        } else {
            // For standard provider, we'll just use the authentication-based method
            // This is a simplified approach
            throw new UnsupportedOperationException("Standard provider requires Authentication object");
        }
    }

    public String getUsernameFromToken(String token) {
        if (usePostQuantum) {
            return pqProvider.getUsernameFromToken(token);
        } else {
            return standardProvider.getUsernameFromToken(token);
        }
    }

    public boolean validateToken(String token) {
        if (usePostQuantum) {
            return pqProvider.validateToken(token);
        } else {
            return standardProvider.validateToken(token);
        }
    }

    public boolean isPostQuantumEnabled() {
        return usePostQuantum;
    }
}

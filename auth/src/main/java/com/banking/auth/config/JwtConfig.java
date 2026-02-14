package com.banking.auth.config;

import com.banking.auth.security.JwtTokenProvider;
import com.banking.auth.security.PQJwtTokenProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * Configuration for JWT token providers.
 * Allows switching between standard HMAC-based JWT and Post-Quantum ML-DSA-65
 * based JWT.
 */
@Configuration
public class JwtConfig {

    @Value("${jwt.use-post-quantum:false}")
    private boolean usePostQuantum;

    /**
     * Primary JWT token provider based on configuration.
     * Set jwt.use-post-quantum=true in application.yml to use PQ algorithms.
     */
    @Bean
    @Primary
    public Object primaryJwtTokenProvider(JwtTokenProvider standardProvider,
            PQJwtTokenProvider pqProvider) {
        if (usePostQuantum) {
            System.out.println("Using Post-Quantum JWT Token Provider (ML-DSA-65)");
            return pqProvider;
        } else {
            System.out.println("Using Standard JWT Token Provider (HMAC-SHA256)");
            return standardProvider;
        }
    }
}

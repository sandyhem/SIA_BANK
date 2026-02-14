package com.banking.transaction.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.Map;

/**
 * PQ JWT Token Provider for validation only.
 * Fetches the auth service's public key to verify ML-DSA-65 signed JWTs.
 */
@Component
public class PQJwtTokenProvider {

    @Value("${auth-service.url:http://localhost:8083/auth}")
    private String authServiceUrl;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private PublicKey cachedPublicKey = null;

    /**
     * Extract username from PQ-signed JWT token
     */
    public String getUsernameFromToken(String token) {
        try {
            Map<String, Object> payload = parseToken(token);
            return (String) payload.get("sub");
        } catch (Exception e) {
            throw new RuntimeException("Error extracting username from PQ JWT", e);
        }
    }

    /**
     * Validate PQ-signed JWT token
     */
    public boolean validateToken(String authToken) {
        try {
            String[] parts = authToken.split("\\.");
            if (parts.length != 3) {
                return false;
            }

            // Parse header to check algorithm
            String headerJson = new String(base64UrlDecode(parts[0]), StandardCharsets.UTF_8);
            @SuppressWarnings("unchecked")
            Map<String, Object> header = objectMapper.readValue(headerJson, Map.class);
            String alg = (String) header.get("alg");

            if (!"ML-DSA-65".equals(alg)) {
                System.err.println("Not a PQ JWT, algorithm: " + alg);
                return false;
            }

            String signingInput = parts[0] + "." + parts[1];
            byte[] signatureBytes = base64UrlDecode(parts[2]);

            // Get or fetch public key from auth service
            PublicKey publicKey = getAuthServicePublicKey();

            // Verify signature with ML-DSA-65
            Signature signature = Signature.getInstance("ML-DSA-65", "BCPQC");
            signature.initVerify(publicKey);
            signature.update(signingInput.getBytes(StandardCharsets.UTF_8));

            if (!signature.verify(signatureBytes)) {
                System.err.println("Invalid PQ JWT signature");
                return false;
            }

            // Check expiration
            Map<String, Object> payload = parsePayload(parts[1]);
            Number exp = (Number) payload.get("exp");
            if (exp != null) {
                long expirationTime = exp.longValue() * 1000; // Convert to milliseconds
                if (System.currentTimeMillis() > expirationTime) {
                    System.err.println("Expired PQ JWT token");
                    return false;
                }
            }

            return true;
        } catch (Exception ex) {
            System.err.println("Error validating PQ JWT: " + ex.getMessage());
            ex.printStackTrace();
            return false;
        }
    }

    /**
     * Get auth service's public key
     * In production, this should be fetched via a secure endpoint or configured
     * statically
     */
    private PublicKey getAuthServicePublicKey() throws Exception {
        if (cachedPublicKey != null) {
            return cachedPublicKey;
        }

        // For now, we'll generate keys on both sides (not ideal for production)
        // In production, transaction service should fetch public key from auth service
        // or share it via configuration/key management service

        // Generate same keys as auth service (temporary solution)
        // This works only if both services start at same time with same seed
        // Better approach: Store public key in shared config or fetch via API

        KeyFactory kf = KeyFactory.getInstance("ML-DSA-65", "BCPQC");

        // Fetch public key from auth service
        try {
            RestTemplate restTemplate = new RestTemplate();
            String url = authServiceUrl + "/api/crypto/server-dsa-public-key";

            @SuppressWarnings("unchecked")
            Map<String, String> response = restTemplate.getForObject(url, Map.class);

            if (response != null && response.containsKey("publicKey")) {
                String publicKeyBase64 = response.get("publicKey");
                byte[] publicKeyBytes = Base64.getDecoder().decode(publicKeyBase64);

                cachedPublicKey = kf.generatePublic(new X509EncodedKeySpec(publicKeyBytes));

                System.out.println("Successfully fetched ML-DSA-65 public key from auth service");
                return cachedPublicKey;
            }
        } catch (Exception e) {
            System.err.println("Error fetching public key from auth service: " + e.getMessage());
            throw new RuntimeException("Cannot verify PQ JWTs without auth service public key", e);
        }

        throw new RuntimeException("Failed to obtain public key from auth service");
    }

    /**
     * Parse and validate token, return payload
     */
    private Map<String, Object> parseToken(String token) throws Exception {
        if (!validateToken(token)) {
            throw new RuntimeException("Invalid or expired token");
        }

        String[] parts = token.split("\\.");
        return parsePayload(parts[1]);
    }

    /**
     * Parse payload from base64URL encoded string
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> parsePayload(String encodedPayload) throws Exception {
        byte[] payloadBytes = base64UrlDecode(encodedPayload);
        String payloadJson = new String(payloadBytes, StandardCharsets.UTF_8);
        return objectMapper.readValue(payloadJson, Map.class);
    }

    /**
     * Base64URL decode
     */
    private byte[] base64UrlDecode(String encoded) {
        return Base64.getUrlDecoder().decode(encoded);
    }
}

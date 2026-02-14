package com.banking.auth.security;

import com.banking.auth.controller.ServerKeyStore;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * Post-Quantum JWT Token Provider using ML-DSA-65 (Dilithium) for digital
 * signatures.
 * This provides quantum-resistant authentication tokens.
 * 
 * Note: Since JJWT doesn't support PQC algorithms, we manually construct JWTs.
 */
@Component
public class PQJwtTokenProvider {

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    @Autowired
    private ServerKeyStore serverKeyStore;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Generate a JWT token signed with ML-DSA-65 post-quantum signature algorithm
     */
    public String generateToken(Authentication authentication) {
        UserDetailsImpl userPrincipal = (UserDetailsImpl) authentication.getPrincipal();
        return generateToken(userPrincipal.getUsername(), userPrincipal.getId());
    }

    /**
     * Generate token with custom userId (for login/register)
     */
    public String generateToken(String username, Long userId) {
        try {
            Date now = new Date();
            Date expiryDate = new Date(now.getTime() + jwtExpiration);

            // Create JWT header
            Map<String, Object> header = new HashMap<>();
            header.put("alg", "ML-DSA-65");
            header.put("typ", "JWT");

            // Create JWT payload
            Map<String, Object> payload = new HashMap<>();
            payload.put("sub", username);
            payload.put("iat", now.getTime() / 1000);
            payload.put("exp", expiryDate.getTime() / 1000);
            payload.put("userId", userId);
            payload.put("pq", true);

            // Base64URL encode header and payload
            String headerJson = objectMapper.writeValueAsString(header);
            String payloadJson = objectMapper.writeValueAsString(payload);

            String encodedHeader = base64UrlEncode(headerJson.getBytes(StandardCharsets.UTF_8));
            String encodedPayload = base64UrlEncode(payloadJson.getBytes(StandardCharsets.UTF_8));

            // Create signing input
            String signingInput = encodedHeader + "." + encodedPayload;

            // Sign with ML-DSA-65
            PrivateKey privateKey = serverKeyStore.getDsaPrivate();
            Signature signature = Signature.getInstance("ML-DSA-65", "BC");
            signature.initSign(privateKey);
            signature.update(signingInput.getBytes(StandardCharsets.UTF_8));
            byte[] signatureBytes = signature.sign();

            // Base64URL encode signature
            String encodedSignature = base64UrlEncode(signatureBytes);

            // Construct final JWT
            return signingInput + "." + encodedSignature;

        } catch (Exception e) {
            throw new RuntimeException("Error generating PQ JWT token", e);
        }
    }

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

            String signingInput = parts[0] + "." + parts[1];
            byte[] signatureBytes = base64UrlDecode(parts[2]);

            // Verify signature with ML-DSA-65
            PublicKey publicKey = serverKeyStore.getDsaPublic();
            Signature signature = Signature.getInstance("ML-DSA-65", "BC");
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
            return false;
        }
    }

    /**
     * Get userId from token
     */
    public Long getUserIdFromToken(String token) {
        try {
            Map<String, Object> payload = parseToken(token);
            Number userId = (Number) payload.get("userId");
            return userId != null ? userId.longValue() : null;
        } catch (Exception e) {
            throw new RuntimeException("Error extracting userId from PQ JWT", e);
        }
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
     * Base64URL encode (URL-safe, no padding)
     */
    private String base64UrlEncode(byte[] data) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(data);
    }

    /**
     * Base64URL decode
     */
    private byte[] base64UrlDecode(String encoded) {
        return Base64.getUrlDecoder().decode(encoded);
    }
}

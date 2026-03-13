# Post-Quantum Cryptography Integration Guide

## Overview

This authentication service now supports **Post-Quantum Cryptography (PQC)** using NIST-approved algorithms:
- **ML-DSA-65** (previously Dilithium3) - Digital signatures for JWT signing
- **ML-KEM-768** (previously Kyber768) - Key encapsulation mechanism for secure key exchange

## Features

### 1. Post-Quantum JWT Tokens
JWTs can be signed using ML-DSA-65 instead of traditional HMAC-SHA256, providing quantum-resistant authentication.

### 2. Crypto API Endpoints
- **Generate PQ Keys**: `POST /api/crypto/generate-keys` - Generate ML-DSA-65 key pairs for clients
- **Server KEM Public Key**: `GET /api/crypto/server-kem-public-key` - Get server's ML-KEM-768 public key
- **Sign Data**: `POST /api/crypto/sign` - Sign data using ML-DSA-65
- **Encapsulate**: `POST /api/crypto/encapsulate` - Perform ML-KEM-768 key encapsulation

## Configuration

### Enable Post-Quantum JWT (application.yml)

```yaml
jwt:
  use-post-quantum: true  # Set to true for ML-DSA-65, false for HMAC-SHA256
```

### Dependencies (pom.xml)

The following BouncyCastle dependencies are required:

```xml
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcprov-jdk18on</artifactId>
    <version>1.80</version>
</dependency>
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcpkix-jdk18on</artifactId>
    <version>1.80</version>
</dependency>
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcprov-ext-jdk18on</artifactId>
    <version>1.80</version>
</dependency>
```

## Architecture Components

### 1. PQCProviderConfig
Registers the BouncyCastle PQC provider at application startup.

### 2. ServerKeyStore
Manages server-side ML-KEM and ML-DSA key pairs. Keys are generated once at startup.

### 3. PQJwtTokenProvider
Provides JWT generation and validation using ML-DSA-65 signatures.

### 4. UnifiedJwtService
Unified service that delegates to either standard or PQ JWT provider based on configuration.

### 5. HybridJwtAuthenticationFilter
Security filter that supports both standard and PQ JWT tokens.

### 6. CryptoController
REST API for PQ cryptographic operations.

## Usage Examples

### 1. Using Post-Quantum JWTs

#### Enable PQ Mode
Set in `application.yml`:
```yaml
jwt:
  use-post-quantum: true
```

#### Login/Register
The authentication endpoints work the same way, but tokens will be signed with ML-DSA-65:

```bash
curl -X POST http://localhost:8083/auth/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user",
    "password": "password"
  }'
```

Response includes a PQ-signed JWT:
```json
{
  "token": "eyJhbGc...[ML-DSA-65 signed JWT]",
  "username": "user",
  "email": "user@example.com",
  "role": "USER"
}
```

### 2. Generate PQ Key Pair for Client

```bash
curl -X POST http://localhost:8083/auth/api/crypto/generate-keys
```

Response:
```json
{
  "publicKey": "MIIHzjANBg...",
  "privateKey": "MIIchQIBAD..."
}
```

### 3. Get Server's KEM Public Key

```bash
curl http://localhost:8083/auth/api/crypto/server-kem-public-key
```

Response:
```json
{
  "publicKey": "MIIFrzANBg...",
  "privateKey": null
}
```

### 4. Sign Data with ML-DSA-65

```bash
curl -X POST http://localhost:8083/auth/api/crypto/sign \
  -H "Content-Type: application/json" \
  -d '{
    "privateKey": "MIIchQIBAD...",
    "sessionId": "session123",
    "serverNonce": "bm9uY2U="
  }'
```

Response:
```json
{
  "signature": "ZGlsaXRoaXVt..."
}
```

### 5. Encapsulate Shared Secret

```bash
curl -X POST http://localhost:8083/auth/api/crypto/encapsulate \
  -H "Content-Type: application/json" \
  -d '{
    "serverPublicKey": "MIIFrzANBg..."
  }'
```

Response:
```json
{
  "ciphertext": "a3liZXI3Njg=",
  "sharedSecret": null
}
```

## Security Considerations

### Quantum Resistance
- **ML-DSA-65**: NIST security level 3, resistant to quantum attacks from Shor's algorithm
- **ML-KEM-768**: NIST security level 3, resistant to quantum attacks on key exchange

### Migration Strategy

1. **Phase 1**: Run in standard mode (`use-post-quantum: false`)
2. **Phase 2**: Enable PQ mode for new tokens while accepting both types
3. **Phase 3**: Full PQ mode after all clients upgraded

The `HybridJwtAuthenticationFilter` supports both token types simultaneously.

### Performance Impact

Post-quantum algorithms have different performance characteristics:

| Operation | ML-DSA-65 | HMAC-SHA256 |
|-----------|-----------|-------------|
| Key Gen | ~50ms | <1ms |
| Sign | ~2ms | <1ms |
| Verify | ~1ms | <1ms |
| Key Size (Public) | ~2KB | 32 bytes |
| Signature Size | ~3KB | 32 bytes |

JWT tokens will be significantly larger with PQ signatures (~3-4KB vs ~200 bytes).

## Troubleshooting

### Provider Not Found
If you see "NoSuchAlgorithmException: ML-DSA-65 not found":
- Ensure PQCProviderConfig is being loaded
- Verify BouncyCastle PQC dependencies are in classpath
- Check provider registration in ServerKeyStore.init()

### Invalid Signature
- Ensure both client and server use the same public/private key pair
- Verify the correct provider (standard vs PQ) is being used
- Check that keys are in correct format (PKCS8 for private, X509 for public)

### Token Size Issues
PQ-signed JWTs are larger (~4KB). Ensure:
- HTTP header size limits can accommodate larger tokens
- Network bandwidth can handle larger token sizes
- Storage systems account for larger token sizes

## Testing

Run the auth service:
```bash
cd auth
mvn clean install
mvn spring-boot:run
```

The service will log which JWT provider is active:
```
Using Post-Quantum JWT Token Provider (ML-DSA-65)
```
or
```
Using Standard JWT Token Provider (HMAC-SHA256)
```

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [BouncyCastle PQC Documentation](https://www.bouncycastle.org/java.html)
- [ML-DSA (FIPS 204)](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.204.pdf)
- [ML-KEM (FIPS 203)](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf)

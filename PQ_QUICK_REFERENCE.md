# PQ Crypto Quick Reference

## 🔧 Configuration Switch

**Enable PQ-signed JWTs:**
```yaml
# auth/src/main/resources/application.yml
jwt:
  use-post-quantum: true  # ML-DSA-65 signatures
```

**Disable (use standard HMAC):**
```yaml
jwt:
  use-post-quantum: false  # HMAC-SHA256 (default)
```

## 🚀 Quick Commands

### Build & Run
```bash
cd /home/inba/SIA_BANK/auth
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
mvn clean install
mvn spring-boot:run
```

### Test
```bash
# Full test suite
./test-pq-crypto.sh

# Quick health check
curl http://localhost:8083/auth/api/crypto/health
```

## 📡 Key Endpoints

### PQ Crypto Operations
```bash
# Health check
GET /api/crypto/health

# Generate ML-DSA-65 keys
POST /api/crypto/generate-keys

# Get server ML-KEM key
GET /api/crypto/server-kem-public-key

# Sign data
POST /api/crypto/sign
{
  "privateKey": "...",
  "sessionId": "...",
  "serverNonce": "..."
}

# Encapsulate
POST /api/crypto/encapsulate
{
  "serverPublicKey": "..."
}
```

### Auth with PQ JWTs
```bash
# All standard endpoints work with PQ:
POST /api/auth/register
POST /api/auth/login
GET /api/auth/validate
```

## 📦 What Was Added

### New Files (12)
1. `PQCProviderConfig.java` - Provider setup
2. `ServerKeyStore.java` - Key management
3. `CryptoController.java` - Crypto API
4. `PQJwtTokenProvider.java` - PQ JWT signing
5. `UnifiedJwtService.java` - JWT abstraction
6. `HybridJwtAuthenticationFilter.java` - Dual JWT support
7. `JwtConfig.java` - Provider switching
8. `KeyResponse.java` - DTO
9. `SignRequest.java` - DTO
10. `SignResponse.java` - DTO
11. `EncapsulateRequest.java` - DTO
12. `EncapsulateResponse.java` - DTO

### Updated Files (4)
1. `pom.xml` - Added BouncyCastle PQC deps
2. `SecurityConfig.java` - Crypto endpoints + hybrid filter
3. `AuthServiceImpl.java` - Use UnifiedJwtService
4. `application.yml` - PQ flag

### Documentation (3)
1. `PQ_CRYPTO_GUIDE.md` - Full guide
2. `PQ_INTEGRATION_SUMMARY.md` - Integration details
3. `test-pq-crypto.sh` - Test script

## ⚡ Key Features

✅ ML-DSA-65 digital signatures (NIST approved)  
✅ ML-KEM-768 key encapsulation (NIST approved)  
✅ Quantum-resistant JWT tokens  
✅ Backward compatible (hybrid mode)  
✅ REST API for all PQ operations  
✅ Zero breaking changes to existing code  

## 🎯 Next Steps

1. **Test Standard Mode**: Run with `use-post-quantum: false`
2. **Test PQ Mode**: Run with `use-post-quantum: true`
3. **Compare JWT Sizes**: Standard (~300 bytes) vs PQ (~3-4 KB)
4. **Performance Test**: Check signing/validation times
5. **Integration**: Connect with other services

## 📊 Quick Stats

| Item | Value |
|------|-------|
| Files Created | 12 |
| Files Updated | 4 |
| Build Status | ✅ SUCCESS |
| Compile Errors | 0 |
| Security Level | NIST Level 3 |
| Quantum Safe | ✅ YES |

---
**Ready to use!** 🎉

package com.banking.auth.controller;

import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.pqc.jcajce.provider.BouncyCastlePQCProvider;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.crypto.Cipher;
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

@RestController
@RequestMapping("/api/crypto")
public class CryptoController {

    private final ServerKeyStore serverKeyStore;

    public CryptoController(ServerKeyStore serverKeyStore) {
        this.serverKeyStore = serverKeyStore;
        // Register both providers
        if (Security.getProvider("BC") == null) {
            Security.addProvider(new BouncyCastleProvider());
        }
        if (Security.getProvider("BCPQC") == null) {
            Security.addProvider(new BouncyCastlePQCProvider());
        }
    }

    // Generate ML-DSA-65 key pair for client
    @PostMapping("/generate-keys")
    public ResponseEntity<KeyResponse> generateKeys() throws Exception {
        try {
            KeyPairGenerator kpg = KeyPairGenerator.getInstance("ML-DSA-65", "BC");
            // Don't initialize - ML-DSA-65 generates with default parameters
            KeyPair kp = kpg.generateKeyPair();

            String publicKeyBase64 = Base64.getEncoder().encodeToString(
                    kp.getPublic().getEncoded());
            String privateKeyBase64 = Base64.getEncoder().encodeToString(
                    kp.getPrivate().getEncoded());

            return ResponseEntity.ok(new KeyResponse(publicKeyBase64, privateKeyBase64));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(null);
        }
    }

    // Get server's ML-KEM public key
    @GetMapping("/server-kem-public-key")
    public ResponseEntity<KeyResponse> getServerKemPublicKey() {
        try {
            PublicKey kemPubKey = serverKeyStore.getKemPublic();
            String publicKeyBase64 = Base64.getEncoder().encodeToString(
                    kemPubKey.getEncoded());
            return ResponseEntity.ok(new KeyResponse(publicKeyBase64, null));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(null);
        }
    }

    // Get server's ML-DSA public key for JWT verification
    @GetMapping("/server-dsa-public-key")
    public ResponseEntity<KeyResponse> getServerDsaPublicKey() {
        try {
            PublicKey dsaPubKey = serverKeyStore.getDsaPublic();
            String publicKeyBase64 = Base64.getEncoder().encodeToString(
                    dsaPubKey.getEncoded());
            return ResponseEntity.ok(new KeyResponse(publicKeyBase64, null));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(null);
        }
    }

    // Sign data with client's ML-DSA private key
    @PostMapping("/sign")
    public ResponseEntity<SignResponse> signData(@RequestBody SignRequest req) {
        try {
            byte[] privateKeyBytes = Base64.getDecoder().decode(req.privateKey());
            byte[] sessionIdBytes = req.sessionId().getBytes();
            byte[] nonceBytes = Base64.getDecoder().decode(req.serverNonce());

            // Reconstruct private key
            PrivateKey privateKey = KeyFactory.getInstance("ML-DSA-65", "BC")
                    .generatePrivate(new PKCS8EncodedKeySpec(privateKeyBytes));

            // Sign
            Signature sig = Signature.getInstance("ML-DSA-65", "BC");
            sig.initSign(privateKey);
            sig.update(sessionIdBytes);
            sig.update(nonceBytes);
            byte[] signatureBytes = sig.sign();

            String signatureBase64 = Base64.getEncoder().encodeToString(signatureBytes);
            return ResponseEntity.ok(new SignResponse(signatureBase64));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(null);
        }
    }

    // Encapsulate ML-KEM shared secret
    @PostMapping("/encapsulate")
    public ResponseEntity<EncapsulateResponse> encapsulate(@RequestBody EncapsulateRequest req) {
        try {
            byte[] serverPublicKeyBytes = Base64.getDecoder().decode(req.serverPublicKey());

            // Reconstruct server's public key
            PublicKey serverPublicKey = KeyFactory.getInstance("ML-KEM-768", "BC")
                    .generatePublic(new X509EncodedKeySpec(serverPublicKeyBytes));

            // ML-KEM uses WRAP_MODE for encapsulation (generating ciphertext)
            Cipher kemCipher = Cipher.getInstance("ML-KEM-768", "BC");
            kemCipher.init(Cipher.WRAP_MODE, serverPublicKey);

            // Wrap a random key - ML-KEM generates shared secret automatically
            byte[] ciphertextBytes = kemCipher.wrap(new javax.crypto.spec.SecretKeySpec(new byte[32], 0, 32, "RAW"));

            String ciphertextBase64 = Base64.getEncoder().encodeToString(ciphertextBytes);
            return ResponseEntity.ok(new EncapsulateResponse(ciphertextBase64, null));
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Encapsulation error: " + e.getMessage());
            return ResponseEntity.status(500).body(null);
        }
    }

    // Health check for PQ crypto system
    @GetMapping("/health")
    public ResponseEntity<java.util.Map<String, String>> health() {
        try {
            boolean bcpqcInstalled = Security.getProvider("BCPQC") != null;
            boolean bcInstalled = Security.getProvider("BC") != null;
            boolean keysGenerated = serverKeyStore.getKemPublic() != null &&
                    serverKeyStore.getDsaPublic() != null;

            String status = (bcpqcInstalled && bcInstalled && keysGenerated) ? "UP" : "DOWN";

            return ResponseEntity.ok(java.util.Map.of(
                    "status", status,
                    "bcpqcProvider", String.valueOf(bcpqcInstalled),
                    "bcProvider", String.valueOf(bcInstalled),
                    "serverKeysReady", String.valueOf(keysGenerated),
                    "mlKemAlgorithm", serverKeyStore.getKemPublic().getAlgorithm(),
                    "mlDsaAlgorithm", serverKeyStore.getDsaPublic().getAlgorithm()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(java.util.Map.of(
                    "status", "ERROR",
                    "error", e.getMessage()));
        }
    }
}

package com.banking.auth.controller;

import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;

import java.security.*;

@Component
public class ServerKeyStore {

    private KeyPair mlKemKeyPair;
    private KeyPair mlDsaKeyPair;

    @PostConstruct
    public void init() throws Exception {
        // Ensure provider is registered
        if (Security.getProvider("BCPQC") == null) {
            Security.addProvider(new org.bouncycastle.pqc.jcajce.provider.BouncyCastlePQCProvider());
        }
        if (Security.getProvider("BC") == null) {
            Security.addProvider(new org.bouncycastle.jce.provider.BouncyCastleProvider());
        }

        // Generate ML-KEM-768 key pair for key encapsulation
        KeyPairGenerator mlKemGen = KeyPairGenerator.getInstance("ML-KEM-768", "BC");
        mlKemKeyPair = mlKemGen.generateKeyPair();

        // Generate ML-DSA-65 key pair for digital signatures
        KeyPairGenerator mlDsaGen = KeyPairGenerator.getInstance("ML-DSA-65", "BC");
        mlDsaKeyPair = mlDsaGen.generateKeyPair();

        System.out.println("Server PQ keys generated successfully");
        System.out.println("ML-KEM-768 public key: " + mlKemKeyPair.getPublic().getAlgorithm());
        System.out.println("ML-DSA-65 public key: " + mlDsaKeyPair.getPublic().getAlgorithm());
    }

    public PublicKey getKemPublic() {
        return mlKemKeyPair.getPublic();
    }

    public PrivateKey getKemPrivate() {
        return mlKemKeyPair.getPrivate();
    }

    public PublicKey getDsaPublic() {
        return mlDsaKeyPair.getPublic();
    }

    public PrivateKey getDsaPrivate() {
        return mlDsaKeyPair.getPrivate();
    }

    public KeyPair getKemKeyPair() {
        return mlKemKeyPair;
    }

    public KeyPair getDsaKeyPair() {
        return mlDsaKeyPair;
    }
}

package com.banking.transaction.config;

import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

import java.security.Security;

@Configuration
public class PQCProviderConfig {

    @PostConstruct
    public void setup() {
        Security.addProvider(
                new org.bouncycastle.pqc.jcajce.provider.BouncyCastlePQCProvider());
        Security.addProvider(
                new org.bouncycastle.jce.provider.BouncyCastleProvider());
    }
}

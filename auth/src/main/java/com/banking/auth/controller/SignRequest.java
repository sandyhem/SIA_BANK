package com.banking.auth.controller;

public record SignRequest(String privateKey, String sessionId, String serverNonce) {
}

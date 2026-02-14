package com.banking.auth.controller;

public record EncapsulateResponse(String ciphertext, String sharedSecret) {
}

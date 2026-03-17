package com.banking.auth.exception;

public class InvalidKycStatusException extends RuntimeException {
    public InvalidKycStatusException(String message) {
        super(message);
    }
}

package com.banking.auth.exception;

public class CustomerProfileAlreadyExistsException extends RuntimeException {
    public CustomerProfileAlreadyExistsException(String message) {
        super(message);
    }
}

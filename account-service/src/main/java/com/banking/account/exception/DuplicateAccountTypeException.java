package com.banking.account.exception;

public class DuplicateAccountTypeException extends RuntimeException {
    public DuplicateAccountTypeException(String message) {
        super(message);
    }
}

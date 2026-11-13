package com.comodeu.exception;

/** Requisição com dados inválidos. Vira HTTP 400. */
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}

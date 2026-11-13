package com.comodeu.exception;

/** Registro inexistente (ou de outro usuário). Vira HTTP 404. */
public class NotFoundException extends RuntimeException {
    public NotFoundException(String message) {
        super(message);
    }
}

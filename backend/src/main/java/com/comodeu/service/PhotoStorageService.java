package com.comodeu.service;

import com.comodeu.exception.BadRequestException;
import com.comodeu.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * Guarda as fotos das evidências como arquivos em disco, fora do banco.
 *
 * Pasta definida em app.storage.photos-dir (variável PHOTOS_DIR).
 * No banco fica só o nome do arquivo (evidences.photo_path), gerado aqui
 * como UUID + extensão, o que evita colisões e nomes maliciosos.
 */
@Slf4j
@Service
public class PhotoStorageService {

    private final Path root;

    public PhotoStorageService(@Value("${app.storage.photos-dir}") String photosDir) {
        this.root = Path.of(photosDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            throw new UncheckedIOException("Não foi possível criar a pasta de fotos: " + root, e);
        }
        log.info("Pasta de fotos: {}", root);
    }

    /** Valida que os bytes são uma imagem (JPEG, PNG ou WebP), salva e devolve o nome do arquivo. */
    public String save(byte[] bytes) {
        if (bytes == null || bytes.length == 0) {
            throw new BadRequestException("Foto vazia");
        }
        String extension = detectExtension(bytes);
        if (extension == null) {
            throw new BadRequestException("Formato de foto não suportado (use JPEG, PNG ou WebP)");
        }
        String filename = UUID.randomUUID() + "." + extension;
        Path target = resolve(filename);
        try {
            Path tmp = Files.createTempFile(root, "upload-", ".tmp");
            Files.write(tmp, bytes);
            Files.move(tmp, target, StandardCopyOption.ATOMIC_MOVE);
        } catch (IOException e) {
            throw new UncheckedIOException("Erro ao salvar a foto", e);
        }
        return filename;
    }

    public byte[] load(String filename) {
        try {
            return Files.readAllBytes(resolve(filename));
        } catch (java.nio.file.NoSuchFileException e) {
            throw new NotFoundException("Arquivo da foto não encontrado");
        } catch (IOException e) {
            throw new UncheckedIOException("Erro ao ler a foto", e);
        }
    }

    /**
     * Apaga o arquivo só depois que a transação do banco confirmar (se houver uma),
     * para a foto não sumir caso a exclusão no banco seja desfeita.
     */
    public void deleteAfterCommit(String filename) {
        if (filename == null) {
            return;
        }
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    delete(filename);
                }
            });
        } else {
            delete(filename);
        }
    }

    /**
     * Salvo um arquivo dentro de uma transação: se ela for desfeita, apaga o arquivo
     * para não deixar foto órfã.
     */
    public void deleteOnRollback(String filename) {
        if (filename != null && TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCompletion(int status) {
                    if (status != STATUS_COMMITTED) {
                        delete(filename);
                    }
                }
            });
        }
    }

    public void delete(String filename) {
        if (filename == null) {
            return;
        }
        try {
            Files.deleteIfExists(resolve(filename));
        } catch (IOException e) {
            // A evidência já foi apagada; um arquivo órfão não deve quebrar a operação.
            log.warn("Não foi possível apagar a foto {}: {}", filename, e.getMessage());
        }
    }

    public static MediaType mediaTypeOf(String filename) {
        if (filename.endsWith(".png")) return MediaType.IMAGE_PNG;
        if (filename.endsWith(".webp")) return MediaType.parseMediaType("image/webp");
        return MediaType.IMAGE_JPEG;
    }

    /** Resolve o nome dentro da pasta de fotos, recusando qualquer caminho que saia dela. */
    private Path resolve(String filename) {
        Path path = root.resolve(filename).normalize();
        if (!path.getParent().equals(root)) {
            throw new BadRequestException("Nome de arquivo inválido");
        }
        return path;
    }

    /** Identifica o formato pelos primeiros bytes (não confia na extensão/Content-Type do cliente). */
    private static String detectExtension(byte[] b) {
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) {
            return "jpg";
        }
        if (b.length >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') {
            return "png";
        }
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') {
            return "webp";
        }
        return null;
    }
}

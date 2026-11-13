import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Armazenamento local (SQLite) para o modo offline.
///
/// Guarda:
///  - **cache**: últimas respostas da API (avaliações, evidências, itens) para
///    consulta sem conexão;
///  - **fotos**: imagens já baixadas;
///  - **pendências**: avaliações e evidências criadas sem conexão, que o
///    [ApiService.syncPending] envia quando a conexão volta.
///
/// Só funciona em Android/iOS/desktop: no navegador (Flutter Web) o sqflite não
/// está disponível, então [supported] é falso e os métodos não fazem nada.
class OfflineStore {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  static const _dbName = 'comodeu_offline.db';
  static const _dbVersion = 1;

  Database? _db;

  /// Em testes sem o plugin do sqflite, permite desligar o armazenamento local.
  @visibleForTesting
  static bool? debugSupportedOverride;

  bool get supported => debugSupportedOverride ?? !kIsWeb;

  Future<Database> get _database async {
    return _db ??= await openDatabase(
      p.join(await getDatabasesPath(), _dbName),
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)');
        await db.execute(
            'CREATE TABLE cache (key TEXT PRIMARY KEY, json TEXT NOT NULL, updated_at TEXT NOT NULL)');
        await db.execute('CREATE TABLE photo_cache (evidence_id INTEGER PRIMARY KEY, bytes BLOB NOT NULL)');
        await db.execute('''
          CREATE TABLE pending_evaluations (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            visitor_name TEXT NOT NULL,
            cultural_space_name TEXT NOT NULL,
            space_type TEXT NOT NULL,
            created_at TEXT NOT NULL,
            server_id INTEGER,
            sync_error TEXT
          )''');
        await db.execute('''
          CREATE TABLE pending_evidences (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            evaluation_id INTEGER,
            local_evaluation_id INTEGER,
            photo BLOB NOT NULL,
            mark_x INTEGER,
            mark_y INTEGER,
            quick_note TEXT NOT NULL,
            created_at TEXT NOT NULL,
            sync_error TEXT
          )''');
      },
    );
  }

  // ---------------------------------------------------------------- conta

  /// Garante que os dados locais pertencem a [email]; se forem de outra conta, apaga tudo.
  Future<void> useAccount(String email) async {
    if (!supported) return;
    final db = await _database;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: ['owner']);
    final owner = rows.isEmpty ? null : rows.first['value'] as String?;
    if (owner != email.toLowerCase()) {
      await _wipe(db);
      await db.insert('meta', {'key': 'owner', 'value': email.toLowerCase()},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Apaga todos os dados locais (cache e pendências). Usado no logout.
  Future<void> clearAll() async {
    if (!supported) return;
    await _wipe(await _database);
  }

  Future<void> _wipe(Database db) async {
    for (final table in ['meta', 'cache', 'photo_cache', 'pending_evaluations', 'pending_evidences']) {
      await db.delete(table);
    }
  }

  // ---------------------------------------------------------------- cache de respostas

  Future<void> putCache(String key, Object? json) async {
    if (!supported) return;
    final db = await _database;
    await db.insert(
      'cache',
      {'key': key, 'json': jsonEncode(json), 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Resposta guardada, ou null se não houver.
  Future<dynamic> getCache(String key) async {
    if (!supported) return null;
    final db = await _database;
    final rows = await db.query('cache', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : jsonDecode(rows.first['json'] as String);
  }

  Future<void> putPhoto(int evidenceId, Uint8List bytes) async {
    if (!supported) return;
    final db = await _database;
    await db.insert('photo_cache', {'evidence_id': evidenceId, 'bytes': bytes},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Uint8List?> getPhoto(int evidenceId) async {
    if (!supported) return null;
    final db = await _database;
    final rows = await db.query('photo_cache', where: 'evidence_id = ?', whereArgs: [evidenceId]);
    return rows.isEmpty ? null : rows.first['bytes'] as Uint8List;
  }

  Future<void> deletePhoto(int evidenceId) async {
    if (!supported) return;
    final db = await _database;
    await db.delete('photo_cache', where: 'evidence_id = ?', whereArgs: [evidenceId]);
  }

  // ---------------------------------------------------------------- avaliações pendentes

  /// Guarda uma avaliação criada sem conexão e devolve o id local.
  Future<int> addPendingEvaluation({
    required String visitorName,
    required String culturalSpaceName,
    required String spaceType,
  }) async {
    final db = await _database;
    return db.insert('pending_evaluations', {
      'visitor_name': visitorName,
      'cultural_space_name': culturalSpaceName,
      'space_type': spaceType,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Avaliações ainda não enviadas.
  Future<List<Map<String, Object?>>> unsyncedEvaluations() async {
    if (!supported) return [];
    final db = await _database;
    return db.query('pending_evaluations', where: 'server_id IS NULL', orderBy: 'local_id DESC');
  }

  /// Id no servidor de uma avaliação local já enviada (ou null se ainda não foi).
  Future<int?> serverIdOf(int localEvaluationId) async {
    if (!supported) return null;
    final db = await _database;
    final rows = await db.query('pending_evaluations',
        columns: ['server_id'], where: 'local_id = ?', whereArgs: [localEvaluationId]);
    return rows.isEmpty ? null : rows.first['server_id'] as int?;
  }

  /// Marca a avaliação local como enviada e move as evidências dela para o id do servidor.
  /// A linha é mantida para que telas abertas com o id local continuem funcionando.
  Future<void> markEvaluationSynced(int localEvaluationId, int serverId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.update('pending_evaluations', {'server_id': serverId, 'sync_error': null},
          where: 'local_id = ?', whereArgs: [localEvaluationId]);
      await txn.update('pending_evidences', {'evaluation_id': serverId, 'local_evaluation_id': null},
          where: 'local_evaluation_id = ?', whereArgs: [localEvaluationId]);
    });
  }

  Future<void> setEvaluationError(int localEvaluationId, String error) async {
    final db = await _database;
    await db.update('pending_evaluations', {'sync_error': error},
        where: 'local_id = ?', whereArgs: [localEvaluationId]);
  }

  Future<void> deletePendingEvaluation(int localEvaluationId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('pending_evidences', where: 'local_evaluation_id = ?', whereArgs: [localEvaluationId]);
      await txn.delete('pending_evaluations', where: 'local_id = ?', whereArgs: [localEvaluationId]);
    });
  }

  // ---------------------------------------------------------------- evidências pendentes

  /// Guarda uma evidência registrada sem conexão. Informe [evaluationId] (avaliação
  /// já no servidor) ou [localEvaluationId] (avaliação também pendente).
  Future<int> addPendingEvidence({
    int? evaluationId,
    int? localEvaluationId,
    required Uint8List photo,
    int? markX,
    int? markY,
    required String quickNote,
  }) async {
    assert((evaluationId == null) != (localEvaluationId == null));
    final db = await _database;
    return db.insert('pending_evidences', {
      'evaluation_id': evaluationId,
      'local_evaluation_id': localEvaluationId,
      'photo': photo,
      'mark_x': markX,
      'mark_y': markY,
      'quick_note': quickNote,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static const _evidenceColumns = [
    'local_id', 'evaluation_id', 'local_evaluation_id', 'mark_x', 'mark_y',
    'quick_note', 'created_at', 'sync_error',
  ];

  /// Evidências pendentes de uma avaliação (sem a foto, que é carregada à parte).
  Future<List<Map<String, Object?>>> pendingEvidencesOf({int? evaluationId, int? localEvaluationId}) async {
    if (!supported) return [];
    final db = await _database;
    return evaluationId != null
        ? db.query('pending_evidences', columns: _evidenceColumns,
            where: 'evaluation_id = ?', whereArgs: [evaluationId], orderBy: 'local_id')
        : db.query('pending_evidences', columns: _evidenceColumns,
            where: 'local_evaluation_id = ?', whereArgs: [localEvaluationId], orderBy: 'local_id');
  }

  /// Evidências prontas para envio (a avaliação já existe no servidor).
  Future<List<Map<String, Object?>>> sendableEvidences() async {
    if (!supported) return [];
    final db = await _database;
    return db.query('pending_evidences', where: 'evaluation_id IS NOT NULL', orderBy: 'local_id');
  }

  Future<Uint8List?> pendingEvidencePhoto(int localId) async {
    if (!supported) return null;
    final db = await _database;
    final rows = await db.query('pending_evidences',
        columns: ['photo'], where: 'local_id = ?', whereArgs: [localId]);
    return rows.isEmpty ? null : rows.first['photo'] as Uint8List;
  }

  Future<void> setEvidenceError(int localId, String error) async {
    final db = await _database;
    await db.update('pending_evidences', {'sync_error': error}, where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> deletePendingEvidence(int localId) async {
    final db = await _database;
    await db.delete('pending_evidences', where: 'local_id = ?', whereArgs: [localId]);
  }

  /// Total de itens aguardando envio (avaliações + evidências).
  Future<int> pendingCount() async {
    if (!supported) return 0;
    final db = await _database;
    final evaluations = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM pending_evaluations WHERE server_id IS NULL')) ??
        0;
    final evidences = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pending_evidences')) ?? 0;
    return evaluations + evidences;
  }
}

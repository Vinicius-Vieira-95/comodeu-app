import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/classification.dart';
import '../models/como_item.dart';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import 'offline_store.dart';

/// Erro de autenticação (login inválido, e-mail já cadastrado, dados inválidos).
/// A [message] já vem pronta para mostrar ao usuário.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// A API respondeu com erro (404, 400...). A [message] já vem pronta para o usuário.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Não foi possível falar com o servidor (sem internet, servidor fora do ar, timeout).
class OfflineException implements Exception {
  final String message;
  OfflineException([this.message = 'Sem conexão com o servidor']);

  @override
  String toString() => message;
}

/// Cliente HTTP que envia o token JWT em toda requisição e, se a API
/// responder 401 (token expirado/inválido), encerra a sessão.
class _AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = ApiService.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = await _inner.send(request);
    if (response.statusCode == 401) {
      // Sessão expirada: mantém as pendências offline (são enviadas após novo login da mesma conta).
      await ApiService.logout(keepOfflineData: true);
      ApiService.onUnauthorized?.call();
    }
    return response;
  }
}

class ApiService {
  /// URL da API. Pode ser sobrescrita com
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080/api`.
  /// Padrão: no emulador Android, 10.0.2.2 aponta para o localhost do PC.
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';

  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  static final http.Client _client = _AuthClient();
  static final OfflineStore _store = OfflineStore.instance;

  /// Token JWT da sessão atual (null = não logado).
  static String? token;

  /// Nome do usuário logado (para exibir na tela).
  static String? userName;

  /// Chamado quando a API recusa o token (401). O app usa para voltar ao login.
  static void Function()? onUnauthorized;

  /// true quando a última tentativa de falar com o servidor falhou por falta de conexão.
  static final ValueNotifier<bool> offline = ValueNotifier(false);

  /// Quantidade de avaliações/evidências guardadas no aparelho aguardando envio.
  static final ValueNotifier<int> pendingCount = ValueNotifier(0);

  /// O modo offline (guardar sem conexão) está disponível nesta plataforma?
  static bool get offlineSupported => _store.supported;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static bool get isLoggedIn => token != null;

  /// Fotos já baixadas nesta execução do app.
  static final Map<int, Uint8List> _photoMemoryCache = {};

  // ======================================================================
  // INFRAESTRUTURA
  // ======================================================================

  /// Executa a chamada HTTP convertendo falhas de rede em [OfflineException].
  static Future<http.Response> _send(Future<http.Response> Function() call,
      {Duration timeout = _timeout}) async {
    try {
      final response = await call().timeout(timeout);
      offline.value = false;
      return response;
    } on TimeoutException {
      offline.value = true;
      throw OfflineException('O servidor demorou para responder');
    } on http.ClientException {
      offline.value = true;
      throw OfflineException();
    }
  }

  static dynamic _decode(http.Response response) {
    // utf8.decode: a API não envia charset, e response.body decodificaria como Latin-1 (acentos quebrados).
    return response.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Lança [ApiException] com a mensagem enviada pela API ({"error": "..."}).
  static Never _fail(http.Response response, String fallback) {
    if (response.statusCode == 401) {
      throw ApiException(401, 'Sessão expirada. Entre novamente.');
    }
    String message = fallback;
    try {
      final data = _decode(response);
      if (data is Map && data['fields'] is Map && (data['fields'] as Map).isNotEmpty) {
        message = (data['fields'] as Map).values.join('\n');
      } else if (data is Map && data['error'] is String) {
        message = data['error'] as String;
      }
    } catch (_) {
      // corpo não é JSON: usa a mensagem padrão
    }
    throw ApiException(response.statusCode, message);
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<void> _refreshPendingCount() async {
    pendingCount.value = await _store.pendingCount();
  }

  // ======================================================================
  // AUTENTICAÇÃO
  // ======================================================================

  /// Carrega o token salvo no aparelho. Chamar uma vez ao abrir o app.
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    userName = prefs.getString(_userNameKey);
    final email = prefs.getString(_userEmailKey);
    if (isLoggedIn && email != null) {
      await _store.useAccount(email);
      await _refreshPendingCount();
    }
    return isLoggedIn;
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    await _authenticate('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _authenticate('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  /// Encerra a sessão. Por padrão apaga também os dados guardados no aparelho
  /// (inclusive pendências não enviadas); com [keepOfflineData] eles são mantidos
  /// e continuam valendo se a mesma conta entrar de novo.
  static Future<void> logout({bool keepOfflineData = false}) async {
    token = null;
    userName = null;
    _photoMemoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    if (!keepOfflineData) {
      await prefs.remove(_userEmailKey);
      await _store.clearAll();
      pendingCount.value = 0;
    }
  }

  static Future<void> _authenticate(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await http
          .post(_uri(path), headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
    } catch (e) {
      throw AuthException('Não foi possível conectar com o servidor');
    }

    dynamic data;
    try {
      data = _decode(response);
    } catch (_) {
      data = null;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      token = data['token'] as String;
      userName = data['user']?['name'] as String?;
      final email = (data['user']?['email'] as String?) ?? body['email']!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token!);
      await prefs.setString(_userEmailKey, email);
      if (userName != null) {
        await prefs.setString(_userNameKey, userName!);
      }
      await _store.useAccount(email);
      await _refreshPendingCount();
      return;
    }

    // 400: {"error": "...", "fields": {"campo": "mensagem"}}  |  401/409: {"error": "..."}
    if (data is Map && data['fields'] is Map && (data['fields'] as Map).isNotEmpty) {
      throw AuthException((data['fields'] as Map).values.join('\n'));
    }
    if (data is Map && data['error'] is String) {
      throw AuthException(data['error'] as String);
    }
    throw AuthException('Erro inesperado (${response.statusCode})');
  }

  // ======================================================================
  // AVALIAÇÕES
  // ======================================================================

  /// Cria a avaliação no servidor. Sem conexão, guarda no aparelho e devolve
  /// uma avaliação pendente (id negativo), enviada depois por [syncPending].
  static Future<Evaluation> createEvaluation({
    required String visitorName,
    required String culturalSpaceName,
    required String spaceType,
  }) async {
    try {
      return await _createEvaluationOnServer(visitorName, culturalSpaceName, spaceType);
    } on OfflineException {
      if (!offlineSupported) rethrow;
      final localId = await _store.addPendingEvaluation(
        visitorName: visitorName,
        culturalSpaceName: culturalSpaceName,
        spaceType: spaceType,
      );
      await _refreshPendingCount();
      final now = DateTime.now();
      return Evaluation(
        id: -localId,
        visitorName: visitorName,
        culturalSpaceName: culturalSpaceName,
        spaceType: spaceType,
        visitDate: now,
        createdAt: now,
        status: 'IN_PROGRESS',
      );
    }
  }

  static Future<Evaluation> _createEvaluationOnServer(
      String visitorName, String culturalSpaceName, String spaceType) async {
    final response = await _send(() => _client.post(
          _uri('/evaluations'),
          headers: headers,
          body: jsonEncode({
            'visitorName': visitorName,
            'culturalSpaceName': culturalSpaceName,
            'spaceType': spaceType,
          }),
        ));
    if (response.statusCode != 201) _fail(response, 'Erro ao criar avaliação');
    return Evaluation.fromJson(_decode(response));
  }

  /// Avaliações do usuário: as pendentes (só no aparelho) primeiro, depois as do servidor.
  /// Sem conexão, usa a última lista salva no aparelho.
  static Future<List<Evaluation>> getAllEvaluations() async {
    List<Evaluation> fromServer;
    try {
      final response = await _send(() => _client.get(_uri('/evaluations'), headers: headers));
      if (response.statusCode != 200) _fail(response, 'Erro ao buscar avaliações');
      final data = _decode(response) as List<dynamic>;
      await _store.putCache('evaluations', data);
      fromServer = data.map((json) => Evaluation.fromJson(json)).toList();
    } on OfflineException {
      final cached = await _store.getCache('evaluations');
      if (cached == null) rethrow;
      fromServer = (cached as List<dynamic>).map((json) => Evaluation.fromJson(json)).toList();
    }

    final pending = (await _store.unsyncedEvaluations()).map((row) {
      final createdAt = DateTime.parse(row['created_at'] as String);
      return Evaluation(
        id: -(row['local_id'] as int),
        visitorName: row['visitor_name'] as String,
        culturalSpaceName: row['cultural_space_name'] as String,
        spaceType: row['space_type'] as String,
        visitDate: createdAt,
        createdAt: createdAt,
        status: 'IN_PROGRESS',
      );
    });
    return [...pending, ...fromServer];
  }

  static Future<Evaluation> getEvaluation(int id) async {
    final response = await _send(() => _client.get(_uri('/evaluations/$id'), headers: headers));
    if (response.statusCode != 200) _fail(response, 'Avaliação não encontrada');
    return Evaluation.fromJson(_decode(response));
  }

  /// Marca a avaliação como concluída (não aceita mais evidências novas).
  static Future<Evaluation> completeEvaluation(Evaluation evaluation) async {
    final id = await _serverEvaluationId(evaluation.id!);
    if (id == null) {
      throw ApiException(409, 'Esta avaliação ainda não foi enviada. Sincronize antes de concluir.');
    }
    final response = await _send(() => _client.put(_uri('/evaluations/$id/complete'), headers: headers));
    if (response.statusCode != 200) _fail(response, 'Erro ao concluir avaliação');
    return Evaluation.fromJson(_decode(response));
  }

  /// Id da avaliação no servidor. Para uma avaliação pendente (id negativo), devolve
  /// o id recebido na sincronização, ou null se ela ainda não foi enviada.
  static Future<int?> _serverEvaluationId(int id) async {
    if (id >= 0) return id;
    return _store.serverIdOf(-id);
  }

  // ======================================================================
  // EVIDÊNCIAS
  // ======================================================================

  /// Registra a evidência (upload da foto). Sem conexão — ou se a avaliação ainda
  /// estiver pendente — guarda no aparelho e devolve uma evidência pendente (id negativo).
  static Future<Evidence> registerEvidence({
    required Evaluation evaluation,
    required Uint8List photo,
    required int? markX,
    required int? markY,
    required String quickNote,
  }) async {
    final serverEvaluationId = await _serverEvaluationId(evaluation.id!);

    if (serverEvaluationId != null) {
      try {
        return await _uploadEvidence(serverEvaluationId, photo, markX, markY, quickNote);
      } on OfflineException {
        if (!offlineSupported) rethrow;
      }
    }

    final localId = await _store.addPendingEvidence(
      evaluationId: serverEvaluationId,
      localEvaluationId: serverEvaluationId == null ? -evaluation.id! : null,
      photo: photo,
      markX: markX,
      markY: markY,
      quickNote: quickNote,
    );
    await _refreshPendingCount();
    return Evidence(
      id: -localId,
      evaluationId: evaluation.id!,
      markX: markX,
      markY: markY,
      quickNote: quickNote,
      captureTime: DateTime.now(),
      status: 'REGISTERED',
    );
  }

  static Future<Evidence> _uploadEvidence(
      int evaluationId, Uint8List photo, int? markX, int? markY, String quickNote) async {
    final request = http.MultipartRequest('POST', _uri('/evidences'))
      ..headers['Accept'] = 'application/json'
      ..fields['evaluationId'] = '$evaluationId'
      ..fields['quickNote'] = quickNote
      ..files.add(http.MultipartFile.fromBytes('photo', photo, filename: 'evidencia.jpg'));
    if (markX != null) request.fields['markX'] = '$markX';
    if (markY != null) request.fields['markY'] = '$markY';

    final response = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
      timeout: _uploadTimeout,
    );
    if (response.statusCode != 201) _fail(response, 'Erro ao registrar evidência');
    final evidence = Evidence.fromJson(_decode(response));
    _photoMemoryCache[evidence.id!] = photo;
    await _store.putPhoto(evidence.id!, photo);
    return evidence;
  }

  /// Evidências da avaliação: as do servidor e, depois, as pendentes no aparelho.
  /// Sem conexão, usa a última lista salva no aparelho.
  static Future<List<Evidence>> getEvidencesByEvaluation(Evaluation evaluation) async {
    final serverId = await _serverEvaluationId(evaluation.id!);

    var fromServer = <Evidence>[];
    if (serverId != null) {
      final cacheKey = 'evidences:$serverId';
      try {
        final response =
            await _send(() => _client.get(_uri('/evidences/evaluation/$serverId'), headers: headers));
        if (response.statusCode != 200) _fail(response, 'Erro ao buscar evidências');
        final data = _decode(response) as List<dynamic>;
        await _store.putCache(cacheKey, data);
        fromServer = data.map((json) => Evidence.fromJson(json)).toList();
      } on OfflineException {
        final cached = await _store.getCache(cacheKey);
        if (cached == null && !offlineSupported) rethrow;
        fromServer = ((cached ?? []) as List<dynamic>).map((json) => Evidence.fromJson(json)).toList();
      }
    }

    final pendingRows = serverId != null
        ? await _store.pendingEvidencesOf(evaluationId: serverId)
        : await _store.pendingEvidencesOf(localEvaluationId: -evaluation.id!);
    final pending = pendingRows.map((row) => Evidence(
          id: -(row['local_id'] as int),
          evaluationId: evaluation.id!,
          markX: row['mark_x'] as int?,
          markY: row['mark_y'] as int?,
          quickNote: row['quick_note'] as String,
          captureTime: DateTime.parse(row['created_at'] as String),
          status: 'REGISTERED',
          syncError: row['sync_error'] as String?,
        ));
    return [...fromServer, ...pending];
  }

  /// Bytes da foto: memória → aparelho → servidor (e guarda no aparelho para uso offline).
  static Future<Uint8List?> getEvidencePhoto(Evidence evidence) async {
    final id = evidence.id!;
    if (evidence.isPending) return _store.pendingEvidencePhoto(-id);
    if (!evidence.hasPhoto) return null;

    final inMemory = _photoMemoryCache[id];
    if (inMemory != null) return inMemory;

    final stored = await _store.getPhoto(id);
    if (stored != null) return _photoMemoryCache[id] = stored;

    final response = await _send(
      () => _client.get(_uri('/evidences/$id/photo')),
      timeout: _uploadTimeout,
    );
    if (response.statusCode != 200) _fail(response, 'Erro ao carregar a foto');
    final bytes = response.bodyBytes;
    _photoMemoryCache[id] = bytes;
    await _store.putPhoto(id, bytes);
    return bytes;
  }

  /// Apaga a evidência (e as classificações dela). Pendentes são apagadas só do aparelho.
  static Future<void> deleteEvidence(Evidence evidence) async {
    final id = evidence.id!;
    if (evidence.isPending) {
      await _store.deletePendingEvidence(-id);
      await _refreshPendingCount();
      return;
    }
    final response = await _send(() => _client.delete(_uri('/evidences/$id'), headers: headers));
    if (response.statusCode != 204 && response.statusCode != 404) {
      _fail(response, 'Erro ao apagar evidência');
    }
    _photoMemoryCache.remove(id);
    await _store.deletePhoto(id);
  }

  // ======================================================================
  // ITENS COMO D'EU
  // ======================================================================

  static Future<List<ComoItem>> getAllComoItems() async {
    List<dynamic> data;
    try {
      final response = await _send(() => _client.get(_uri('/como-items'), headers: headers));
      if (response.statusCode != 200) _fail(response, 'Erro ao buscar itens COMO D\'EU');
      data = _decode(response) as List<dynamic>;
      await _store.putCache('como_items', data);
    } on OfflineException {
      final cached = await _store.getCache('como_items');
      if (cached == null) rethrow;
      data = cached as List<dynamic>;
    }
    return data.map((json) => ComoItem.fromJson(json)).toList()
      ..sort((a, b) => a.itemNumber.compareTo(b.itemNumber));
  }

  /// Sugestões por palavras-chave da nota. Em caso de erro, devolve lista vazia.
  static Future<List<ComoItem>> suggestComoItems(String quickNote) async {
    try {
      final response = await _send(() => _client.post(
            _uri('/como-items/suggest'),
            headers: headers,
            body: jsonEncode({'quickNote': quickNote}),
          ));
      if (response.statusCode != 200) return [];
      final data = _decode(response) as List<dynamic>;
      return data.map((json) => ComoItem.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  // ======================================================================
  // CLASSIFICAÇÕES (exigem conexão)
  // ======================================================================

  static Future<List<Classification>> getClassifications(int evidenceId) async {
    final response =
        await _send(() => _client.get(_uri('/evidences/$evidenceId/classifications'), headers: headers));
    if (response.statusCode != 200) _fail(response, 'Erro ao buscar classificações');
    final data = _decode(response) as List<dynamic>;
    return data.map((json) => Classification.fromJson(json)).toList();
  }

  /// Salva a classificação completa da evidência, substituindo a anterior (sem duplicar).
  static Future<List<Classification>> saveClassifications({
    required int evidenceId,
    required List<int> comoItemIds,
    required String personalAnalysis,
  }) async {
    final response = await _send(() => _client.put(
          _uri('/evidences/$evidenceId/classifications'),
          headers: headers,
          body: jsonEncode({'comoItemIds': comoItemIds, 'personalAnalysis': personalAnalysis}),
        ));
    if (response.statusCode != 200) _fail(response, 'Erro ao salvar classificação');
    final data = _decode(response) as List<dynamic>;
    return data.map((json) => Classification.fromJson(json)).toList();
  }

  // ======================================================================
  // SINCRONIZAÇÃO
  // ======================================================================

  static Future<int>? _syncInProgress;

  /// Envia ao servidor o que foi guardado sem conexão. Devolve quantos itens foram enviados.
  /// Para na primeira falha de conexão; erros de validação ficam registrados no item.
  static Future<int> syncPending() {
    if (!isLoggedIn || !offlineSupported) return Future.value(0);
    return _syncInProgress ??= _doSync().whenComplete(() => _syncInProgress = null);
  }

  static Future<int> _doSync() async {
    var sent = 0;
    try {
      for (final row in await _store.unsyncedEvaluations()) {
        final localId = row['local_id'] as int;
        try {
          final created = await _createEvaluationOnServer(
            row['visitor_name'] as String,
            row['cultural_space_name'] as String,
            row['space_type'] as String,
          );
          await _store.markEvaluationSynced(localId, created.id!);
          sent++;
        } on ApiException catch (e) {
          if (e.statusCode == 401) rethrow;
          await _store.setEvaluationError(localId, e.message);
        }
      }

      for (final row in await _store.sendableEvidences()) {
        final localId = row['local_id'] as int;
        try {
          await _uploadEvidence(
            row['evaluation_id'] as int,
            row['photo'] as Uint8List,
            row['mark_x'] as int?,
            row['mark_y'] as int?,
            row['quick_note'] as String,
          );
          await _store.deletePendingEvidence(localId);
          sent++;
        } on ApiException catch (e) {
          if (e.statusCode == 401) rethrow;
          await _store.setEvidenceError(localId, e.message);
        }
      }
    } on OfflineException {
      // sem conexão: tenta de novo na próxima vez
    } on ApiException {
      // sessão expirada: o app volta para o login
    } finally {
      await _refreshPendingCount();
    }
    return sent;
  }
}

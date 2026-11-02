import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import '../models/como_item.dart';

/// Erro de autenticação (login inválido, e-mail já cadastrado, dados inválidos).
/// A [message] já vem pronta para mostrar ao usuário.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

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
      await ApiService.logout();
      ApiService.onUnauthorized?.call();
    }
    return response;
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'auth_user_name';

  static final http.Client _client = _AuthClient();

  /// Token JWT da sessão atual (null = não logado).
  static String? token;

  /// Nome do usuário logado (para exibir na tela).
  static String? userName;

  /// Chamado quando a API recusa o token (401). O app usa para voltar ao login.
  static void Function()? onUnauthorized;

  // Headers padrão (o token é adicionado pelo _AuthClient)
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static bool get isLoggedIn => token != null;

  // AUTH ENDPOINTS

  /// Carrega o token salvo no aparelho. Chamar uma vez ao abrir o app.
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    userName = prefs.getString(_userNameKey);
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

  static Future<void> logout() async {
    token = null;
    userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
  }

  static Future<void> _authenticate(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw AuthException('Não foi possível conectar com o servidor');
    }

    // utf8.decode: a API não envia charset, e response.body decodificaria como Latin-1 (acentos quebrados).
    dynamic data;
    try {
      data = response.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      token = data['token'] as String;
      userName = data['user']?['name'] as String?;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token!);
      if (userName != null) {
        await prefs.setString(_userNameKey, userName!);
      }
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

  // EVALUATION ENDPOINTS

  static Future<Evaluation> createEvaluation({
    required String visitorName,
    required String culturalSpaceName,
    required String spaceType,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/evaluations'),
        headers: headers,
        body: jsonEncode({
          'visitorName': visitorName,
          'culturalSpaceName': culturalSpaceName,
          'spaceType': spaceType,
        }),
      );

      if (response.statusCode == 201) {
        return Evaluation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erro ao criar avaliação: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  static Future<Evaluation> getEvaluation(int id) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/evaluations/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Evaluation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Avaliação não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar avaliação: $e');
    }
  }

  static Future<List<Evaluation>> getAllEvaluations() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/evaluations'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Evaluation.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar avaliações');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // EVIDENCE ENDPOINTS

  static Future<Evidence> registerEvidence({
    required int evaluationId,
    required String photoBase64,
    required int? markX,
    required int? markY,
    required String quickNote,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/evidences'),
        headers: headers,
        body: jsonEncode({
          'evaluationId': evaluationId,
          'photoBase64': photoBase64,
          'markX': markX,
          'markY': markY,
          'quickNote': quickNote,
        }),
      );

      if (response.statusCode == 201) {
        return Evidence.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erro ao registrar evidência: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao enviar evidência: $e');
    }
  }

  static Future<List<Evidence>> getEvidencesByEvaluation(int evaluationId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/evidences/evaluation/$evaluationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Evidence.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar evidências');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // COMO ITEMS ENDPOINTS

  static Future<List<ComoItem>> getAllComoItems() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/como-items'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ComoItem.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar itens COMO D\'EU');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  static Future<List<ComoItem>> suggestComoItems(String quickNote) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/como-items/suggest'),
        headers: headers,
        body: jsonEncode({
          'quickNote': quickNote,
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ComoItem.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Erro ao obter sugestões: $e');
    }
  }

  // CLASSIFICATIONS ENDPOINTS

  static Future<bool> createClassification({
    required int evidenceId,
    required int comoItemId,
    required String personalAnalysis,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/classifications'),
        headers: headers,
        body: jsonEncode({
          'evidenceId': evidenceId,
          'comoItemId': comoItemId,
          'personalAnalysis': personalAnalysis,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao classificar evidência: $e');
    }
  }
}

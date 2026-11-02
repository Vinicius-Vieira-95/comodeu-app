import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import '../models/como_item.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  // Headers padrão
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // EVALUATION ENDPOINTS

  static Future<Evaluation> createEvaluation({
    required String visitorName,
    required String culturalSpaceName,
    required String spaceType,
  }) async {
    try {
      final response = await http.post(
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
      final response = await http.get(
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
      final response = await http.get(
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
      final response = await http.post(
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
      final response = await http.get(
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
      final response = await http.get(
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
      final response = await http.post(
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
      final response = await http.post(
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

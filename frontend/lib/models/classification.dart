/// Ligação de uma evidência a um item COMO D'EU, com a análise do avaliador.
class Classification {
  final int id;
  final int evidenceId;
  final int comoItemId;
  final String personalAnalysis;

  Classification({
    required this.id,
    required this.evidenceId,
    required this.comoItemId,
    required this.personalAnalysis,
  });

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      id: json['id'],
      evidenceId: json['evidenceId'],
      comoItemId: json['comoItemId'],
      personalAnalysis: json['personalAnalysis'] ?? '',
    );
  }
}

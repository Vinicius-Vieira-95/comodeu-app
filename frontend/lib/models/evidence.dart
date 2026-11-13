/// Evidência registrada durante a visita.
///
/// Evidências ainda não enviadas ao servidor (modo offline) têm [id] negativo:
/// -id é o identificador local no aparelho.
class Evidence {
  final int? id;
  final int evaluationId;
  final bool hasPhoto;
  final int? markX;
  final int? markY;
  final String quickNote;
  final DateTime captureTime;
  final String status; // REGISTERED, CLASSIFIED

  /// Mensagem do último erro ao tentar enviar (só para pendentes).
  final String? syncError;

  Evidence({
    this.id,
    required this.evaluationId,
    this.hasPhoto = true,
    this.markX,
    this.markY,
    required this.quickNote,
    required this.captureTime,
    required this.status,
    this.syncError,
  });

  /// Ainda está só no aparelho, aguardando envio.
  bool get isPending => id != null && id! < 0;

  bool get isClassified => status == 'CLASSIFIED';

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      id: json['id'],
      evaluationId: json['evaluationId'],
      hasPhoto: json['hasPhoto'] ?? false,
      markX: json['markX'],
      markY: json['markY'],
      quickNote: json['quickNote'],
      captureTime: DateTime.parse(json['captureTime']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'evaluationId': evaluationId,
      'hasPhoto': hasPhoto,
      'markX': markX,
      'markY': markY,
      'quickNote': quickNote,
      'captureTime': captureTime.toIso8601String(),
      'status': status,
    };
  }
}

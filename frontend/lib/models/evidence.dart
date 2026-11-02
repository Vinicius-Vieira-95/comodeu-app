class Evidence {
  final int? id;
  final int evaluationId;
  final String? photoDataBase64;
  final int? markX;
  final int? markY;
  final String quickNote;
  final DateTime captureTime;
  final String status; // REGISTERED, CLASSIFIED, COMPLETED

  Evidence({
    this.id,
    required this.evaluationId,
    this.photoDataBase64,
    this.markX,
    this.markY,
    required this.quickNote,
    required this.captureTime,
    required this.status,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      id: json['id'],
      evaluationId: json['evaluationId'],
      photoDataBase64: json['photoDataBase64'],
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
      'photoDataBase64': photoDataBase64,
      'markX': markX,
      'markY': markY,
      'quickNote': quickNote,
      'captureTime': captureTime.toIso8601String(),
      'status': status,
    };
  }

  Evidence copyWith({
    int? id,
    int? evaluationId,
    String? photoDataBase64,
    int? markX,
    int? markY,
    String? quickNote,
    DateTime? captureTime,
    String? status,
  }) {
    return Evidence(
      id: id ?? this.id,
      evaluationId: evaluationId ?? this.evaluationId,
      photoDataBase64: photoDataBase64 ?? this.photoDataBase64,
      markX: markX ?? this.markX,
      markY: markY ?? this.markY,
      quickNote: quickNote ?? this.quickNote,
      captureTime: captureTime ?? this.captureTime,
      status: status ?? this.status,
    );
  }
}

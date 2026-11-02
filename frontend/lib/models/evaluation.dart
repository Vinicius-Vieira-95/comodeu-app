class Evaluation {
  final int? id;
  final String visitorName;
  final String culturalSpaceName;
  final String spaceType;
  final DateTime visitDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String status; // IN_PROGRESS, COMPLETED

  Evaluation({
    this.id,
    required this.visitorName,
    required this.culturalSpaceName,
    required this.spaceType,
    required this.visitDate,
    required this.createdAt,
    this.completedAt,
    required this.status,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      id: json['id'],
      visitorName: json['visitorName'],
      culturalSpaceName: json['culturalSpaceName'],
      spaceType: json['spaceType'],
      visitDate: DateTime.parse(json['visitDate']),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitorName': visitorName,
      'culturalSpaceName': culturalSpaceName,
      'spaceType': spaceType,
      'visitDate': visitDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
    };
  }

  Evaluation copyWith({
    int? id,
    String? visitorName,
    String? culturalSpaceName,
    String? spaceType,
    DateTime? visitDate,
    DateTime? createdAt,
    DateTime? completedAt,
    String? status,
  }) {
    return Evaluation(
      id: id ?? this.id,
      visitorName: visitorName ?? this.visitorName,
      culturalSpaceName: culturalSpaceName ?? this.culturalSpaceName,
      spaceType: spaceType ?? this.spaceType,
      visitDate: visitDate ?? this.visitDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
    );
  }
}

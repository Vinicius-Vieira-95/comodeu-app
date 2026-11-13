import 'package:flutter/material.dart';

import '../models/evaluation.dart';

/// Chip de status da avaliação: Não enviada / Em Progresso / Concluída.
class EvaluationStatusChip extends StatelessWidget {
  final Evaluation evaluation;

  const EvaluationStatusChip({super.key, required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final (String label, Color? color) = evaluation.isPending
        ? ('Não enviada', Colors.grey[300])
        : evaluation.isCompleted
            ? ('Concluída', Colors.green[200])
            : ('Em Progresso', Colors.orange[200]);
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.black87)),
      backgroundColor: color,
    );
  }
}

import 'package:flutter/material.dart';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import '../navigation.dart';
import '../services/api_service.dart';
import '../widgets/evaluation_status_chip.dart';
import '../widgets/evidence_photo.dart';
import 'capture_screen.dart';
import 'classification_screen.dart';

/// Tela de uma avaliação: evidências registradas, nova evidência,
/// classificar, apagar evidência e concluir a avaliação.
class GalleryScreen extends StatefulWidget {
  final Evaluation evaluation;

  const GalleryScreen({super.key, required this.evaluation});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with RouteAware {
  late Evaluation _evaluation;
  late Future<List<Evidence>> futureEvidences;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _evaluation = widget.evaluation;
    futureEvidences = _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Voltou de outra tela (captura, classificação): recarrega.
  @override
  void didPopNext() => _reload();

  Future<List<Evidence>> _load() async {
    await ApiService.syncPending();
    return ApiService.getEvidencesByEvaluation(_evaluation);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => futureEvidences = future);
    try {
      await future;
    } catch (_) {
      // exibido pelo FutureBuilder
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String title, String content, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _completeEvaluation() async {
    final ok = await _confirm(
      'Concluir avaliação?',
      'Depois de concluída, não será possível registrar novas evidências nesta avaliação. '
          'Você ainda poderá classificar as evidências já registradas.',
      'Concluir',
    );
    if (!ok) return;
    setState(() => _completing = true);
    try {
      final updated = await ApiService.completeEvaluation(_evaluation);
      if (!mounted) return;
      setState(() => _evaluation = updated);
      _showMessage('✓ Avaliação concluída');
    } catch (e) {
      _showMessage('Erro: $e');
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _deleteEvidence(Evidence evidence) async {
    final ok = await _confirm(
      'Apagar evidência?',
      evidence.isPending
          ? 'Esta evidência ainda não foi enviada e será apagada do aparelho.'
          : 'A foto, a nota e as classificações desta evidência serão apagadas.',
      'Apagar',
    );
    if (!ok) return;
    try {
      await ApiService.deleteEvidence(evidence);
      _showMessage('Evidência apagada');
      _reload();
    } catch (e) {
      _showMessage('Erro: $e');
    }
  }

  void _openEvidence(Evidence evidence) {
    if (evidence.isPending) {
      _showPendingInfo(evidence);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassificationScreen(evidence: evidence, evaluation: _evaluation),
      ),
    );
  }

  void _showPendingInfo(Evidence evidence) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aguardando envio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Esta evidência está guardada no aparelho e será enviada automaticamente '
                'quando houver conexão. Depois de enviada, você poderá classificá-la.',
              ),
              if (evidence.syncError != null) ...[
                const SizedBox(height: 12),
                Text('Último erro ao enviar: ${evidence.syncError}', style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _reload();
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Tentar enviar agora'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEvidence(evidence);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Apagar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _newEvidence() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaptureScreen(evaluation: _evaluation, fromGallery: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_evaluation.culturalSpaceName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_evaluation.isCompleted)
            _completing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.task_alt),
                    tooltip: 'Concluir avaliação',
                    onPressed: _completeEvaluation,
                  ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text([
              _evaluation.visitorName,
              if (_evaluation.spaceType.isNotEmpty) _evaluation.spaceType,
            ].join(' • ')),
            subtitle: Text(_evaluation.isCompleted
                ? 'Avaliação concluída. Toque em uma evidência para classificá-la.'
                : 'Toque em uma evidência para classificá-la. Segure para apagar.'),
            trailing: EvaluationStatusChip(evaluation: _evaluation),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: FutureBuilder<List<Evidence>>(
                future: futureEvidences,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Center(child: Text('${snapshot.error}', textAlign: TextAlign.center)),
                        Center(child: TextButton(onPressed: _reload, child: const Text('Tentar novamente'))),
                      ],
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Center(child: Text('Nenhuma evidência registrada')),
                      ],
                    );
                  }
                  final evidences = snapshot.data!;
                  return GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: evidences.length,
                    itemBuilder: (context, index) {
                      final evidence = evidences[index];
                      return _EvidenceTile(
                        evidence: evidence,
                        onTap: () => _openEvidence(evidence),
                        onLongPress: () => _deleteEvidence(evidence),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _evaluation.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: _newEvidence,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Nova evidência'),
            ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final Evidence evidence;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EvidenceTile({required this.evidence, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = evidence.isPending
        ? (evidence.syncError != null ? 'Erro ao enviar' : 'Não enviada', evidence.syncError != null ? Colors.red : Colors.grey)
        : evidence.isClassified
            ? ('Classificada', Colors.green)
            : ('Registrada', Colors.orange);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            EvidencePhoto(evidence: evidence),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidence.quickNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      avatar: evidence.isPending
                          ? const Icon(Icons.cloud_upload_outlined, size: 14, color: Colors.white)
                          : null,
                      label: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: color,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

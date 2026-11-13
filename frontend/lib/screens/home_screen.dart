import 'package:flutter/material.dart';
import '../models/evaluation.dart';
import '../navigation.dart';
import '../services/api_service.dart';
import '../widgets/evaluation_status_chip.dart';
import 'evaluation_form_screen.dart';
import 'gallery_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late Future<List<Evaluation>> futureEvaluations;

  @override
  void initState() {
    super.initState();
    futureEvaluations = _load();
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

  /// Voltou para a Home (de uma avaliação, do formulário...): recarrega a lista.
  @override
  void didPopNext() => _reload();

  /// Envia pendências offline (se houver) e busca as avaliações.
  Future<List<Evaluation>> _load() async {
    final sent = await ApiService.syncPending();
    if (sent > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ $sent item(ns) guardado(s) no aparelho foram enviados')),
      );
    }
    return ApiService.getAllEvaluations();
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => futureEvaluations = future);
    try {
      await future;
    } catch (_) {
      // o erro é exibido pelo FutureBuilder
    }
  }

  Future<void> _logout() async {
    final pending = ApiService.pendingCount.value;
    if (pending > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sair e descartar pendências?'),
          content: Text(
            'Há $pending item(ns) guardado(s) no aparelho que ainda não foram enviados. '
            'Ao sair, eles serão apagados.\n\nConecte-se à internet e sincronize antes de sair para não perdê-los.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair mesmo assim', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _newEvaluation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EvaluationFormScreen()),
    );
  }

  void _openEvaluation(Evaluation evaluation) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GalleryScreen(evaluation: evaluation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Avaliador COMO D\'EU'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: ApiService.userName == null ? 'Sair' : 'Sair (${ApiService.userName})',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusBanners(onSync: _reload),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: FutureBuilder<List<Evaluation>>(
                future: futureEvaluations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _scrollable(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text('${snapshot.error}', textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _reload, child: const Text('Tentar Novamente')),
                      ],
                    ));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _scrollable(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assessment, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Nenhuma avaliação encontrada'),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _newEvaluation,
                          icon: const Icon(Icons.add),
                          label: const Text('Nova Avaliação'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ],
                    ));
                  }
                  final evaluations = snapshot.data!;
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: evaluations.length,
                    itemBuilder: (context, index) {
                      final evaluation = evaluations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            evaluation.isPending ? Icons.cloud_upload_outlined : Icons.assessment,
                            color: evaluation.isPending ? Colors.grey : Colors.blue,
                          ),
                          title: Text(evaluation.culturalSpaceName),
                          subtitle: Text([
                            evaluation.visitorName,
                            if (evaluation.spaceType.isNotEmpty) evaluation.spaceType,
                          ].join(' • ')),
                          trailing: EvaluationStatusChip(evaluation: evaluation),
                          onTap: () => _openEvaluation(evaluation),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newEvaluation,
        icon: const Icon(Icons.add),
        label: const Text('Nova Avaliação'),
      ),
    );
  }

  /// Mantém o "puxar para atualizar" funcionando mesmo em telas de erro/vazias.
  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: Center(child: child)),
      ),
    );
  }
}

/// Avisos de "sem conexão" e de itens aguardando envio, com botão para sincronizar.
class _StatusBanners extends StatelessWidget {
  final Future<void> Function() onSync;

  const _StatusBanners({required this.onSync});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.offline,
      builder: (context, offline, _) => ValueListenableBuilder<int>(
        valueListenable: ApiService.pendingCount,
        builder: (context, pending, _) {
          if (!offline && pending == 0) return const SizedBox.shrink();
          return MaterialBanner(
            backgroundColor: offline ? Colors.amber[100] : Colors.blue[50],
            leading: Icon(offline ? Icons.cloud_off : Icons.cloud_upload_outlined, color: Colors.black54),
            content: Text(
              [
                if (offline) 'Sem conexão: mostrando dados salvos no aparelho.',
                if (pending > 0) '$pending item(ns) aguardando envio.',
              ].join('\n'),
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: onSync,
                child: Text(pending > 0 ? 'Sincronizar' : 'Tentar de novo'),
              ),
            ],
          );
        },
      ),
    );
  }
}

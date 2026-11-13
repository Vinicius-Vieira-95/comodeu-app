import 'package:flutter/material.dart';
import '../models/classification.dart';
import '../models/como_item.dart';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import '../services/api_service.dart';
import '../widgets/evidence_photo.dart';

/// Dados carregados pela tela.
class _ScreenData {
  final List<ComoItem> suggestions;
  final List<ComoItem> allItems;
  final List<Classification> saved;

  _ScreenData(this.suggestions, this.allItems, this.saved);
}

/// Classificação de uma evidência nos itens COMO D'EU.
///
/// Mostra a classificação já salva (itens marcados + análise). Salvar substitui
/// a classificação anterior, sem criar duplicados.
class ClassificationScreen extends StatefulWidget {
  final Evidence evidence;
  final Evaluation evaluation;

  const ClassificationScreen({
    super.key,
    required this.evidence,
    required this.evaluation,
  });

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  late Future<_ScreenData> futureData;
  final _analysisController = TextEditingController();
  final Set<int> _selectedItemIds = {};
  bool _prefilled = false;
  bool _hasSavedClassification = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    futureData = _load();
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  Future<_ScreenData> _load() async {
    final evidenceId = widget.evidence.id!;
    // Sugestão é opcional: se falhar, devolve lista vazia.
    final results = await Future.wait([
      ApiService.suggestComoItems(widget.evidence.quickNote),
      ApiService.getAllComoItems(),
      ApiService.getClassifications(evidenceId),
    ]);
    final data = _ScreenData(
      results[0] as List<ComoItem>,
      results[1] as List<ComoItem>,
      results[2] as List<Classification>,
    );

    // Preenche com a classificação salva só na primeira carga (não apaga o que o usuário editou).
    if (!_prefilled) {
      _prefilled = true;
      _hasSavedClassification = data.saved.isNotEmpty;
      _selectedItemIds.addAll(data.saved.map((c) => c.comoItemId));
      if (data.saved.isNotEmpty && _analysisController.text.isEmpty) {
        _analysisController.text = data.saved.first.personalAnalysis;
      }
      if (mounted) setState(() {}); // atualiza título e botão fora do FutureBuilder
    }
    return data;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveClassifications() async {
    final analysis = _analysisController.text.trim();
    if (_selectedItemIds.isEmpty || analysis.isEmpty) {
      _showMessage('Selecione itens e escreva sua análise');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.saveClassifications(
        evidenceId: widget.evidence.id!,
        comoItemIds: _selectedItemIds.toList(),
        personalAnalysis: analysis,
      );
      if (!mounted) return;
      _showMessage('✓ Classificação salva!');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e is OfflineException ? 'Sem conexão: a classificação precisa de internet.' : 'Erro: $e');
    }
  }

  Future<void> _deleteEvidence() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar evidência?'),
        content: const Text('A foto, a nota e as classificações desta evidência serão apagadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deleteEvidence(widget.evidence);
      if (!mounted) return;
      _showMessage('Evidência apagada');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Erro: $e');
    }
  }

  Widget _itemTile(ComoItem item, {bool suggested = false}) {
    final isSelected = _selectedItemIds.contains(item.id);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedItemIds.add(item.id);
          } else {
            _selectedItemIds.remove(item.id);
          }
        });
      },
      title: Text('${item.itemNumber}. ${item.name}'),
      subtitle: Text(item.description),
      secondary: suggested ? const Icon(Icons.auto_awesome, color: Colors.amber) : null,
      selected: isSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasSavedClassification ? 'Editar Classificação' : 'Classificar Evidência'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Apagar evidência',
            onPressed: _isLoading ? null : _deleteEvidence,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: EvidencePhoto(evidence: widget.evidence, width: double.infinity, height: 200),
            ),
            const SizedBox(height: 16),
            // Nota original
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                border: Border(left: BorderSide(color: Colors.blue[600]!, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sua nota durante a visita:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.evidence.quickNote, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<_ScreenData>(
              future: futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return Column(
                    children: [
                      Text(error is OfflineException
                          ? 'Sem conexão: a classificação precisa de internet.'
                          : 'Erro ao carregar: $error'),
                      TextButton(
                        onPressed: () => setState(() => futureData = _load()),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  );
                }
                final data = snapshot.data!;
                final suggestedIds = data.suggestions.map((i) => i.id).toSet();
                final others = data.allItems.where((i) => !suggestedIds.contains(i.id)).toList();
                const titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.saved.isNotEmpty)
                      Card(
                        color: Colors.green[50],
                        child: const ListTile(
                          leading: Icon(Icons.check_circle, color: Colors.green),
                          title: Text('Classificação salva', style: TextStyle(color: Colors.black87)),
                          subtitle: Text(
                            'Os itens e a análise abaixo foram salvos antes. '
                            'Ao salvar de novo, a classificação anterior é substituída.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text('Itens Sugeridos', style: titleStyle),
                    const SizedBox(height: 8),
                    if (data.suggestions.isEmpty)
                      const Text('Nenhuma sugestão para esta nota. Escolha na lista abaixo.')
                    else
                      ...data.suggestions.map((i) => _itemTile(i, suggested: true)),
                    const SizedBox(height: 16),
                    const Text('Todos os Itens COMO D\'EU', style: titleStyle),
                    const SizedBox(height: 8),
                    ...others.map(_itemTile),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Sua Análise Pessoal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _analysisController,
              maxLines: 5,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'Por que isso é um problema? Como impacta a experiência?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveClassifications,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_hasSavedClassification ? 'Salvar Alterações' : 'Salvar Classificação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

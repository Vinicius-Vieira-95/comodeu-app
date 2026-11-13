import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import '../models/como_item.dart';
import '../services/api_service.dart';

class ClassificationScreen extends StatefulWidget {
  final Evidence evidence;
  final Evaluation evaluation;

  const ClassificationScreen({
    Key? key,
    required this.evidence,
    required this.evaluation,
  }) : super(key: key);

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  /// [0] = sugestões pela nota, [1] = todos os itens COMO D'EU.
  late Future<List<List<ComoItem>>> futureItems;
  final _analysisController = TextEditingController();
  final Set<int> _selectedItemIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    futureItems = _loadItems();
  }

  Future<List<List<ComoItem>>> _loadItems() async {
    // Sugestão é opcional: se falhar, o usuário ainda escolhe na lista completa.
    final suggestions = await ApiService.suggestComoItems(widget.evidence.quickNote)
        .catchError((_) => <ComoItem>[]);
    final all = await ApiService.getAllComoItems();
    return [suggestions, all];
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
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  Future<void> _saveClassifications() async {
    if (_selectedItemIds.isEmpty || _analysisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione itens e escreva sua análise')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      for (int itemId in _selectedItemIds) {
        await ApiService.createClassification(
          evidenceId: widget.evidence.id!,
          comoItemId: itemId,
          personalAnalysis: _analysisController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Classificação salva!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificar Evidência'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            if (widget.evidence.photoDataBase64 != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(widget.evidence.photoDataBase64!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.evidence.quickNote,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Itens: sugeridos primeiro, depois a lista completa
            FutureBuilder<List<List<ComoItem>>>(
              future: futureItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text('Erro ao carregar itens: ${snapshot.error}'),
                      TextButton(
                        onPressed: () => setState(() => futureItems = _loadItems()),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  );
                }
                final suggestions = snapshot.data![0];
                final suggestedIds = suggestions.map((i) => i.id).toSet();
                final others =
                    snapshot.data![1].where((i) => !suggestedIds.contains(i.id)).toList();
                const titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Itens Sugeridos', style: titleStyle),
                    const SizedBox(height: 8),
                    if (suggestions.isEmpty)
                      const Text('Nenhuma sugestão para esta nota. Escolha na lista abaixo.')
                    else
                      ...suggestions.map((i) => _itemTile(i, suggested: true)),
                    const SizedBox(height: 16),
                    const Text('Todos os Itens COMO D\'EU', style: titleStyle),
                    const SizedBox(height: 8),
                    ...others.map(_itemTile),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            // Análise pessoal
            const Text(
              'Sua Análise Pessoal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _analysisController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Por que isso é um problema? Como impacta a experiência?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveClassifications,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Salvar Classificação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

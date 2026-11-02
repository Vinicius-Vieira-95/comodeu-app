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
  late Future<List<ComoItem>> futureSuggestions;
  final _analysisController = TextEditingController();
  final Set<int> _selectedItemIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    futureSuggestions = ApiService.suggestComoItems(widget.evidence.quickNote);
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  Future<void> _saveClassifications() async {
    if (_selectedItemIds.isEmpty || _analysisController.text.isEmpty) {
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
          personalAnalysis: _analysisController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Classificação salva!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                borderLeft: BorderSide(color: Colors.blue[600]!, width: 4),
                borderRadius: BorderRadius.circular(4),
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
            // Sugestões
            const Text(
              'Itens Sugeridos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ComoItem>>(
              future: futureSuggestions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Nenhuma sugestão disponível');
                } else {
                  final items = snapshot.data!;
                  return Column(
                    children: items.map((item) {
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
                        title: Text(item.name),
                        subtitle: Text(item.description),
                        selected: isSelected,
                      );
                    }).toList(),
                  );
                }
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

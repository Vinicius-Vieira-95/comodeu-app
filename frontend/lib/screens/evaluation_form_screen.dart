import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'capture_screen.dart';

class EvaluationFormScreen extends StatefulWidget {
  const EvaluationFormScreen({Key? key}) : super(key: key);

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final _visitorNameController = TextEditingController();
  final _culturalSpaceController = TextEditingController();
  String? _selectedSpaceType;
  bool _isLoading = false;

  final List<String> spaceTypes = ['Museu', 'Galeria', 'Teatro', 'Biblioteca', 'Outro'];

  @override
  void dispose() {
    _visitorNameController.dispose();
    _culturalSpaceController.dispose();
    super.dispose();
  }

  void _createEvaluation() async {
    final visitorName = _visitorNameController.text.trim();
    final spaceName = _culturalSpaceController.text.trim();
    if (visitorName.isEmpty || spaceName.isEmpty || _selectedSpaceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final evaluation = await ApiService.createEvaluation(
        visitorName: visitorName,
        culturalSpaceName: spaceName,
        spaceType: _selectedSpaceType!,
      );

      if (!mounted) return;

      if (evaluation.isPending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📥 Sem conexão: avaliação guardada no aparelho. Será enviada automaticamente.'),
          ),
        );
      }

      // Substitui o formulário pela captura: ao voltar, o usuário cai direto na Home.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CaptureScreen(evaluation: evaluation),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Avaliação'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados da Avaliação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _visitorNameController,
              decoration: InputDecoration(
                labelText: 'Seu Nome',
                hintText: 'Digite seu nome',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _culturalSpaceController,
              decoration: InputDecoration(
                labelText: 'Nome do Espaço Cultural',
                hintText: 'Ex: Museu de Arte...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSpaceType,
              decoration: InputDecoration(
                labelText: 'Tipo de Espaço',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: spaceTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSpaceType = newValue;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createEvaluation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Criando...' : 'Começar Avaliação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

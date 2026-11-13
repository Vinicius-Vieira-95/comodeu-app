import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/evaluation.dart';
import '../services/api_service.dart';
import 'gallery_screen.dart';

/// Registro rápido de evidência durante a visita: foto + marcação + nota.
class CaptureScreen extends StatefulWidget {
  final Evaluation evaluation;

  /// Aberta a partir da tela da avaliação? Nesse caso "Galeria" só volta.
  final bool fromGallery;

  const CaptureScreen({super.key, required this.evaluation, this.fromGallery = false});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  static const int _maxNoteLength = 200;

  final ImagePicker _picker = ImagePicker();
  final _noteController = TextEditingController();

  Uint8List? _photo;
  int? _markX;
  int? _markY;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _markX = null;
        _markY = null;
      });
    } catch (e) {
      _showMessage('Erro ao capturar foto: $e');
    }
  }

  void _markPoint(TapDownDetails details) {
    final offset = details.localPosition;
    setState(() {
      _markX = offset.dx.toInt();
      _markY = offset.dy.toInt();
    });
    _showMessage('✓ Ponto marcado');
  }

  Future<void> _registerEvidence() async {
    final note = _noteController.text.trim();
    if (_photo == null || note.isEmpty) {
      _showMessage('Tire uma foto e escreva uma nota');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final evidence = await ApiService.registerEvidence(
        evaluation: widget.evaluation,
        photo: _photo!,
        markX: _markX,
        markY: _markY,
        quickNote: note,
      );
      if (!mounted) return;

      _showMessage(evidence.isPending
          ? '📥 Sem conexão: evidência guardada no aparelho. Será enviada automaticamente.'
          : '✓ Evidência registrada!');
      setState(() {
        _photo = null;
        _markX = null;
        _markY = null;
        _noteController.clear();
      });
    } catch (e) {
      _showMessage('Erro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToGallery() {
    if (widget.fromGallery) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GalleryScreen(evaluation: widget.evaluation)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Evidência'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _goToGallery,
            tooltip: 'Ver evidências',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.evaluation.culturalSpaceName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _photo == null
                  ? '📸 Toque abaixo para fotografar'
                  : '👆 Toque na foto para marcar onde está o problema',
              style: const TextStyle(fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _photo == null ? _pickImage : null,
              onTapDown: _photo != null ? _markPoint : null,
              child: Container(
                width: double.infinity,
                height: 300,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: _photo != null
                    ? Stack(
                        children: [
                          Image.memory(
                            _photo!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          if (_markX != null && _markY != null)
                            Positioned(
                              left: _markX! - 15,
                              top: _markY! - 15,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red, width: 3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Clique para capturar foto', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
              ),
            ),
            if (_photo != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tirar outra foto'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLength: _maxNoteLength,
              decoration: InputDecoration(
                labelText: 'Descrição Rápida',
                hintText: 'Ex: Placa com letra pequena',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _registerEvidence,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Registrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToGallery,
                    icon: const Icon(Icons.folder),
                    label: const Text('Evidências'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

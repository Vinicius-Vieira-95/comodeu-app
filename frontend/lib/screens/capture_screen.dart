import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import '../services/api_service.dart';
import 'gallery_screen.dart';

class CaptureScreen extends StatefulWidget {
  final Evaluation evaluation;

  const CaptureScreen({Key? key, required this.evaluation}) : super(key: key);

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final _noteController = TextEditingController();

  File? _selectedImage;
  String? _photoBase64;
  int? _markX;
  int? _markY;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Converter para Base64
        final bytes = await _selectedImage!.readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
          _markX = null;
          _markY = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e')),
      );
    }
  }

  void _markPoint(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = details.localPosition;

    setState(() {
      _markX = offset.dx.toInt();
      _markY = offset.dy.toInt();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Ponto marcado')),
    );
  }

  Future<void> _registerEvidence() async {
    if (_selectedImage == null || _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tire uma foto e escreva uma nota')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final evidence = await ApiService.registerEvidence(
        evaluationId: widget.evaluation.id!,
        photoBase64: _photoBase64!,
        markX: _markX,
        markY: _markY,
        quickNote: _noteController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Evidência registrada!')),
      );

      setState(() {
        _selectedImage = null;
        _photoBase64 = null;
        _markX = null;
        _markY = null;
        _noteController.clear();
      });
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

  void _goToGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(evaluation: widget.evaluation),
      ),
    ).then((value) {
      if (value == true) {
        Navigator.pop(context, true);
      }
    });
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
            tooltip: 'Ver Galeria',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registre uma Evidência',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '📸 Fotografe e marque onde está o problema',
              style: TextStyle(fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              onTapDown: _selectedImage != null ? _markPoint : null,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          Image.file(
                            _selectedImage!,
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
                          Text(
                            'Clique para capturar foto',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Descrição Rápida',
                hintText: 'Ex: Placa com letra pequena',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Registrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToGallery,
                    icon: const Icon(Icons.folder),
                    label: const Text('Galeria'),
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

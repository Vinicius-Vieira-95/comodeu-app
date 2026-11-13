import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/evidence.dart';
import '../services/api_service.dart';

/// Foto de uma evidência, carregada sob demanda (servidor, cache do aparelho
/// ou fila offline) por [ApiService.getEvidencePhoto].
class EvidencePhoto extends StatefulWidget {
  final Evidence evidence;
  final BoxFit fit;
  final double? width;
  final double? height;

  const EvidencePhoto({
    super.key,
    required this.evidence,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<EvidencePhoto> createState() => _EvidencePhotoState();
}

class _EvidencePhotoState extends State<EvidencePhoto> {
  late Future<Uint8List?> _photo;

  @override
  void initState() {
    super.initState();
    _photo = ApiService.getEvidencePhoto(widget.evidence);
  }

  @override
  void didUpdateWidget(EvidencePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evidence.id != widget.evidence.id) {
      _photo = ApiService.getEvidencePhoto(widget.evidence);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _photo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholder(const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ));
        }
        final bytes = snapshot.data;
        if (snapshot.hasError || bytes == null) {
          return _placeholder(Icon(
            snapshot.hasError ? Icons.cloud_off : Icons.image_not_supported,
            color: Colors.grey[500],
          ));
        }
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) =>
              _placeholder(Icon(Icons.broken_image, color: Colors.grey[500])),
        );
      },
    );
  }

  Widget _placeholder(Widget child) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: child,
    );
  }
}

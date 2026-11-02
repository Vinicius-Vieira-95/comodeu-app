import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/evaluation.dart';
import '../models/evidence.dart';
import '../services/api_service.dart';
import 'classification_screen.dart';

class GalleryScreen extends StatefulWidget {
  final Evaluation evaluation;

  const GalleryScreen({Key? key, required this.evaluation}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<Evidence>> futureEvidences;

  @override
  void initState() {
    super.initState();
    futureEvidences = ApiService.getEvidencesByEvaluation(widget.evaluation.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Evidências'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureEvidences = ApiService.getEvidencesByEvaluation(widget.evaluation.id!);
          });
        },
        child: FutureBuilder<List<Evidence>>(
          future: futureEvidences,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Erro: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('Nenhuma evidência registrada'),
                  ],
                ),
              );
            } else {
              final evidences = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: evidences.length,
                itemBuilder: (context, index) {
                  final evidence = evidences[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassificationScreen(
                            evidence: evidence,
                            evaluation: widget.evaluation,
                          ),
                        ),
                      ).then((value) {
                        if (value == true) {
                          setState(() {
                            futureEvidences = ApiService.getEvidencesByEvaluation(widget.evaluation.id!);
                          });
                        }
                      });
                    },
                    child: Card(
                      child: Stack(
                        children: [
                          if (evidence.photoDataBase64 != null)
                            Image.memory(
                              base64Decode(evidence.photoDataBase64!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          else
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(
                                      evidence.status == 'REGISTERED' ? 'Registrada' : 'Classificada',
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                    backgroundColor: evidence.status == 'REGISTERED'
                                        ? Colors.orange
                                        : Colors.green,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

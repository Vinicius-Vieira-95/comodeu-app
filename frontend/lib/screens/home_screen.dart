import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/evaluation.dart';
import 'evaluation_form_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Evaluation>> futureEvaluations;

  @override
  void initState() {
    super.initState();
    futureEvaluations = ApiService.getAllEvaluations();
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
            tooltip: ApiService.userName == null
                ? 'Sair'
                : 'Sair (${ApiService.userName})',
            onPressed: () async {
              await ApiService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureEvaluations = ApiService.getAllEvaluations();
          });
        },
        child: FutureBuilder<List<Evaluation>>(
          future: futureEvaluations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erro: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          futureEvaluations = ApiService.getAllEvaluations();
                        });
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assessment, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Nenhuma avaliação encontrada'),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EvaluationFormScreen(),
                          ),
                        ).then((value) {
                          if (value == true) {
                            setState(() {
                              futureEvaluations = ApiService.getAllEvaluations();
                            });
                          }
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nova Avaliação'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final evaluation = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.assessment, color: Colors.blue),
                      title: Text(evaluation.culturalSpaceName),
                      subtitle: Text('${evaluation.visitorName} • ${evaluation.spaceType}'),
                      trailing: Chip(
                        label: Text(evaluation.status == 'IN_PROGRESS' ? 'Em Progresso' : 'Concluído'),
                        backgroundColor: evaluation.status == 'IN_PROGRESS'
                            ? Colors.orange[200]
                            : Colors.green[200],
                      ),
                      onTap: () {
                        // Navegar para tela de avaliação
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EvaluationFormScreen(),
            ),
          ).then((value) {
            if (value == true) {
              setState(() {
                futureEvaluations = ApiService.getAllEvaluations();
              });
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Avaliação'),
      ),
    );
  }
}

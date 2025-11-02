import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pesticide_application.dart';
import '../../repositories/pesticide_application_repository.dart';
import '../../widgets/loading_indicator.dart';

class PesticideApplicationListScreen extends StatefulWidget {
  const PesticideApplicationListScreen({Key? key}) : super(key: key);

  @override
  _PesticideApplicationListScreenState createState() => _PesticideApplicationListScreenState();
}

class _PesticideApplicationListScreenState extends State<PesticideApplicationListScreen> {
  final PesticideApplicationRepository _repository = PesticideApplicationRepository();
  List<PesticideApplication> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final applications = await _repository.getAllPesticideApplications();
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicações de Defensivos'),
        // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_drink_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma aplicação de defensivo registrada',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque no botão + para adicionar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final application = _applications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          application.productName ?? 'Produto não especificado',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(application.date)}\n'
                          'Cultura: ${application.cropName ?? 'Cultura não especificada'}\n'
                          'Dose: ${application.dosePerHa} ${application.doseUnit}/ha',
                        ),
                        leading: CircleAvatar(
                          // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
                          child: Icon(
                            Icons.local_drink_outlined,
                            color: Colors.white,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/application/form',
                                  arguments: {'applicationId': application.id},
                                ).then((_) => _loadApplications());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteConfirmationDialog(application);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/application/details',
                            arguments: {'applicationId': application.id},
                          ).then((_) => _loadApplications());
                        },
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/application/form')
              .then((_) => _loadApplications());
        },
        label: const Text('Nova Aplicação'),
        icon: const Icon(Icons.add),
        // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
      ),
    );
  }

  void _showDeleteConfirmationDialog(PesticideApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir este registro de aplicação?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (application.id != null) {
                  await _repository.deletePesticideApplication(application.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registro excluído com sucesso!'),
                    ),
                  );
                  _loadApplications();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro: ID da aplicação não encontrado'),
                      // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir registro: $e')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

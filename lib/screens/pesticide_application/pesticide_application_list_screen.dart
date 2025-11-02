import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pesticide_application.dart';
import '../../repositories/pesticide_application_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state.dart';

class PesticideApplicationListScreen extends StatefulWidget {
  const PesticideApplicationListScreen({Key? key}) : super(key: key);

  @override
  State<PesticideApplicationListScreen> createState() => _PesticideApplicationListScreenState();
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
      final applications = await _repository.getAllApplications();
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar aplicações: $e')),
        );
      }
    }
  }

  Future<void> _deleteApplication(PesticideApplication application) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir esta aplicação? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _repository.deleteApplication(application.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aplicação excluída com sucesso')),
        );
        _loadApplications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir aplicação: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Aplicações de Defensivos',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implementar filtros no futuro
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtros serão implementados em breve')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? EmptyState(
                  icon: Icons.local_drink,
                  title: 'Nenhuma aplicação registrada',
                  message: 'Registre suas aplicações de defensivos para monitorar o uso de produtos em suas lavouras.',
                  buttonText: 'Registrar Aplicação',
                  onButtonPressed: () => _navigateToApplicationForm(context),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.builder(
                    itemCount: _applications.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final application = _applications[index];
                      return _buildApplicationCard(application);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToApplicationForm(context),
        // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildApplicationCard(PesticideApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // onTap: () => _navigateToApplicationDetails(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 application),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      application.purpose ?? 'Sem finalidade',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(application.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Data: ${DateFormatter.format(application.date)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Responsável: ${application.responsiblePerson}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Talhão: ${application.plotName}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${application.products?.length ?? 0} produto(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A4F3D),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _navigateToApplicationEdit(context, application),
                        color: Colors.blue,
                        tooltip: 'Editar',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteApplication(application),
                        color: Colors.red,
                        tooltip: 'Excluir',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    IconData icon;
    
    switch (status?.toLowerCase() ?? 'desconhecido') {
      case 'concluída':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'em andamento':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'planejada':
        color = Colors.blue;
        icon = Icons.event;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status ?? 'Desconhecido',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToApplicationForm(BuildContext context) {
    // Implementar navegação para o formulário de aplicação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulário de aplicação será implementado em breve')),
    );
  }

  void _navigateToApplicationDetails(BuildContext context, PesticideApplication application) {
    // Implementar navegação para os detalhes da aplicação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detalhes da aplicação serão implementados em breve')),
    );
  }

  void _navigateToApplicationEdit(BuildContext context, PesticideApplication application) {
    // Implementar navegação para a edição da aplicação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edição de aplicação será implementada em breve')),
    );
  }
}

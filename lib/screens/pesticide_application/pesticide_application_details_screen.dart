import 'package:flutter/material.dart';
import '../../models/pesticide_application.dart';
import '../../repositories/pesticide_application_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';

class PesticideApplicationDetailsScreen extends StatefulWidget {
  final String applicationId;

  const PesticideApplicationDetailsScreen({Key? key, required this.applicationId}) : super(key: key);

  @override
  State<PesticideApplicationDetailsScreen> createState() => _PesticideApplicationDetailsScreenState();
}

class _PesticideApplicationDetailsScreenState extends State<PesticideApplicationDetailsScreen> {
  final PesticideApplicationRepository _repository = PesticideApplicationRepository();
  PesticideApplication? _application;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final application = await _repository.getById(widget.applicationId);
      setState(() {
        _application = application;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar aplicação: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteApplication() async {
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
      try {
        await _repository.deleteApplication(widget.applicationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aplicação excluída com sucesso')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir aplicação: $e')),
          );
        }
      }
    }
  }

  void _navigateToEdit() {
    Navigator.pushNamed(
      context,
      '/application/form',
      arguments: {'applicationId': widget.applicationId},
    ).then((value) {
      if (value == true) {
        _loadApplication();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Detalhes da Aplicação',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteApplication,
            tooltip: 'Excluir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _application == null
              ? const Center(child: Text('Aplicação não encontrada'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildInfoSection('Informações Básicas', [
                        _buildInfoItem('Talhão', _application!.plotName ?? 'Não informado'),
                        _buildInfoItem('Data', DateFormatter.format(_application!.date)),
                        _buildInfoItem('Finalidade', _application!.purpose ?? 'Não informada'),
                        _buildInfoItem('Responsável', _application!.responsiblePerson ?? 'Não informado'),
                        _buildInfoItem('Status', _application!.status ?? 'Não informado'),
                      ]),
                      const SizedBox(height: 24),
                      _buildProductsSection(),
                      const SizedBox(height: 24),
                      if (_application!.notes != null && _application!.notes!.isNotEmpty)
                        _buildInfoSection('Observações', [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_application!.notes!),
                          ),
                        ]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    _application!.purpose ?? 'Sem finalidade',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(_application!.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Talhão: ${_application!.plotName ?? "Não informado"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Data: ${DateFormatter.format(_application!.date)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    final products = _application!.products;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produtos Utilizados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${products?.length ?? 0} produto(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A4F3D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (products == null || products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Nenhum produto registrado',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Dose: ${product.dose} ${product.doseUnit}'),
                        Text('Quantidade: ${product.quantity} ${product.quantityUnit}'),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: () {
                // Implementar adição de produtos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade de adicionar produtos será implementada em breve')),
                );
              },
              label: 'Adicionar Produto',
            ),
          ],
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
}

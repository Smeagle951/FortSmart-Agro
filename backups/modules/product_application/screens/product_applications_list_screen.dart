import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_widget.dart' as app_error;
import '../models/product_application_model.dart';
import '../services/product_application_service.dart';
import 'product_application_form_screen.dart';

class ProductApplicationsListScreen extends StatefulWidget {
  const ProductApplicationsListScreen({Key? key}) : super(key: key);

  @override
  _ProductApplicationsListScreenState createState() => _ProductApplicationsListScreenState();
}

class _ProductApplicationsListScreenState extends State<ProductApplicationsListScreen> {
  final ProductApplicationService _applicationService = ProductApplicationService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<ProductApplicationModel> _applications = [];
  
  // Filtros
  String? _selectedPlotId;
  String? _selectedCropId;
  ApplicationType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }
  
  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      List<ProductApplicationModel> applications;
      
      // Aplicar filtros se existirem
      if (_selectedPlotId != null) {
        applications = await _applicationService.getApplicationsByPlot(_selectedPlotId!);
      } else if (_selectedCropId != null) {
        applications = await _applicationService.getApplicationsByCrop(_selectedCropId!);
      } else if (_selectedType != null) {
        applications = await _applicationService.getApplicationsByType(_selectedType!);
      } else if (_startDate != null && _endDate != null) {
        applications = await _applicationService.getApplicationsByDateRange(_startDate!, _endDate!);
      } else {
        applications = await _applicationService.getAllApplications();
      }
      
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }
  
  void _resetFilters() {
    setState(() {
      _selectedPlotId = null;
      _selectedCropId = null;
      _selectedType = null;
      _startDate = null;
      _endDate = null;
    });
    
    _loadApplications();
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Aplicações'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Implementar widgets de filtro aqui
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadApplications();
                },
                child: const Text('Aplicar Filtros'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetFilters();
                },
                child: const Text('Limpar Filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToFormScreen({ProductApplicationModel? application}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductApplicationFormScreen(
          application: application,
        ),
      ),
    ).then((_) => _loadApplications());
  }
  
  Future<void> _confirmDelete(ProductApplicationModel application) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Aplicação'),
        content: Text('Deseja realmente excluir a aplicação de ${application.applicationDate.toString().substring(0, 10)} em ${application.plotName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        await _applicationService.deleteApplication(application.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aplicação excluída com sucesso')),
        );
        _loadApplications();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir aplicação: ${e.toString()}')),
        );
      }
    }
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  String _getApplicationTypeText(ApplicationType type) {
    switch (type) {
      case ApplicationType.terrestrial:
        return 'Terrestre';
      case ApplicationType.aerial:
        return 'Aérea';
    }
  }
  
  Widget _buildApplicationCard(ProductApplicationModel application) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        // onTap: () => _navigateToFormScreen(application: application), // onTap não é suportado em Polygon no flutter_map 5.0.0
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(application.applicationDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: application.applicationType == ApplicationType.terrestrial
                          ? Colors.green[100]
                          : Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getApplicationTypeText(application.applicationType),
                      style: TextStyle(
                        color: application.applicationType == ApplicationType.terrestrial
                            ? Colors.green[800]
                            : Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${application.plotName} (${application.cropName})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    application.responsibleName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.landscape, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${application.area.toStringAsFixed(2)} ha',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Controle: ${application.controlType.controlTypesString}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Produtos: ${application.products.length}',
                style: const TextStyle(fontSize: 14),
              ),
              if (application.products.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  application.products.map((p) => p.productName).join(', '),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _navigateToFormScreen(application: application),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(application),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicações de Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Carregando aplicações...')
          : _hasError
              ? app_error.AppErrorWidget(
                  message: 'Erro ao carregar aplicações: $_errorMessage',
                  onRetry: _loadApplications,
                )
              : _applications.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.eco,
                      message: 'Nenhuma aplicação encontrada. Clique no botão + para adicionar uma nova aplicação de produtos',
                      actionLabel: 'Nova Aplicação',
                      onAction: () => _navigateToFormScreen(),
                    )
                  : ListView.builder(
                      itemCount: _applications.length,
                      itemBuilder: (context, index) => _buildApplicationCard(_applications[index]),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToFormScreen(),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

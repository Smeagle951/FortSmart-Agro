import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:open_file/open_file.dart'; // Removido - causando problemas de build
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../../services/farm_service.dart';
import '../../../providers/user_provider.dart';
import '../services/inventory_report_service.dart';
import '../../../modules/inventory/services/inventory_service.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({Key? key}) : super(key: key);

  @override
  _InventoryReportScreenState createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedProductName;
  String? _selectedProductType;
  String? _selectedSupplier;
  String? _selectedBatchNumber;
  
  final List<String> _productTypes = [
    'Defensivo',
    'Fertilizante',
    'Semente',
    'Combustível',
    'Outros'
  ];
  
  List<String> _productNames = [];
  List<String> _suppliers = [];
  List<String> _batchNumbers = [];
  
  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }
  
  Future<void> _loadFilterOptions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      final products = await inventoryService.getAllProducts();
      
      // Extrair nomes de produtos únicos
      final productNames = products.map((p) => p.name).toSet().toList();
      productNames.sort();
      
      // Extrair fornecedores únicos
      final suppliers = products
          .where((p) => p.supplier != null && p.supplier!.isNotEmpty)
          .map((p) => p.supplier!)
          .toSet()
          .toList();
      suppliers.sort();
      
      // Extrair lotes únicos
      final batchNumbers = products
          .where((p) => p.batchNumber.isNotEmpty)
          .map((p) => p.batchNumber)
          .toSet()
          .toList();
      batchNumbers.sort();
      
      setState(() {
        _productNames = productNames;
        _suppliers = suppliers.cast<String>();
        _batchNumbers = batchNumbers.cast<String>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erro ao carregar opções de filtro: $e');
    }
  }
  
  Future<void> _generateReport(bool exportToExcel) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      final farmService = Provider.of<FarmService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final reportService = InventoryReportService(inventoryService);
      
      final currentFarm = await farmService.getCurrentFarm();
      final currentUser = userProvider.currentUser;
      
      File reportFile;
      
      if (exportToExcel) {
        reportFile = await reportService.exportStockReportToExcel(
          farmName: currentFarm?.name ?? 'Fazenda',
          responsiblePerson: currentUser?.name ?? 'Usuário',
          startDate: _startDate,
          endDate: _endDate,
          productName: _selectedProductName,
          productType: _selectedProductType,
          supplier: _selectedSupplier,
          batchNumber: _selectedBatchNumber,
        );
      } else {
        reportFile = await reportService.generateStockReportPdf(
          farmName: currentFarm?.name ?? 'Fazenda',
          responsiblePerson: currentUser?.name ?? 'Usuário',
          startDate: _startDate,
          endDate: _endDate,
          productName: _selectedProductName,
          productType: _selectedProductType,
          supplier: _selectedSupplier,
          batchNumber: _selectedBatchNumber,
        );
      }
      
      setState(() {
        _isLoading = false;
      });
      
      _showReportActions(reportFile);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erro ao gerar relatório: $e');
    }
  }
  
  void _showReportActions(File reportFile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Abrir relatório'),
                          onTap: () async {
                Navigator.pop(context);
                // OpenFile.open(reportFile.path); // Removido - usando share_plus como alternativa
                await Share.shareXFiles([XFile(reportFile.path)], text: 'Relatório de Inventário');
              }
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Compartilhar'),
            onTap: () {
              Navigator.pop(context);
              Share.share(reportFile.path, 
                subject: 'Relatório de Estoque - FortSmart Agro');
            },  
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
      ),
    );
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFilterOptions,
            tooltip: 'Atualizar filtros',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Relatório de Estoque - Conferência Atual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Filtros
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de data de vencimento
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data de vencimento',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            title: Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} até ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                  : 'Selecione um período',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            // onTap: () => _selectDateRange(context), // onTap não é suportado em Polygon no flutter_map 5.0.0
                          ),
                          if (_startDate != null && _endDate != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                              },
                              child: const Text('Limpar seleção'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de nome do produto
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nome do produto',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedProductName,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            hint: const Text('Selecione um produto'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todos os produtos'),
                              ),
                              ..._productNames.map((name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedProductName = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de tipo de produto
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de produto',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedProductType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            hint: const Text('Selecione um tipo'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todos os tipos'),
                              ),
                              ..._productTypes.map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedProductType = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de fornecedor
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fornecedor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedSupplier,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            hint: const Text('Selecione um fornecedor'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todos os fornecedores'),
                              ),
                              ..._suppliers.map((supplier) => DropdownMenuItem<String>(
                                value: supplier,
                                child: Text(supplier),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSupplier = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de lote
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lote',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBatchNumber,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            hint: const Text('Selecione um lote'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todos os lotes'),
                              ),
                              ..._batchNumbers.map((batch) => DropdownMenuItem<String>(
                                value: batch,
                                child: Text(batch),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedBatchNumber = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Gerar PDF'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _generateReport(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Exportar Excel'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _generateReport(true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.filter_alt),
                      label: const Text('Limpar Filtros'),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedProductName = null;
                          _selectedProductType = null;
                          _selectedSupplier = null;
                          _selectedBatchNumber = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:open_file/open_file.dart'; // Removido - causando problemas de build
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../../services/farm_service.dart';
import '../services/product_application_report_service.dart';
import '../../../modules/product_application/services/product_application_service.dart';

class ProductApplicationReportScreen extends StatefulWidget {
  const ProductApplicationReportScreen({Key? key}) : super(key: key);

  @override
  _ProductApplicationReportScreenState createState() => _ProductApplicationReportScreenState();
}

class _ProductApplicationReportScreenState extends State<ProductApplicationReportScreen> {
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCrop;
  String? _selectedField;
  String? _selectedProduct;
  String? _selectedResponsible;
  
  List<String> _crops = [];
  List<String> _fields = [];
  List<String> _products = [];
  List<String> _responsibles = [];
  
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
      final applicationService = Provider.of<ProductApplicationService>(context, listen: false);
      final applications = await applicationService.getAllApplications();
      
      // Extrair culturas únicas
      final crops = applications
          .where((a) => a.cropName?.isNotEmpty ?? false)
          .map((a) => a.cropName ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      crops.sort();
      
      // Extrair talhões únicos
      final fields = applications
          .where((a) => a.plotName?.isNotEmpty ?? false)
          .map((a) => a.plotName ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      fields.sort();
      
      // Extrair produtos únicos
      final products = <String>{};
      for (var application in applications) {
        if (application.products != null) {
          for (var product in application.products!) {
            if (product.productName != null && product.productName!.isNotEmpty) {
              products.add(product.productName!);
            }
          }
        }
      }
      final productsList = products.toList();
      productsList.sort();
      
      // Extrair responsáveis únicos
      final responsibles = applications
          .where((a) => a.responsibleName?.isNotEmpty ?? false)
          .map((a) => a.responsibleName ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      responsibles.sort();
      
      setState(() {
        _crops = crops.cast<String>();
        _fields = fields.cast<String>();
        _products = productsList.cast<String>();
        _responsibles = responsibles.cast<String>();
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
      final applicationService = Provider.of<ProductApplicationService>(context, listen: false);
      final farmService = Provider.of<FarmService>(context, listen: false);
      
      final reportService = ProductApplicationReportService(applicationService);
      
      final currentFarm = await farmService.getCurrentFarm();
      
      File reportFile;
      
      if (exportToExcel) {
        reportFile = await reportService.exportApplicationReportToExcel(
          farmName: currentFarm?.name ?? 'Fazenda',
          startDate: _startDate,
          endDate: _endDate,
          cropName: _selectedCrop,
          fieldName: _selectedField,
          productName: _selectedProduct,
          responsiblePerson: _selectedResponsible,
        );
      } else {
        reportFile = await reportService.generateApplicationReportPdf(
          farmName: currentFarm?.name ?? 'Fazenda',
          startDate: _startDate,
          endDate: _endDate,
          cropName: _selectedCrop,
          fieldName: _selectedField,
          productName: _selectedProduct,
          responsiblePerson: _selectedResponsible,
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
                await Share.shareXFiles([XFile(reportFile.path)], text: 'Relatório de Aplicação de Produtos');
              }, // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Compartilhar'),
            onTap: () {
              Navigator.pop(context);
              Share.share(reportFile.path, 
                subject: 'Relatório de Aplicações - FortSmart Agro');
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Enviar por e-mail'),
            onTap: () {
              Navigator.pop(context);
              // Implementar envio por e-mail
              _showErrorSnackBar('Função de envio por e-mail será implementada em breve.');
            }, // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
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
        title: const Text('Relatório de Aplicações'),
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
                    'Relatório de Gasto de Estoque por Aplicação',
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
                  
                  // Filtro de período de aplicação
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Período de aplicação',
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
                  
                  // Filtro de cultura
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cultura',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCrop,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            hint: const Text('Selecione uma cultura'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todas as culturas'),
                              ),
                              ..._crops.map((crop) => DropdownMenuItem<String>(
                                value: crop,
                                child: Text(crop),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCrop = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de talhão
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Talhão',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedField,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            hint: const Text('Selecione um talhão'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todos os talhões'),
                              ),
                              ..._fields.map((field) => DropdownMenuItem<String>(
                                value: field,
                                child: Text(field),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedField = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de produto
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produto',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedProduct,
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
                              ..._products.map((product) => DropdownMenuItem<String>(
                                value: product,
                                child: Text(product),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedProduct = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro de responsável
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Responsável',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedResponsible,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            hint: const Text('Selecione um responsável'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todos os responsáveis'),
                              ),
                              ..._responsibles.map((responsible) => DropdownMenuItem<String>(
                                value: responsible,
                                child: Text(responsible),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedResponsible = value;
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
                          _selectedCrop = null;
                          _selectedField = null;
                          _selectedProduct = null;
                          _selectedResponsible = null;
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

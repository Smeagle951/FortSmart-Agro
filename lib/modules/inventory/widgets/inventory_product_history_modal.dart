import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import '../models/inventory_product_model.dart';
import '../models/inventory_transaction_model.dart';
import '../models/product_class_model.dart';
import '../services/inventory_service.dart';
import '../services/inventory_report_service.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/loading_indicator_widget.dart';

/// Enum para definir o formato de exportação
enum ExportFormat { pdf, excel }

/// Modal para exibir o histórico de transações de um produto do estoque
class InventoryProductHistoryModal extends StatefulWidget {
  final InventoryProductModel product;

  const InventoryProductHistoryModal({Key? key, required this.product}) : super(key: key);

  @override
  _InventoryProductHistoryModalState createState() => _InventoryProductHistoryModalState();
}

class _InventoryProductHistoryModalState extends State<InventoryProductHistoryModal> {
  // Serviços
  final InventoryService _inventoryService = InventoryService();
  final InventoryReportService _reportService = InventoryReportService();

  // Variáveis de estado
  bool _isLoading = true;
  bool _isExporting = false;
  bool _hasError = false;
  String? _errorMessage;

  // Dados
  List<InventoryTransactionModel> _transactions = [];
  List<InventoryTransactionModel> _filteredTransactions = [];

  // Paginação
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;

  // Filtros
  DateTime? _startDate;
  DateTime? _endDate;
  String? _transactionType;
  
  // Exportação
  ExportFormat _exportFormat = ExportFormat.pdf;

  // Formatadores
  final NumberFormat _quantityFormat = NumberFormat.decimalPattern('pt_BR');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }
  
  // Carrega as transações do produto e aplica filtros
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Busca as transações do produto pelo ID
      final transactions = await _inventoryService.getTransactions(widget.product.id);
      var filtered = transactions;
      
      // Aplica os filtros selecionados
      if (_startDate != null) {
        filtered = filtered.where((t) => t.date.isAfter(_startDate!)).toList();
      }
      if (_endDate != null) {
        filtered = filtered.where((t) => t.date.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
      }
      if (_transactionType != null && _transactionType!.isNotEmpty) {
        filtered = filtered.where((t) => t.type == _transactionType).toList();
      }
      
      // Ordena as transações por data (mais recentes primeiro)
      filtered.sort((a, b) => b.date.compareTo(a.date));
      
      // Calcula o número total de páginas
      _totalPages = (filtered.length / _itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
      if (_currentPage > _totalPages) {
        _currentPage = _totalPages;
      }
      
      setState(() {
        _transactions = transactions;
        _filteredTransactions = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erro ao carregar histórico: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  // Retorna as transações da página atual
  List<InventoryTransactionModel> _getCurrentPageTransactions() {
    if (_filteredTransactions.isEmpty) {
      return [];
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > _filteredTransactions.length 
        ? _filteredTransactions.length 
        : startIndex + _itemsPerPage;
        
    if (startIndex >= _filteredTransactions.length) {
      return [];
    }
    
    return _filteredTransactions.sublist(startIndex, endIndex);
  }
  
  // Navega para a próxima página
  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }
  
  // Navega para a página anterior
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }
  
  // Limpa todos os filtros aplicados
  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _transactionType = null;
      _currentPage = 1;
    });
    _loadTransactions();
  }
  
  // Aplica os filtros selecionados
  void _applyFilters() {
    _loadTransactions();
  }
  
  // Exporta o relatório no formato selecionado
  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
    });
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final productId = widget.product.id.toString();
      final fileName = 'historico_${productId}_${DateTime.now().millisecondsSinceEpoch}';
      
      File? file;
      
      if (_exportFormat == ExportFormat.pdf) {
        file = await _reportService.generateProductHistoryReport(widget.product);
      } else {
        file = await _reportService.exportProductHistoryToExcel(widget.product);
      }
      
      setState(() {
        _isExporting = false;
      });
      
      if (file != null && await file.exists()) {
        // await OpenFile.open(file.path); // Removido - usando share_plus como alternativa
        await Share.shareXFiles([XFile(file.path)], text: 'Histórico do Produto');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Relatório exportado com sucesso!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao exportar relatório: arquivo não encontrado')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _hasError = true;
        _errorMessage = 'Erro ao exportar relatório: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar relatório: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 700 
            ? 700 
            : MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text(
                  'Histórico de Movimentações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Informações do produto
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Classe: ${_getProductClassName(widget.product.productClass)}',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getProductClassColor(widget.product.productClass),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lote: ${widget.product.batchNumber}',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Estoque Atual: ${widget.product.quantity} ${widget.product.unit}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filtros (seção colapsável)
            _buildFiltersSection(),
            
            // Conteúdo - Lista de transações
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicatorWidget())
                  : _hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.danger,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage ?? 'Erro ao carregar histórico',
                                style: const TextStyle(color: AppColors.danger),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTransactions,
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: AppColors.primary, // backgroundColor não é suportado em flutter_map 5.0.0
                                ),
                                child: const Text(
                                  'Tentar Novamente',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filteredTransactions.isEmpty
                          ? const EmptyStateWidget(
                              icon: Icons.history,
                              message: 'Nenhuma movimentação encontrada para este produto.',
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _getCurrentPageTransactions().length,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemBuilder: (context, index) {
                                      final transaction = _getCurrentPageTransactions()[index];
                                      return _buildTransactionItem(transaction);
                                    },
                                  ),
                                ),
                                // Controles de paginação
                                if (_totalPages > 1) _buildPaginationControls(),
                              ],
                            ),
            ),
            
            // Rodapé
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Se a largura for menor que 600px, empilhar verticalmente
                  if (constraints.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Seletor de formato de exportação e botão exportar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Seletor de formato
                            Row(
                              children: [
                                const Text('Formato: '),
                                DropdownButton<ExportFormat>(
                                  value: _exportFormat,
                                  onChanged: (ExportFormat? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _exportFormat = newValue;
                                      });
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(value: ExportFormat.pdf, child: Text('PDF')),
                                    DropdownMenuItem(value: ExportFormat.excel, child: Text('Excel')),
                                  ],
                                ),
                              ],
                            ),
                            // Botão de exportar
                            ElevatedButton.icon(
                              onPressed: _isExporting ? null : _exportReport,
                              icon: _isExporting 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download, size: 16),
                              label: Text(_isExporting ? 'Exportando...' : 'Exportar'),
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: AppColors.secondary, // backgroundColor não é suportado em flutter_map 5.0.0
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Botão fechar
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: AppColors.primary, // backgroundColor não é suportado em flutter_map 5.0.0
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Fechar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Para telas maiores, usar layout horizontal
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Seletor de formato de exportação
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Formato: '),
                              DropdownButton<ExportFormat>(
                                value: _exportFormat,
                                onChanged: (ExportFormat? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _exportFormat = newValue;
                                    });
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(value: ExportFormat.pdf, child: Text('PDF')),
                                  DropdownMenuItem(value: ExportFormat.excel, child: Text('Excel')),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Botão de exportar
                              ElevatedButton.icon(
                                onPressed: _isExporting ? null : _exportReport,
                                icon: _isExporting 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.download, size: 16),
                                label: Text(_isExporting ? 'Exportando...' : 'Exportar'),
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: AppColors.secondary, // backgroundColor não é suportado em flutter_map 5.0.0
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botão fechar
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: AppColors.primary, // backgroundColor não é suportado em flutter_map 5.0.0
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Fechar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return ExpansionTile(
      title: const Text(
        'Filtros',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: const Icon(Icons.filter_list),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Data Inicial',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _startDate != null 
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : '',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Data Final',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _endDate != null 
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : '',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Transação',
                  border: OutlineInputBorder(),
                ),
                value: _transactionType,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'entry', child: Text('Entrada')),
                  DropdownMenuItem(value: 'manual', child: Text('Saída Manual')),
                  DropdownMenuItem(value: 'application', child: Text('Aplicação')),
                  DropdownMenuItem(value: 'adjustment', child: Text('Ajuste')),
                ],
                onChanged: (value) {
                  setState(() {
                    _transactionType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: AppColors.primary, // backgroundColor não é suportado em flutter_map 5.0.0
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página $_currentPage de $_totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1 ? _previousPage : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Obtém o nome da classe do produto para exibição
  String _getProductClassName(ProductClass productClass) {
    return ProductClassHelper.getName(productClass);
  }

  Color _getProductClassColor(ProductClass productClass) {
    return ProductClassHelper.getColor(productClass);
  }

  Widget _buildTransactionItem(InventoryTransactionModel transaction) {
    // Formatar data e quantidade
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(transaction.date);
    final quantityFormatted = _quantityFormat.format(transaction.quantity);
    
    // Determina o ícone e a cor com base no tipo de transação
    IconData icon;
    Color color;
    String typeText;

    switch (transaction.type) {
      case TransactionType.entry:
        icon = Icons.add_circle;
        color = Colors.green;
        typeText = 'Entrada';
        break;
      case TransactionType.manual:
        icon = Icons.remove_circle;
        color = Colors.red;
        typeText = 'Saída Manual';
        break;
      case TransactionType.application:
        icon = Icons.agriculture;
        color = Colors.orange;
        typeText = 'Aplicação';
        break;
      case TransactionType.adjustment:
        icon = Icons.sync;
        color = Colors.blue;
        typeText = 'Ajuste';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        typeText = 'Desconhecido';
    }
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormatted,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${transaction.isEntry ? '+' : '-'} $quantityFormatted ${widget.product.unit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Motivo e referência
            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              _buildInfoItem(
                'Motivo',
                transaction.notes!,
                Icons.description,
              ),
            if (transaction.applicationId != null && transaction.applicationId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildInfoItem(
                  'Aplicação',
                  'ID: ${transaction.applicationId}',
                  Icons.agriculture,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textLight,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
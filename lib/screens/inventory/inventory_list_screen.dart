
import 'package:flutter/material.dart';
import 'package:fortsmart_agro/utils/wrappers/wrappers.dart';
import 'package:fortsmart_agro/database/models/inventory.dart';
import 'package:fortsmart_agro/repositories/inventory_repository.dart';
import 'package:fortsmart_agro/screens/inventory/inventory_detail_screen.dart';
import 'package:fortsmart_agro/screens/inventory/inventory_form_screen.dart';
import 'package:fortsmart_agro/screens/inventory/inventory_movement_screen.dart';
import 'package:fortsmart_agro/screens/inventory/inventory_import_result_screen.dart';
import 'package:fortsmart_agro/services/excel_import_service.dart';
import 'package:fortsmart_agro/services/auth_service.dart';
import 'package:fortsmart_agro/utils/snackbar_helper.dart';
import 'package:fortsmart_agro/utils/permission_helper.dart';
import 'package:fortsmart_agro/widgets/app_drawer.dart';
import 'package:fortsmart_agro/widgets/loading_overlay.dart';
import 'package:fortsmart_agro/widgets/empty_state.dart';
import 'package:fortsmart_agro/widgets/search_bar.dart';
import 'package:fortsmart_agro/widgets/filter_chip_group.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class InventoryListScreen extends StatefulWidget {
  static const routeName = '/inventory';

  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  _InventoryListScreenState createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final InventoryRepository _repository = InventoryRepository();
  final ExcelImportService _excelService = ExcelImportService();
  final AuthService _authService = AuthService();
  
  List<InventoryItem> _allItems = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = 'Todos';
  
  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }
  
  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await _repository.getAllItems();
      setState(() {
        _allItems = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao carregar estoque: ${e.toString()}'
      );
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        // Aplica filtro de pesquisa
        final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.type?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
            (item.formulation?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase());
        
        // Aplica filtro de tipo
        final matchesType = _selectedType == 'Todos' || item.type == _selectedType;
        
        return matchesSearch && matchesType;
      }).toList();
      
      // Ordena por nome
      _filteredItems.sort((a, b) => a.name.compareTo(b.name));
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }
  
  void _onTypeFilterChanged(String type) {
    setState(() {
      _selectedType = type;
      _applyFilters();
    });
  }
  
  Future<void> _importFromExcel() async {
    if (!await PermissionHelper.checkStoragePermission(context)) {
      return;
    }
    
    try {
      final file = await FilePickerWrapper.pickSingleFile();
      
      if (file == null) {
        return;
      }
      
      // Verificar a extensão do arquivo
      final path = file.path;
      if (!path.toLowerCase().endsWith('.xlsx') && 
          !path.toLowerCase().endsWith('.xls') && 
          !path.toLowerCase().endsWith('.csv')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O arquivo selecionado não é uma planilha válida (.xlsx, .xls, .csv)'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
        return;
      }
      
      final currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        SnackbarHelper.showErrorSnackbar(
          context, 
          'Erro: Usuário não autenticado'
        );
        return;
      }
      
      LoadingOverlay.show(context, 'Importando produtos...');
      
      final importResult = await _excelService.importInventoryFromExcel(
        file, 
        currentUser.name
      );
      
      LoadingOverlay.hide();
      
      // Navega para a tela de resultado da importação
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InventoryImportResultScreen(result: importResult),
        ),
      ).then((_) => _loadInventoryItems());
      
    } catch (e) {
      LoadingOverlay.hide();
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao importar arquivo: ${e.toString()}'
      );
    }
  }
  
  Future<void> _downloadTemplate() async {
    if (!await PermissionHelper.checkStoragePermission(context)) {
      return;
    }
    
    try {
      LoadingOverlay.show(context, 'Gerando modelo...');
      
      final templateFile = await _excelService.generateTemplateFile();
      
      LoadingOverlay.hide();
      
      // Compartilha o arquivo
      await Share.shareXFiles(
        [XFile(templateFile.path)],
        text: 'Modelo de importação de estoque FORTSMARTAGRO',
      );
      
    } catch (e) {
      LoadingOverlay.hide();
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao gerar modelo: ${e.toString()}'
      );
    }
  }
  
  Future<void> _addNewItem() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InventoryFormScreen(),
      ),
    );
    
    if (result == true) {
      _loadInventoryItems();
    }
  }
  
  Future<void> _viewItemDetails(InventoryItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InventoryDetailScreen(item: item),
      ),
    );
    
    if (result == true) {
      _loadInventoryItems();
    }
  }
  
  Future<void> _viewMovements() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InventoryMovementScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Extrai tipos únicos para o filtro
    final types = ['Todos']..addAll(
      _allItems.map((item) => item.type ?? 'Sem tipo')
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList()..sort()
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Estoque de Defensivos'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Histórico de Movimentações',
            onPressed: _viewMovements,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import') {
                _importFromExcel();
              } else if (value == 'template') {
                _downloadTemplate();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Importar Planilha'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'template',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Baixar Modelo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(
                    onChanged: _onSearchChanged,
                    hintText: 'Buscar produtos...',
                  ),
                ),
                if (types.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilterChipGroup(
                      items: types,
                      selectedItem: _selectedType,
                      onSelected: _onTypeFilterChanged,
                    ),
                  ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory,
                          message: _searchQuery.isNotEmpty || _selectedType != 'Todos'
                              ? 'Nenhum produto encontrado com os filtros atuais'
                              : 'Nenhum produto cadastrado',
                          actionText: 'Adicionar Produto',
                          onAction: _addNewItem,
                        )
                      : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildInventoryItemCard(item);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        child: Icon(Icons.add),
        tooltip: 'Adicionar Produto',
      ),
    );
  }
  
  Widget _buildInventoryItemCard(InventoryItem item) {
    // Define cores de alerta
    Color statusColor = Colors.green;
    String statusText = '';
    
    if (item.isExpired()) {
      statusColor = Colors.red;
      statusText = 'VENCIDO';
    } else if (item.isNearExpiration()) {
      statusColor = Colors.orange;
      statusText = 'PRÓXIMO DO VENCIMENTO';
    } else if (item.isBelowMinimumLevel()) {
      statusColor = Colors.red;
      statusText = 'ESTOQUE BAIXO';
    }
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        // onTap: () => _viewItemDetails(item), // onTap não é suportado em Polygon no flutter_map 5.0.0
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.getFullName(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type ?? 'Sem tipo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantidade: ${item.getFormattedQuantity()}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Local: ${item.location}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              if (item.expirationDate != null) ...[
                SizedBox(height: 4),
                Text(
                  'Validade: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item.expirationDate!))}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
              if (statusText.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product_model.dart';
import '../models/product_class_model.dart';
import '../services/inventory_service.dart';
import '../widgets/inventory_product_card.dart';
import '../widgets/inventory_filter_bar.dart';
import '../widgets/inventory_add_product_modal.dart';
import '../widgets/inventory_product_details_modal.dart';
import '../widgets/inventory_stock_movement_modal.dart';
import '../widgets/inventory_product_history_modal.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/utils/app_colors.dart';
import '../../../widgets/app_drawer.dart';

class InventoryProductsScreen extends StatefulWidget {
  const InventoryProductsScreen({Key? key}) : super(key: key);

  @override
  _InventoryProductsScreenState createState() => _InventoryProductsScreenState();
}

class _InventoryProductsScreenState extends State<InventoryProductsScreen> {
  final InventoryService _inventoryService = InventoryService();
  
  // Estado da tela
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<InventoryProductModel> _products = [];
  int _totalProducts = 0;
  
  // Filtros
  String _searchQuery = '';
  int? _typeFilter;
  ProductClass? _classFilter;
  bool _lowStockFilter = false;
  bool _criticalStockFilter = false;
  bool _expiringFilter = false;
  bool _expiredFilter = false;
  String _orderBy = 'name';
  bool _descending = false;
  
  // Paginação
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;
  
  // Formatador de moeda
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  
  // ScrollController para detectar quando chegou ao final da lista
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Listener para detectar quando chegou ao final da lista
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreItems) {
        _loadMoreProducts();
      }
    }
  }
  
  // Carregar produtos iniciais
  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }
    
    try {
      // Obter produtos
      final products = await _inventoryService.getAllProducts();
      final totalCount = products.length;
      
      if (mounted) {
        setState(() {
          _products = products;
          _totalProducts = totalCount;
          _currentPage = 0;
          _hasMoreItems = products.length < totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Erro ao carregar produtos: $e';
        });
      }
    }
  }
  
  // Carregar mais produtos (paginação)
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreItems) return;
    
    if (mounted) {
      setState(() {
        _isLoadingMore = true;
      });
    }
    
    try {
      final nextPage = _currentPage + 1;
      final offset = nextPage * _itemsPerPage;
      
      // Obter próxima página de produtos
      final moreProducts = await _inventoryService.getAllProducts();
      
      if (mounted) {
        setState(() {
          _products.addAll(moreProducts);
          _currentPage = nextPage;
          _hasMoreItems = _products.length < _totalProducts;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  // Aplicar filtros
  void _applyFilters({
    String? searchQuery,
    int? typeFilter,
    ProductClass? classFilter,
    bool? lowStockFilter,
    bool? criticalStockFilter,
    bool? expiringFilter,
    bool? expiredFilter,
    String? orderBy,
    bool? descending,
  }) {
    if (mounted) {
      setState(() {
        if (searchQuery != null) _searchQuery = searchQuery;
        if (typeFilter != null) _typeFilter = typeFilter;
        if (classFilter != null) _classFilter = classFilter;
        if (lowStockFilter != null) _lowStockFilter = lowStockFilter;
        if (criticalStockFilter != null) _criticalStockFilter = criticalStockFilter;
        if (expiringFilter != null) _expiringFilter = expiringFilter;
        if (expiredFilter != null) _expiredFilter = expiredFilter;
        if (orderBy != null) _orderBy = orderBy;
        if (descending != null) _descending = descending;
      });
    }
    
    _loadProducts();
  }
  
  // Limpar todos os filtros
  void _clearFilters() {
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _typeFilter = null;
        _classFilter = null;
        _lowStockFilter = false;
        _criticalStockFilter = false;
        _expiringFilter = false;
        _expiredFilter = false;
        _orderBy = 'name';
        _descending = false;
      });
    }
    
    _loadProducts();
  }
  
  // Mostrar modal de adição de produto
  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryAddProductModal(
        onSave: (product) async {
          try {
            // Salvar o produto no banco de dados
            final result = await _inventoryService.addProduct(product);
            if (result != null) {
              // Produto salvo com sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Produto "${product.name}" adicionado com sucesso!'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
              // Recarregar a lista de produtos
              _loadProducts();
            } else {
              // Erro ao salvar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao adicionar produto. Tente novamente.'),
                  backgroundColor: AppColors.danger,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            // Erro durante o salvamento
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao adicionar produto: $e'),
                backgroundColor: AppColors.danger,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        onProductAdded: (product) {
          _loadProducts();
        },
      ),
    );
  }
  
  // Mostrar modal de detalhes do produto
  void _showProductDetailsModal(InventoryProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryProductDetailsModal(
        product: product,
        onProductUpdated: (transaction) {
          _loadProducts();
        },
      ),
    );
  }
  
  // Mostrar modal de movimentação de estoque
  void _showStockMovementModal(InventoryProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryStockMovementModal(
        product: product,
        onSave: (transaction) {
          _loadProducts();
        },
        onStockUpdated: (transaction) {
          _loadProducts();
        },
      ),
    );
  }
  
  // Mostrar modal de histórico do produto
  void _showProductHistoryModal(InventoryProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryProductHistoryModal(
        product: product,
      ),
    );
  }
  
  // Gerar relatório de estoque atual
  void _generateCurrentStockReport() {
    // TODO: Implementar geração de relatório PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gerando relatório de estoque atual...'),
        backgroundColor: AppColors.success
      ),
    );
  }
  
  // Gerar relatório de gasto por aplicação
  void _generateApplicationExpenseReport() {
    // TODO: Implementar geração de relatório PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gerando relatório de gasto por aplicação...'),
        backgroundColor: AppColors.success
      ),
    );
  }
  
  // Exportar para Excel
  void _exportToExcel() {
    // TODO: Implementar exportação para Excel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportando dados para Excel...'),
        backgroundColor: AppColors.success
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estoque de Produtos'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Atualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'current_stock_report':
                  _generateCurrentStockReport();
                  break;
                case 'application_expense_report':
                  _generateApplicationExpenseReport();
                  break;
                case 'export_excel':
                  _exportToExcel();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'current_stock_report',
                child: Row(
                  children: [
                    Icon(Icons.description, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Relatório de Estoque Atual'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'application_expense_report',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Relatório de Gasto por Aplicação'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Exportar para Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          // Barra de filtros
          InventoryFilterBar(
            searchQuery: _searchQuery,
            typeFilter: _typeFilter,
            lowStockFilter: _lowStockFilter,
            criticalStockFilter: _criticalStockFilter,
            expiringFilter: _expiringFilter,
            expiredFilter: _expiredFilter,
            orderBy: _orderBy,
            descending: _descending,
            onApplyFilters: _applyFilters,
            onClearFilters: _clearFilters,
          ),
          
          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: $_totalProducts produtos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (_hasMoreItems && _products.isNotEmpty)
                  Text(
                    'Mostrando ${_products.length} de $_totalProducts',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de produtos
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductModal,
        // backgroundColor: AppColors.success, // backgroundColor não é suportado em flutter_map 5.0.0
        child: Icon(Icons.add),
        tooltip: 'Adicionar Produto',
      ),
    );
  }
  
  Widget _buildProductsList() {
    if (_isLoading && _products.isEmpty) {
      return LoadingIndicator(message: 'Carregando produtos...');
    }
    
    if (_hasError) {
      return ErrorState(
        message: _errorMessage,
        onRetry: _loadProducts,
      );
    }
    
    if (_products.isEmpty) {
      return EmptyState(
        icon: Icons.inventory,
        message: 'Nenhum produto encontrado',
        subMessage: 'Adicione produtos ao estoque ou ajuste os filtros',
        buttonText: 'Adicionar Produto',
        onButtonPressed: _showAddProductModal,
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(8),
        itemCount: _products.length + (_hasMoreItems ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final product = _products[index];
          
          return InventoryProductCard(
            product: product,
            onTap: () => _showProductDetailsModal(product),
            onEdit: () => _showProductDetailsModal(product),
            onHistory: () => _showProductHistoryModal(product),
            onStockMovement: () => _showStockMovementModal(product),
          );
        },
      ),
    );
  }
}

/// 🌱 Tela de Lista de Testes de Germinação
/// 
/// Lista elegante dos testes de germinação com filtros e busca
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';
import 'widgets/germination_test_card.dart';
import 'widgets/germination_filter_widget.dart';
import 'widgets/germination_search_widget.dart';
import 'germination_test_create_screen.dart';

class GerminationTestListScreen extends StatefulWidget {
  const GerminationTestListScreen({super.key});

  @override
  State<GerminationTestListScreen> createState() => _GerminationTestListScreenState();
}

class _GerminationTestListScreenState extends State<GerminationTestListScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _searchText = '';
  String _selectedStatus = 'all';
  String _selectedCulture = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadData() async {
    final provider = context.read<GerminationTestProvider>();
    await provider.loadTests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildSearchAndFilters(),
              Expanded(
                child: _buildTestsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBarWidget(
      title: 'Testes de Germinação',
      showBackButton: true,
      backgroundColor: FortSmartTheme.primaryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilters(),
          tooltip: 'Filtros',
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => _showSortOptions(),
          tooltip: 'Ordenar',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GerminationSearchWidget(
            searchText: _searchText,
            onSearchChanged: (text) {
              setState(() => _searchText = text);
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'Todos',
                  _selectedStatus == 'all',
                  () => _setStatusFilter('all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Ativos',
                  _selectedStatus == 'active',
                  () => _setStatusFilter('active'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Completos',
                  _selectedStatus == 'completed',
                  () => _setStatusFilter('completed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? FortSmartTheme.primaryColor 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTestsList() {
    return Consumer<GerminationTestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        final filteredTests = _getFilteredTests(provider.tests);

        if (filteredTests.isEmpty) {
          return _buildEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTests.length,
            itemBuilder: (context, index) {
              final test = filteredTests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GerminationTestCard(
                  test: test,
                  onTap: () => _navigateToTestDetail(test),
                  onEdit: () => _editTest(test),
                  onDelete: () => _deleteTest(test),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar testes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum teste encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro teste de germinação',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateTest(),
            icon: const Icon(Icons.add),
            label: const Text('Criar Teste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCreateTest(),
      backgroundColor: FortSmartTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Novo Teste'),
      elevation: 8,
    );
  }

  List<GerminationTest> _getFilteredTests(List<GerminationTest> tests) {
    return tests.where((test) {
      // Filtro por status
      if (_selectedStatus != 'all' && test.status != _selectedStatus) {
        return false;
      }

      // Filtro por cultura
      if (_selectedCulture != 'all' && test.culture != _selectedCulture) {
        return false;
      }

      // Filtro por texto de busca
      if (_searchText.isNotEmpty) {
        final searchLower = _searchText.toLowerCase();
        if (!test.culture.toLowerCase().contains(searchLower) &&
            !test.variety.toLowerCase().contains(searchLower) &&
            !test.seedLot.toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      // Filtro por data
      if (_startDate != null && test.startDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && test.startDate.isAfter(_endDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  void _setStatusFilter(String status) {
    setState(() => _selectedStatus = status);
    _applyFilters();
  }

  void _applyFilters() {
    final provider = context.read<GerminationTestProvider>();
    provider.searchTests(
      culture: _selectedCulture != 'all' ? _selectedCulture : null,
      status: _selectedStatus != 'all' ? _selectedStatus : null,
      startDate: _startDate,
      endDate: _endDate,
      searchText: _searchText.isNotEmpty ? _searchText : null,
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GerminationFilterWidget(
        selectedCulture: _selectedCulture,
        startDate: _startDate,
        endDate: _endDate,
        onCultureChanged: (culture) => setState(() => _selectedCulture = culture),
        onStartDateChanged: (date) => setState(() => _startDate = date),
        onEndDateChanged: (date) => setState(() => _endDate = date),
        onApply: () {
          Navigator.pop(context);
          _applyFilters();
        },
        onClear: () {
          setState(() {
            _selectedCulture = 'all';
            _startDate = null;
            _endDate = null;
          });
          Navigator.pop(context);
          _applyFilters();
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data de Criação'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar ordenação
              },
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Cultura'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar ordenação
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Taxa de Germinação'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar ordenação
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTestDetail(GerminationTest test) {
    // TODO: Implementar navegação para detalhes do teste
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo detalhes do teste: ${test.culture}'),
        backgroundColor: FortSmartTheme.primaryColor,
      ),
    );
  }

  void _editTest(GerminationTest test) {
    // TODO: Implementar edição do teste
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando teste: ${test.culture}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteTest(GerminationTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Teste'),
        content: Text('Tem certeza que deseja excluir o teste de ${test.culture}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<GerminationTestProvider>();
              final success = await provider.deleteTest(test.id!);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teste excluído com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GerminationTestCreateScreen(),
      ),
    );
  }
}

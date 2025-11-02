import 'package:flutter/material.dart';
import '../services/cost_management_service.dart';
import '../models/cost_management_model.dart';
import '../../../utils/logger.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/loading_widget.dart';

class ApplicationsListScreen extends StatefulWidget {
  const ApplicationsListScreen({Key? key}) : super(key: key);

  @override
  State<ApplicationsListScreen> createState() => _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen>
    with TickerProviderStateMixin {
  final CostManagementService _costService = CostManagementService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  List<CostManagementModel> _aplicacoes = [];
  String _filtroStatus = 'Todas';
  String _termoBusca = '';

  final List<String> _filtrosStatus = ['Todas', 'Este Mês', 'Último Mês', 'Este Ano'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarAplicacoes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    _animationController.forward();
  }

  Future<void> _carregarAplicacoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('📋 Carregando aplicações...');
      final aplicacoes = await _costService.getAllAplicacoes();
      
      setState(() {
        _aplicacoes = aplicacoes;
        _isLoading = false;
      });
      
      Logger.info('✅ ${aplicacoes.length} aplicações carregadas');
    } catch (e) {
      Logger.error('❌ Erro ao carregar aplicações: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar aplicações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CostManagementModel> get _aplicacoesFiltradas {
    List<CostManagementModel> aplicacoes = List.from(_aplicacoes);

    // Aplicar filtro de status
    if (_filtroStatus != 'Todas') {
      final agora = DateTime.now();
      aplicacoes = aplicacoes.where((aplicacao) {
        switch (_filtroStatus) {
          case 'Este Mês':
            return aplicacao.dataAplicacao.year == agora.year &&
                   aplicacao.dataAplicacao.month == agora.month;
          case 'Último Mês':
            final ultimoMes = DateTime(agora.year, agora.month - 1);
            return aplicacao.dataAplicacao.year == ultimoMes.year &&
                   aplicacao.dataAplicacao.month == ultimoMes.month;
          case 'Este Ano':
            return aplicacao.dataAplicacao.year == agora.year;
          default:
            return true;
        }
      }).toList();
    }

    // Aplicar busca
    if (_termoBusca.isNotEmpty) {
      aplicacoes = aplicacoes.where((aplicacao) {
        return aplicacao.talhaoNome.toLowerCase().contains(_termoBusca.toLowerCase()) ||
               aplicacao.operador.toLowerCase().contains(_termoBusca.toLowerCase()) ||
               aplicacao.equipamento.toLowerCase().contains(_termoBusca.toLowerCase());
      }).toList();
    }

    // Ordenar por data mais recente
    aplicacoes.sort((a, b) => b.dataAplicacao.compareTo(a.dataAplicacao));

    return aplicacoes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
              appBar: const CustomAppBar(
          title: 'Aplicações',
        ),
      body: _isLoading
          ? const LoadingWidget()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildSearchAndFilters(),
                  Expanded(
                    child: _buildApplicationsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Campo de busca
          TextField(
            onChanged: (value) {
              setState(() {
                _termoBusca = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar aplicações...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filtros de status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filtrosStatus.map((filtro) {
                final isSelected = _filtroStatus == filtro;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filtro),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filtroStatus = filtro;
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    final aplicacoesFiltradas = _aplicacoesFiltradas;

    if (aplicacoesFiltradas.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _carregarAplicacoes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: aplicacoesFiltradas.length,
        itemBuilder: (context, index) {
          final aplicacao = aplicacoesFiltradas[index];
          return _buildApplicationCard(aplicacao);
        },
      ),
    );
  }

  Widget _buildApplicationCard(CostManagementModel aplicacao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _abrirDetalhesAplicacao(aplicacao),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com talhão e data
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                                             child: Icon(
                         Icons.agriculture,
                         color: AppColors.primary,
                         size: 20,
                       ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aplicacao.talhaoNome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(aplicacao.dataAplicacao),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'R\$ ${aplicacao.custoTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Informações da aplicação
                _buildInfoRow('Área', '${aplicacao.areaHa.toStringAsFixed(2)} ha'),
                _buildInfoRow('Custo/ha', 'R\$ ${aplicacao.custoPorHectare.toStringAsFixed(2)}'),
                _buildInfoRow('Operador', aplicacao.operador),
                _buildInfoRow('Equipamento', aplicacao.equipamento),
                if (aplicacao.produtos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Produtos (${aplicacao.produtos.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...aplicacao.produtos.take(2).map((produto) => 
                    _buildProductItem(produto)
                  ),
                  if (aplicacao.produtos.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${aplicacao.produtos.length - 2} produtos',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
                if (aplicacao.observacoes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Observações',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aplicacao.observacoes,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(CostProductModel produto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${produto.nome} - ${produto.dosePorHa} ${produto.unidade}/ha',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          Text(
            'R\$ ${produto.custoTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma aplicação encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece registrando sua primeira aplicação',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nova Aplicação'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _abrirDetalhesAplicacao(CostManagementModel aplicacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildApplicationDetails(aplicacao),
    );
  }

  Widget _buildApplicationDetails(CostManagementModel aplicacao) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                                     child: Icon(
                     Icons.agriculture,
                     color: AppColors.primary,
                     size: 24,
                   ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aplicacao.talhaoNome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _formatDate(aplicacao.dataAplicacao),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Informações Gerais', [
                    _buildDetailItem('Área Aplicada', '${aplicacao.areaHa.toStringAsFixed(2)} ha'),
                    _buildDetailItem('Custo Total', 'R\$ ${aplicacao.custoTotal.toStringAsFixed(2)}'),
                    _buildDetailItem('Custo por Hectare', 'R\$ ${aplicacao.custoPorHectare.toStringAsFixed(2)}'),
                    _buildDetailItem('Operador', aplicacao.operador),
                    _buildDetailItem('Equipamento', aplicacao.equipamento),
                  ]),
                  const SizedBox(height: 24),
                  _buildDetailSection('Produtos Utilizados', aplicacao.produtos.map((produto) => 
                    _buildDetailItem(
                      produto.nome,
                      '${produto.dosePorHa} ${produto.unidade}/ha - R\$ ${produto.custoTotal.toStringAsFixed(2)}',
                    )
                  ).toList()),
                  if (aplicacao.observacoes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDetailSection('Observações', [
                      _buildDetailItem('', aplicacao.observacoes),
                    ]),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

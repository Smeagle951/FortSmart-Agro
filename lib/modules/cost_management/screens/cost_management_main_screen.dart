import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '../services/cost_management_service.dart';
import '../../../models/talhao_model.dart';
import '../../../models/produto_estoque.dart';
import '../../../utils/logger.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/loading_widget.dart';
import 'new_application_screen.dart';
import 'cost_report_screen.dart';
import 'applications_list_screen.dart';
import '../../../routes.dart';

class CostManagementMainScreen extends StatefulWidget {
  const CostManagementMainScreen({Key? key}) : super(key: key);

  @override
  State<CostManagementMainScreen> createState() => _CostManagementMainScreenState();
}

class _CostManagementMainScreenState extends State<CostManagementMainScreen>
    with TickerProviderStateMixin {
  final CostManagementService _costService = CostManagementService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = true;
  Map<String, dynamic> _resumoCustos = {};
  List<Map<String, dynamic>> _aplicacoesRecentes = [];
  List<Map<String, dynamic>> _produtosMaisUtilizados = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarDados();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataInicio = DateTime.now().subtract(const Duration(days: 30));
      final dataFim = DateTime.now();

      // Carregar dados em paralelo
      final futures = await Future.wait([
        _costService.calcularCustosPorPeriodo(
          dataInicio: dataInicio,
          dataFim: dataFim,
        ),
        _costService.obterAplicacoesDetalhadas(
          dataInicio: dataInicio,
          dataFim: dataFim,
        ),
        _costService.obterProdutosMaisUtilizados(
          dataInicio: dataInicio,
          dataFim: dataFim,
        ),
      ]);

      setState(() {
        _resumoCustos = futures[0] as Map<String, dynamic>;
        _aplicacoesRecentes = futures[1] as List<Map<String, dynamic>>;
        _produtosMaisUtilizados = futures[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
              appBar: const CustomAppBar(
          title: 'Gestão de Custos',
        ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildMetricsCards(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentApplications(),
          const SizedBox(height: 24),
          _buildTopProducts(),
          const SizedBox(height: 100), // Espaço para FAB
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestão de Custos',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Controle total dos custos de aplicação',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    final custoTotal = _resumoCustos['custoTotal'] ?? 0.0;
    final totalAplicacoes = _resumoCustos['totalAplicacoes'] ?? 0;
    final produtosEmEstoque = _produtosMaisUtilizados.length;
    final valorEmEstoque = _calcularValorEmEstoque();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo (30 dias)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              'Custo Total',
              'R\$ ${custoTotal.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildMetricCard(
              'Aplicações',
              totalAplicacoes.toString(),
                               Icons.agriculture,
              Colors.blue,
            ),
            _buildMetricCard(
              'Produtos em Estoque',
              produtosEmEstoque.toString(),
              Icons.inventory,
              Colors.orange,
            ),
            _buildMetricCard(
              'Valor em Estoque',
              'R\$ ${valorEmEstoque.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Relatório',
                Icons.bar_chart,
                Colors.green,
                () => _navegarParaRelatorio(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentApplications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aplicações Recentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navegarParaListaAplicacoes(),
              child: const Text('Ver Todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_aplicacoesRecentes.isEmpty)
          _buildEmptyState(
            'Nenhuma aplicação registrada',
            'Comece registrando sua primeira aplicação',
            Icons.add_circle_outline,
          )
        else
          ...(_aplicacoesRecentes.take(3).map((aplicacao) => _buildApplicationCard(aplicacao))),
      ],
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> aplicacao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
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
                  aplicacao['talhaoNome'] ?? 'Talhão',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${aplicacao['areaHa']?.toStringAsFixed(2)} ha • R\$ ${aplicacao['custoTotal']?.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(aplicacao['dataAplicacao']),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produtos Mais Utilizados',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_produtosMaisUtilizados.isEmpty)
          _buildEmptyState(
            'Nenhum produto utilizado',
            'Os produtos aparecerão aqui após aplicações',
            Icons.inventory_2_outlined,
          )
        else
          ...(_produtosMaisUtilizados.take(3).map((produto) => _buildProductCard(produto))),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> produto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto['produtoNome'] ?? 'Produto',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${produto['quantidadeTotal']?.toStringAsFixed(2)} ${produto['unidade']} • ${produto['aplicacoes']} aplicações',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${produto['custoTotal']?.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: () => _navegarParaNovaAplicacao(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Aplicação'),
        elevation: 8,
      ),
    );
  }

  double _calcularValorEmEstoque() {
    // Simulação do valor em estoque
    return _produtosMaisUtilizados.fold<double>(
      0.0,
      (total, produto) => total + (produto['custoTotal'] ?? 0.0),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _navegarParaNovaAplicacao() {
    Navigator.pushNamed(context, AppRoutes.novaPrescricao).then((_) => _carregarDados());
  }


  void _navegarParaRelatorio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CostReportScreen(),
      ),
    );
  }

  void _navegarParaListaAplicacoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApplicationsListScreen(),
      ),
    ).then((_) => _carregarDados());
  }
}

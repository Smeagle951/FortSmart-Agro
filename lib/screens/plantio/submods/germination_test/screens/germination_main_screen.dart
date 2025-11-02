/// 🌱 Tela Principal do Módulo de Teste de Germinação
/// 
/// Design elegante seguindo padrão FortSmart com funcionalidades completas
/// para testes de germinação seguindo metodologias agronômicas (ABNT NBR 9787)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../utils/theme_utils.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import 'germination_test_list_screen.dart';
import 'germination_test_create_screen.dart';
import 'germination_test_settings_screen.dart';
import 'germination_reports_list_screen.dart';
import '../widgets/germination_stats_widget.dart';
// import 'agronomic_reports_screen.dart'; // Comentado temporariamente devido a conflito
import '../widgets/germination_recent_tests_widget.dart';

class GerminationMainScreen extends StatefulWidget {
  const GerminationMainScreen({super.key});

  @override
  State<GerminationMainScreen> createState() => _GerminationMainScreenState();
}

class _GerminationMainScreenState extends State<GerminationMainScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Aguardar o build completar antes de carregar dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

  Future<void> _loadData() async {
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      
      // Garantir que o provider está inicializado
      await provider.ensureInitialized();
      
      // Carregar testes diretamente - o provider já está inicializado
      await provider.loadTests();
      print('✅ Dados carregados com sucesso');
      
      // Forçar rebuild do widget para atualizar a UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      // Não mostrar erro para o usuário na tela inicial
      // Apenas logar o erro para debug
    }
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
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const GerminationStatsWidget(),
                  const SizedBox(height: 24),
                  // Lista de Testes e Subtestes
                  const GerminationRecentTestsWidget(),
                  const SizedBox(height: 24),
                  // Relatórios com filtros
                  _buildReportsSection(),
                  const SizedBox(height: 100), // Espaço para FAB
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBarWidget(
      title: 'Teste de Germinação',
      showBackButton: true,
      backgroundColor: FortSmartTheme.primaryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.cleaning_services),
          onPressed: () => _showClearTestsDialog(),
          tooltip: 'Limpar Testes',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _navigateToSettings(),
          tooltip: 'Configurações',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FortSmartTheme.primaryColor,
            FortSmartTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FortSmartTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Módulo de Germinação',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Testes agronômicos seguindo ABNT NBR 9787',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderStat('Testes Ativos', '0', Icons.play_circle),
              const SizedBox(width: 16),
              _buildHeaderStat('Completos', '0', Icons.check_circle),
              const SizedBox(width: 16),
              _buildHeaderStat('Taxa Média', '0%', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Relatórios de Germinação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Gere relatórios completos com filtros personalizados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            _buildReportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToReports(),
        icon: const Icon(Icons.assessment),
        label: const Text('Gerar Relatório com Filtros'),
        style: ElevatedButton.styleFrom(
          backgroundColor: FortSmartTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildFeatureGrid_OLD() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildFeatureCard(
          'Relatórios',
          Icons.description,
          Colors.blue,
          () => _navigateToReports(),
        ),
        _buildFeatureCard(
          'Exportar',
          Icons.download,
          Colors.orange,
          () => _navigateToExport(),
        ),
        _buildFeatureCard(
          'Configurações',
          Icons.settings,
          Colors.purple,
          () => _navigateToSettings(),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  void _navigateToCreateTest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GerminationTestCreateScreen(),
      ),
    );
    
    // Recarregar dados se um teste foi criado
    if (result == true) {
      await _loadData();
    }
  }

  void _navigateToTestList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GerminationTestListScreen(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GerminationTestSettingsScreen(),
      ),
    );
  }


  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GerminationReportsListScreen(),
      ),
    );
  }

  /// Mostra diálogo de confirmação para limpar todos os testes
  void _showClearTestsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Limpar Todos os Testes'),
            ],
          ),
          content: const Text(
            'Esta ação irá remover TODOS os testes de germinação e seus dados. '
            'Esta ação não pode ser desfeita.\n\n'
            'Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllTests();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpar Tudo'),
            ),
          ],
        );
      },
    );
  }

  /// Executa a limpeza de todos os testes
  Future<void> _clearAllTests() async {
    final provider = Provider.of<GerminationTestProvider>(context, listen: false);
    
    try {
      final success = await provider.clearAllTests();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Todos os testes foram limpos com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Recarregar dados
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${provider.error ?? "Falha ao limpar testes"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToExport() {
    // TODO: Implementar funcionalidade de exportação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

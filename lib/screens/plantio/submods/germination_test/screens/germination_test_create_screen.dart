/// 🌱 Tela de Criação de Teste de Germinação
/// 
/// Design elegante para criação de testes individuais e com subtestes
/// seguindo metodologias agronômicas (ABNT NBR 9787)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import 'widgets/germination_test_type_selector.dart';
import 'widgets/germination_basic_info_form.dart';
import 'widgets/germination_subtest_config_widget.dart';

class GerminationTestCreateScreen extends StatefulWidget {
  const GerminationTestCreateScreen({super.key});

  @override
  State<GerminationTestCreateScreen> createState() => _GerminationTestCreateScreenState();
}

class _GerminationTestCreateScreenState extends State<GerminationTestCreateScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form data
  String _testType = 'individual'; // 'individual' or 'subtests'
  final _formKey = GlobalKey<FormState>();
  
  // Basic info
  String _culture = '';
  String _variety = '';
  String _seedLot = '';
  int _totalSeeds = 100;
  DateTime _startDate = DateTime.now();
  DateTime? _expectedEndDate;
  int _pureSeeds = 0;
  int _brokenSeeds = 0;
  int _stainedSeeds = 0;
  String _observations = '';
  
  // Subtest config
  List<String> _selectedPositions = [];
  int _subtestSeedCount = 0; // Campo livre para entrada do usuário
  

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  GerminationTestTypeSelector(
                    selectedType: _testType,
                    onTypeChanged: (type) => setState(() => _testType = type),
                  ),
                  const SizedBox(height: 24),
                  GerminationBasicInfoForm(
                    culture: _culture,
                    variety: _variety,
                    seedLot: _seedLot,
                    totalSeeds: _totalSeeds,
                    startDate: _startDate,
                    expectedEndDate: _expectedEndDate,
                    pureSeeds: _pureSeeds,
                    brokenSeeds: _brokenSeeds,
                    stainedSeeds: _stainedSeeds,
                    observations: _observations,
                    onCultureChanged: (value) => setState(() => _culture = value),
                    onVarietyChanged: (value) => setState(() => _variety = value),
                    onSeedLotChanged: (value) => setState(() => _seedLot = value),
                    onTotalSeedsChanged: (value) => setState(() => _totalSeeds = value),
                    onStartDateChanged: (value) => setState(() => _startDate = value),
                    onExpectedEndDateChanged: (value) => setState(() => _expectedEndDate = value),
                    onPureSeedsChanged: (value) => setState(() => _pureSeeds = value),
                    onBrokenSeedsChanged: (value) => setState(() => _brokenSeeds = value),
                    onStainedSeedsChanged: (value) => setState(() => _stainedSeeds = value),
                    onObservationsChanged: (value) => setState(() => _observations = value),
                  ),
                  if (_testType == 'subtests') ...[
                    const SizedBox(height: 24),
                    GerminationSubtestConfigWidget(
                      subtestNames: _selectedPositions ?? [],
                      onSubtestNamesChanged: (names) => setState(() => _selectedPositions = names),
                      subtestSeedCount: _subtestSeedCount,
                      onSubtestSeedCountChanged: (count) => setState(() => _subtestSeedCount = count),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 100), // Espaço para FAB
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBarWidget(
      title: 'Novo Teste de Germinação',
      showBackButton: true,
      backgroundColor: FortSmartTheme.primaryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.help),
          onPressed: () => _showHelp(),
          tooltip: 'Ajuda',
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
                      'Criar Teste de Germinação',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seguindo metodologias ABNT NBR 9787',
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
              _buildHeaderInfo('Tipo', _testType == 'individual' ? 'Individual' : 'Com Subtestes'),
              const SizedBox(width: 16),
              _buildHeaderInfo('Sementes', '$_totalSeeds'),
              const SizedBox(width: 16),
              _buildHeaderInfo('Data', _formatDate(_startDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _createTest,
            icon: const Icon(Icons.add),
            label: const Text('Criar Teste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação para subtestes
    if (_testType == 'subtests' && _subtestSeedCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite a quantidade de sementes por subteste'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      
      // Aguardar inicialização do provider
      await provider.ensureInitialized();
      
      if (!provider.isReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Provider não está pronto. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final test = await provider.createTest(
        culture: _culture,
        variety: _variety,
        seedLot: _seedLot,
        totalSeeds: _totalSeeds,
        startDate: _startDate,
        pureSeeds: _pureSeeds,
        brokenSeeds: _brokenSeeds,
        stainedSeeds: _stainedSeeds,
        useSubtests: _testType == 'subtests',
        subtestSeedCount: _subtestSeedCount,
        observations: _observations,
      );

      // Fechar indicador de carregamento
      if (mounted) {
        Navigator.pop(context);
      }

      if (test != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teste criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar teste'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fechar indicador de carregamento
      if (mounted) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar teste: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Criação de Teste'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Teste Individual:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 100 sementes em uma única posição'),
              Text('• Registro diário único'),
              Text('• Relatório básico'),
              SizedBox(height: 16),
              Text(
                'Teste com Subtestes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 3 subtestes (A, B, C) de 100 sementes cada'),
              Text('• Registros independentes por subteste'),
              Text('• Relatório consolidado com média'),
              SizedBox(height: 16),
              Text(
                'Metodologia ABNT NBR 9787:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Contagem diária de germinadas'),
              Text('• Cálculo de vigor e pureza'),
              Text('• Classificação automática'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

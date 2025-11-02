/// 🌱 Tela de Edição de Teste de Germinação
/// 
/// Permite editar informações básicas de um teste existente

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';
import 'widgets/germination_basic_info_form.dart';

class GerminationTestEditScreen extends StatefulWidget {
  final GerminationTest test;

  const GerminationTestEditScreen({
    super.key,
    required this.test,
  });

  @override
  State<GerminationTestEditScreen> createState() => _GerminationTestEditScreenState();
}

class _GerminationTestEditScreenState extends State<GerminationTestEditScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  
  // Form data - inicializar com dados do teste
  late String _culture;
  late String _variety;
  late String _seedLot;
  late int _totalSeeds;
  late DateTime _startDate;
  late DateTime? _expectedEndDate;
  late int _pureSeeds;
  late int _brokenSeeds;
  late int _stainedSeeds;
  late String _observations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFormData();
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

  void _initializeFormData() {
    _culture = widget.test.culture;
    _variety = widget.test.variety;
    _seedLot = widget.test.seedLot;
    _totalSeeds = widget.test.totalSeeds;
    _startDate = widget.test.startDate;
    _expectedEndDate = widget.test.expectedEndDate;
    _pureSeeds = widget.test.pureSeeds;
    _brokenSeeds = widget.test.brokenSeeds;
    _stainedSeeds = widget.test.stainedSeeds;
    _observations = widget.test.observations ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBarWidget(
        title: 'Editar Teste',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
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
                  _buildEditForm(),
                  const SizedBox(height: 24),
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

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [FortSmartTheme.primaryColor, FortSmartTheme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar Teste de Germinação',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modifique as informações do teste',
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
      ),
    );
  }

  Widget _buildEditForm() {
    return GerminationBasicInfoForm(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Alterações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
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

      // Criar objeto atualizado
      final updatedTest = widget.test.copyWith(
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
        updatedAt: DateTime.now(),
      );

      // Atualizar no banco
      final success = await provider.updateTest(
        testId: widget.test.id!,
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
      );

      // Fechar indicador de carregamento
      if (mounted) {
        Navigator.pop(context);
      }

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teste atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (mounted) {
          Navigator.pop(context, true); // Retorna true indicando que houve alteração
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar teste'),
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
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

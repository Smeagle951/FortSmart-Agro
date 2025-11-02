import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import 'monitoring_controller.dart';
import '../components/monitoring_map_widget.dart';
import '../components/monitoring_filters_widget.dart';
import '../components/monitoring_controls_widget.dart';
import '../components/monitoring_status_widget.dart';
import '../sections/monitoring_overview_section.dart';
import '../sections/monitoring_details_section.dart';
import '../sections/monitoring_actions_section.dart';
import '../widgets/database_error_widget.dart';

/// Tela principal de monitoramento - Versão modular e otimizada
class MonitoringMainScreen extends StatefulWidget {
  const MonitoringMainScreen({super.key});

  @override
  State<MonitoringMainScreen> createState() => _MonitoringMainScreenState();
}

class _MonitoringMainScreenState extends State<MonitoringMainScreen> {
  late final MonitoringController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      _controller = MonitoringController();
      await _controller.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        Logger.info('✅ Tela de monitoramento inicializada com sucesso');
      }
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tela de monitoramento: $e');
      if (mounted) {
        _showErrorDialog('Erro de Inicialização', 'Não foi possível carregar o módulo de monitoramento: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: DatabaseErrorWidget(
            error: message,
            onRetry: () {
              Navigator.of(context).pop();
              _initializeController();
            },
            onFixDatabase: () {
              Navigator.of(context).pop();
              _initializeController();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando módulo de monitoramento...'),
            SizedBox(height: 8),
            Text(
              'Isso pode levar alguns segundos na primeira vez',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Monitoramento'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _controller.refreshData,
          tooltip: 'Atualizar',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _controller.openSettings,
          tooltip: 'Configurações',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _controller.refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Widget de status
            MonitoringStatusWidget(controller: _controller),
            
            // Widget de filtros
            MonitoringFiltersWidget(controller: _controller),
            
            // Seção de visão geral
            MonitoringOverviewSection(controller: _controller),
            
            // Widget do mapa
            MonitoringMapWidget(controller: _controller),
            
            // Seção de detalhes
            MonitoringDetailsSection(controller: _controller),
            
            // Seção de ações
            MonitoringActionsSection(controller: _controller),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'new_monitoring',
          onPressed: _controller.startNewMonitoring,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'location',
          onPressed: _controller.goToCurrentLocation,
          backgroundColor: Colors.green,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'history',
          onPressed: _controller.openHistory,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.history, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'delete',
          onPressed: _controller.clearData,
          backgroundColor: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
      ],
    );
  }
}

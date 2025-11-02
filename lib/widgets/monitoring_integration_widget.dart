import 'package:flutter/material.dart';
import '../services/monitoring_save_enhanced_service.dart';
import '../models/monitoring.dart';
import '../utils/logger.dart';

/// Widget que demonstra a integração de monitoramento
/// Pode ser usado em qualquer tela de monitoramento para mostrar status da integração
class MonitoringIntegrationWidget extends StatefulWidget {
  final Monitoring? monitoring;
  final VoidCallback? onIntegrationComplete;
  final bool showDetails;

  const MonitoringIntegrationWidget({
    Key? key,
    this.monitoring,
    this.onIntegrationComplete,
    this.showDetails = false,
  }) : super(key: key);

  @override
  State<MonitoringIntegrationWidget> createState() => _MonitoringIntegrationWidgetState();
}

class _MonitoringIntegrationWidgetState extends State<MonitoringIntegrationWidget> {
  final MonitoringSaveEnhancedService _saveService = MonitoringSaveEnhancedService();
  
  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _lastResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  /// Inicializa o serviço
  Future<void> _initializeService() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _saveService.initialize();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar serviço: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Salva monitoramento com integração
  Future<void> _saveMonitoringWithIntegration() async {
    if (widget.monitoring == null) {
      _showErrorMessage('Nenhum monitoramento para salvar');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _saveService.saveMonitoringWithIntegration(widget.monitoring!);
      
      setState(() {
        _lastResult = result;
        _isLoading = false;
      });

      if (result['status'] == 'SUCCESS') {
        _showSuccessMessage('Monitoramento salvo com sucesso!');
        widget.onIntegrationComplete?.call();
      } else {
        _showErrorMessage(result['message'] ?? 'Erro ao salvar monitoramento');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar monitoramento: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showErrorMessage('Erro ao salvar monitoramento: $e');
    }
  }

  /// Obtém status do serviço
  Future<void> _getServiceStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final status = await _saveService.getStatus();
      
      setState(() {
        _lastResult = status;
        _isLoading = false;
      });
      
    } catch (e) {
      Logger.error('❌ Erro ao obter status: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isLoading) _buildLoadingIndicator(),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_lastResult != null) _buildResult(),
            if (widget.showDetails) _buildDetails(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Constrói cabeçalho
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _isInitialized ? Icons.check_circle : Icons.error,
          color: _isInitialized ? Colors.green : Colors.red,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'Integração de Monitoramento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_isInitialized)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ATIVO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  /// Constrói indicador de carregamento
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Constrói mensagem de erro
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Erro desconhecido',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói resultado
  Widget _buildResult() {
    final result = _lastResult!;
    final status = result['status'] as String;
    final isSuccess = status == 'SUCCESS';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.warning,
                color: isSuccess ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result['message'] ?? 'Operação concluída'),
          if (result['monitoring_id'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'ID: ${result['monitoring_id']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// Constrói detalhes
  Widget _buildDetails() {
    if (_lastResult == null) return const SizedBox.shrink();
    
    final result = _lastResult!;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalhes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...result.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value?.toString() ?? 'null',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// Constrói ações
  Widget _buildActions() {
    return Row(
      children: [
        if (widget.monitoring != null) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading || !_isInitialized ? null : _saveMonitoringWithIntegration,
              icon: const Icon(Icons.save),
              label: const Text('Salvar com Integração'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _getServiceStatus,
            icon: const Icon(Icons.info),
            label: const Text('Status'),
          ),
        ),
      ],
    );
  }

  /// Mostra mensagem de sucesso
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra mensagem de erro
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

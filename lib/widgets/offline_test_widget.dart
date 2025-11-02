import 'package:flutter/material.dart';
import '../services/safe_app_initializer.dart';
import '../services/offline_tile_provider.dart';
import '../services/simple_background_service.dart';
import '../utils/logger.dart';

/// Widget para testar funcionalidades offline
/// Permite verificar se tudo está funcionando corretamente
class OfflineTestWidget extends StatefulWidget {
  const OfflineTestWidget({super.key});

  @override
  State<OfflineTestWidget> createState() => _OfflineTestWidgetState();
}

class _OfflineTestWidgetState extends State<OfflineTestWidget> {
  final SafeAppInitializer _initializer = SafeAppInitializer();
  final OfflineTileProvider _tileProvider = OfflineTileProvider();
  final SimpleBackgroundService _backgroundService = SimpleBackgroundService();
  
  bool _isLoading = true;
  String _status = 'Inicializando...';
  Map<String, dynamic> _cacheStats = {};
  Map<String, bool> _serviceStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeAndTest();
  }

  Future<void> _initializeAndTest() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Inicializando serviços...';
      });

      // Inicializar app
      await _initializer.initializeApp();
      
      setState(() {
        _serviceStatus = _initializer.getServiceStatus();
        _status = _initializer.getStatusSummary();
      });

      // Obter estatísticas do cache
      _cacheStats = await _tileProvider.getCacheStats();
      
      setState(() {
        _isLoading = false;
      });

      Logger.info('✅ Teste offline concluído');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Erro: $e';
      });
      Logger.error('❌ Erro no teste offline: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Offline'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildServicesCard(),
                  const SizedBox(height: 16),
                  _buildCacheCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _status.contains('Erro') ? Icons.error : Icons.check_circle,
                  color: _status.contains('Erro') ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Status Geral',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_status),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status dos Serviços',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._serviceStatus.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.error,
                        color: entry.value ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                      const Spacer(),
                      Text(
                        entry.value ? 'OK' : 'FALHOU',
                        style: TextStyle(
                          color: entry.value ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas do Cache',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_cacheStats.isNotEmpty) ...[
              _buildCacheStat('Tiles em Cache', '${_cacheStats['tileCount'] ?? 0}'),
              _buildCacheStat('Tamanho do Cache', '${_cacheStats['cacheSizeMB'] ?? '0.00'} MB'),
              _buildCacheStat('Última Sincronização', _cacheStats['lastSync'] ?? 'Nunca'),
              _buildCacheStat('Cache Atualizado', _cacheStats['isUpToDate'] == true ? 'Sim' : 'Não'),
            ] else
              const Text('Nenhuma estatística disponível'),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações de Teste',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testBackgroundService,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Testar Background'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testCache,
                    icon: const Icon(Icons.cached),
                    label: const Text('Testar Cache'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _initializeAndTest,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recarregar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testBackgroundService() async {
    try {
      setState(() {
        _status = 'Testando serviço de background...';
      });

      if (_serviceStatus['BackgroundService'] == true) {
        await _backgroundService.startBackgroundProcessing();
        setState(() {
          _status = 'Background service iniciado com sucesso!';
        });
      } else {
        setState(() {
          _status = 'Background service não está disponível';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Erro no background service: $e';
      });
    }
  }

  Future<void> _testCache() async {
    try {
      setState(() {
        _status = 'Testando cache offline...';
      });

      // Testar se consegue cachear um tile
      final success = await _tileProvider.cacheTile(100, 100, 10);
      
      if (success) {
        setState(() {
          _status = 'Cache offline funcionando!';
          _cacheStats = {}; // Força recarregar estatísticas
        });
        await _initializeAndTest();
      } else {
        setState(() {
          _status = 'Falha no cache offline';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Erro no teste de cache: $e';
      });
    }
  }

  Future<void> _clearCache() async {
    try {
      setState(() {
        _status = 'Limpando cache...';
      });

      await _tileProvider.cleanupCache();
      
      setState(() {
        _status = 'Cache limpo com sucesso!';
        _cacheStats = {}; // Força recarregar estatísticas
      });
      
      await _initializeAndTest();
    } catch (e) {
      setState(() {
        _status = 'Erro ao limpar cache: $e';
      });
    }
  }
}

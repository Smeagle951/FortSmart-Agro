import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../index.dart';
import '../../../../models/talhao_model.dart';
import '../../../../providers/talhao_provider.dart';

/// Exemplo de integração do módulo de mapas offline com o sistema FortSmart
class OfflineMapsIntegrationExample extends StatefulWidget {
  const OfflineMapsIntegrationExample({super.key});

  @override
  State<OfflineMapsIntegrationExample> createState() => _OfflineMapsIntegrationExampleState();
}

class _OfflineMapsIntegrationExampleState extends State<OfflineMapsIntegrationExample> {
  final TalhaoIntegrationService _integrationService = TalhaoIntegrationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeIntegration();
  }

  Future<void> _initializeIntegration() async {
    try {
      await _integrationService.init();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Erro ao inicializar integração: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando integração de mapas offline...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Integração Mapas Offline'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Consumer<TalhaoProvider>(
        builder: (context, talhaoProvider, child) {
          return Column(
            children: [
              // Estatísticas de integração
              _buildIntegrationStats(),
              
              // Lista de talhões com status de mapas offline
              Expanded(
                child: _buildTalhoesList(talhaoProvider),
              ),
              
              // Botões de ação
              _buildActionButtons(talhaoProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntegrationStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _integrationService.getIntegrationStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estatísticas de Integração',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Mapas Offline',
                      stats['total_offline_maps']?.toString() ?? '0',
                      Colors.blue,
                      Icons.map,
                    ),
                    _buildStatItem(
                      'Baixados',
                      stats['downloaded_maps']?.toString() ?? '0',
                      Colors.green,
                      Icons.check_circle,
                    ),
                    _buildStatItem(
                      'Baixando',
                      stats['downloading_maps']?.toString() ?? '0',
                      Colors.orange,
                      Icons.download,
                    ),
                    _buildStatItem(
                      'Erros',
                      stats['error_maps']?.toString() ?? '0',
                      Colors.red,
                      Icons.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tamanho total: ${stats['storage_stats']?['formattedSize'] ?? '0 B'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTalhoesList(TalhaoProvider talhaoProvider) {
    final talhoes = talhaoProvider.talhoes;
    
    if (talhoes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum talhão encontrado'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: talhoes.length,
      itemBuilder: (context, index) {
        final talhao = talhoes[index];
        return _buildTalhaoCard(talhao);
      },
    );
  }

  Widget _buildTalhaoCard(TalhaoModel talhao) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.map, color: Colors.green[700]),
        ),
        title: Text(talhao.name),
        subtitle: Text('${talhao.area.toStringAsFixed(1)} ha'),
        trailing: FutureBuilder<bool>(
          future: _integrationService.hasOfflineMapsForTalhao(talhao.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            
            final hasOfflineMaps = snapshot.data ?? false;
            return Icon(
              hasOfflineMaps ? Icons.check_circle : Icons.cloud_off,
              color: hasOfflineMaps ? Colors.green : Colors.grey,
            );
          },
        ),
        onTap: () => _showTalhaoDetails(talhao),
      ),
    );
  }

  Widget _buildActionButtons(TalhaoProvider talhaoProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botão para processar todos os talhões
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processAllTalhoes(talhaoProvider),
              icon: const Icon(Icons.sync),
              label: const Text('Processar Todos os Talhões'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Botão para abrir gerenciador de mapas offline
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openOfflineMapsManager(),
              icon: const Icon(Icons.map),
              label: const Text('Gerenciar Mapas Offline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTalhaoDetails(TalhaoModel talhao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes - ${talhao.name}'),
        content: FutureBuilder<List<OfflineMapModel>>(
          future: _integrationService.getOfflineMapsForTalhao(talhao.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final offlineMaps = snapshot.data ?? [];
            
            if (offlineMaps.isEmpty) {
              return const Text('Nenhum mapa offline encontrado para este talhão.');
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: offlineMaps.map((map) => ListTile(
                leading: Icon(
                  map.status == OfflineMapStatus.downloaded 
                      ? Icons.check_circle 
                      : Icons.cloud_off,
                  color: map.status == OfflineMapStatus.downloaded 
                      ? Colors.green 
                      : Colors.grey,
                ),
                title: Text(map.talhaoName),
                subtitle: Text('Status: ${map.status.displayName}'),
                trailing: Text('${map.area.toStringAsFixed(1)} ha'),
              )).toList(),
            );
          },
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

  Future<void> _processAllTalhoes(TalhaoProvider talhaoProvider) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processando talhões...'),
            ],
          ),
        ),
      );

      await _integrationService.processExistingTalhoes(talhaoProvider.talhoes);
      
      if (mounted) {
        Navigator.pop(context); // Fechar dialog de loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Talhões processados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar dialog de loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar talhões: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openOfflineMapsManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OfflineMapsManagerScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _integrationService.dispose();
    super.dispose();
  }
}

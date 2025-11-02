import 'package:flutter/material.dart';
import '../../database/database_cache_manager.dart';
import 'dart:async';

/// Tela para visualizar e gerenciar o cache do banco de dados
class DatabaseCacheScreen extends StatefulWidget {
  const DatabaseCacheScreen({Key? key}) : super(key: key);

  @override
  _DatabaseCacheScreenState createState() => _DatabaseCacheScreenState();
}

class _DatabaseCacheScreenState extends State<DatabaseCacheScreen> {
  final DatabaseCacheManager _cacheManager = DatabaseCacheManager();
  Map<String, Map<String, dynamic>> _cacheStats = {};
  Timer? _refreshTimer;
  bool _autoRefresh = false;
  int _refreshInterval = 5; // segundos
  
  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  /// Carrega as estatísticas de cache
  void _loadCacheStats() {
    setState(() {
      _cacheStats = _cacheManager.getStats();
    });
  }
  
  /// Inicia ou para o timer de atualização automática
  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
      
      if (_autoRefresh) {
        _refreshTimer = Timer.periodic(Duration(seconds: _refreshInterval), (timer) {
          _loadCacheStats();
        });
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    });
  }
  
  /// Limpa o cache de uma entidade específica
  void _clearEntityCache(String entityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpar cache de $entityName'),
        content: Text('Tem certeza que deseja limpar o cache de $entityName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _cacheManager.clear(entityName);
              _loadCacheStats();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache de $entityName limpo com sucesso')),
              );
            },
            style: ElevatedButton.styleFrom(
              // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
  
  /// Limpa todos os caches
  void _clearAllCaches() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todos os caches'),
        content: const Text('Tem certeza que deseja limpar todos os caches?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _cacheManager.clearAll();
              _loadCacheStats();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todos os caches foram limpos com sucesso')),
              );
            },
            style: ElevatedButton.styleFrom(
              // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
            ),
            child: const Text('Limpar Todos'),
          ),
        ],
      ),
    );
  }
  
  /// Configura o tamanho máximo do cache para uma entidade
  void _configureEntityCache(String entityName, Map<String, dynamic> stats) {
    final maxSizeController = TextEditingController(text: stats['maxSize'].toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configurar cache de $entityName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: maxSizeController,
              decoration: const InputDecoration(
                labelText: 'Tamanho máximo',
                helperText: 'Número máximo de itens no cache',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final maxSize = int.tryParse(maxSizeController.text);
              if (maxSize != null && maxSize > 0) {
                _cacheManager.setMaxSize(entityName, maxSize);
                _loadCacheStats();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cache de $entityName configurado com sucesso')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Valor inválido para tamanho máximo')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Cache'),
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
            tooltip: _autoRefresh ? 'Pausar atualização' : 'Atualização automática',
            onPressed: _toggleAutoRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar agora',
            onPressed: _loadCacheStats,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Limpar todos os caches',
            onPressed: _clearAllCaches,
          ),
        ],
      ),
      body: _cacheStats.isEmpty
          ? const Center(child: Text('Nenhum cache encontrado'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _cacheStats.length,
              itemBuilder: (context, index) {
                final entityName = _cacheStats.keys.elementAt(index);
                final stats = _cacheStats[entityName]!;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entityName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  tooltip: 'Configurar',
                                  onPressed: () => _configureEntityCache(entityName, stats),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Limpar',
                                  onPressed: () => _clearEntityCache(entityName),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Tamanho atual', '${stats['size']} itens'),
                        _buildStatRow('Tamanho máximo', '${stats['maxSize']} itens'),
                        _buildStatRow('Acertos (hits)', stats['hits'].toString()),
                        _buildStatRow('Falhas (misses)', stats['misses'].toString()),
                        _buildStatRow('Taxa de acertos', '${(stats['hitRatio'] * 100).toStringAsFixed(2)}%'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: stats['size'] / stats['maxSize'],
                          // backgroundColor: Colors.grey[200], // backgroundColor não é suportado em flutter_map 5.0.0
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stats['size'] / stats['maxSize'] > 0.8 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _buildSettingsDialog(),
          );
        },
        tooltip: 'Configurações',
        child: const Icon(Icons.settings),
      ),
    );
  }
  
  /// Constrói uma linha de estatística
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  /// Constrói o diálogo de configurações
  Widget _buildSettingsDialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Configurações de Cache'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Intervalo de atualização'),
                subtitle: const Text('Em segundos'),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: 's',
                    ),
                    controller: TextEditingController(text: '$_refreshInterval'),
                    onChanged: (value) {
                      final interval = int.tryParse(value);
                      if (interval != null && interval > 0) {
                        setState(() {
                          _refreshInterval = interval;
                          
                          // Atualiza o timer se estiver ativo
                          if (_autoRefresh) {
                            _refreshTimer?.cancel();
                            _refreshTimer = Timer.periodic(Duration(seconds: _refreshInterval), (timer) {
                              _loadCacheStats();
                            });
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

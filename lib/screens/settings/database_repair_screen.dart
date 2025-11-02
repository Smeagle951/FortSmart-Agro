import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../database/database_performance_screen.dart';
import '../database/database_cache_screen.dart';
import '../database/database_sync_screen.dart';

class DatabaseRepairScreen extends StatefulWidget {
  const DatabaseRepairScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseRepairScreen> createState() => _DatabaseRepairScreenState();
}

class _DatabaseRepairScreenState extends State<DatabaseRepairScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;
  String _statusMessage = '';
  String _diagnosticResults = '';
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _checkDatabaseHealth();
  }

  Future<void> _checkDatabaseHealth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verificando integridade do banco de dados...';
    });

    try {
      final isHealthy = await _databaseHelper.checkDatabaseHealth();
      
      if (isHealthy) {
        setState(() {
          _statusMessage = 'O banco de dados está íntegro.';
          _diagnosticResults = 'Nenhum problema encontrado.';
        });
      } else {
        final diagnostics = await _databaseHelper.getDatabaseDiagnostics();
        setState(() {
          _statusMessage = 'Foram encontrados problemas no banco de dados.';
          _diagnosticResults = diagnostics;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao verificar o banco de dados.';
        _diagnosticResults = 'Erro: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _repairDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Reparando banco de dados...';
    });

    try {
      await _databaseHelper.repairDatabase();
      
      setState(() {
        _statusMessage = 'Reparo concluído. Verificando resultados...';
      });
      
      // Verificar se o reparo foi bem-sucedido
      await _checkDatabaseHealth();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao reparar o banco de dados.';
        _diagnosticResults = 'Erro: $e';
      });
    }
  }

  Future<void> _repairMachinesTable() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Reparando tabela de máquinas...';
    });

    try {
      final db = await _databaseHelper.database;
      await _databaseHelper.recreateMachinesTable(db);
      
      setState(() {
        _statusMessage = 'Reparo da tabela de máquinas concluído. Verificando resultados...';
      });
      
      // Verificar se o reparo foi bem-sucedido
      await _checkDatabaseHealth();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao reparar a tabela de máquinas.';
        _diagnosticResults = 'Erro: $e';
      });
    }
  }

  Future<void> _recreateDatabase() async {
    // Mostrar diálogo de confirmação
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção!'),
        content: const Text(
          'Esta ação irá excluir e recriar o banco de dados. '
          'TODOS OS DADOS SERÃO PERDIDOS. '
          'Esta ação não pode ser desfeita.\n\n'
          'Tem certeza que deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('SIM, RECRIAR'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Recriando banco de dados...';
    });

    try {
      await _databaseHelper.recreateDatabase();
      
      setState(() {
        _statusMessage = 'Banco de dados recriado com sucesso.';
        _diagnosticResults = 'O banco de dados foi recriado do zero. Todos os dados anteriores foram perdidos.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao recriar o banco de dados.';
        _diagnosticResults = 'Erro: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manutenção do Banco de Dados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Monitoramento de Desempenho',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DatabasePerformanceScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'Gerenciamento de Cache',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DatabaseCacheScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronização de Dados',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DatabaseSyncScreen(),
                ),
              );
            },
          ),
        ],
        // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processando...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_isLoading)
                                const CircularProgressIndicator()
                              else if (_statusMessage.contains('íntegro'))
                                const Icon(Icons.check_circle, color: Colors.green, size: 24)
                              else if (_statusMessage.contains('problemas'))
                                const Icon(Icons.warning, color: Colors.orange, size: 24)
                              else
                                const Icon(Icons.error, color: Colors.red, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _checkDatabaseHealth,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Verificar Novamente'),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Diagnóstico
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Diagnóstico',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const DatabaseCacheScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.storage),
                                    label: const Text('Gerenciar Cache'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const DatabasePerformanceScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.speed),
                                    label: const Text('Monitorar Desempenho'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _diagnosticResults.isEmpty
                                  ? 'Execute a verificação para ver os resultados.'
                                  : _diagnosticResults,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const DatabaseSyncScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.sync),
                            label: const Text('Gerenciar Sincronização'),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ações
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Verificar novamente
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _checkDatabaseHealth,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Verificar Novamente'),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Reparar
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _repairDatabase,
                            icon: const Icon(Icons.build),
                            label: const Text('Reparar Banco de Dados'),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: Colors.orange, // backgroundColor não é suportado em flutter_map 5.0.0
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Reparar tabela de máquinas
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _repairMachinesTable,
                            icon: const Icon(Icons.agriculture),
                            label: const Text('Reparar Tabela de Máquinas'),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  
                  // Opções avançadas
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _showAdvancedOptions
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: Colors.grey[700],
                        ),
                        const Text(
                          'Opções Avançadas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_showAdvancedOptions) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'ATENÇÃO: As opções abaixo são perigosas e podem resultar em perda de dados.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Recriar banco de dados
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _recreateDatabase,
                      icon: const Icon(Icons.warning),
                      label: const Text('Recriar Banco de Dados'),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                        minimumSize: MaterialStateProperty.all<Size>(const Size(double.infinity, 48)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
 }


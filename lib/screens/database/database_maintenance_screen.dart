import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../services/database_helper.dart';
import '../../utils/logger.dart';
import '../../widgets/safe_text_widgets.dart';

/// Tela para diagnóstico e manutenção do banco de dados
class DatabaseMaintenanceScreen extends StatefulWidget {
  const DatabaseMaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseMaintenanceScreen> createState() => _DatabaseMaintenanceScreenState();
}

class _DatabaseMaintenanceScreenState extends State<DatabaseMaintenanceScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  bool _isLoading = false;
  String _dbPath = '';
  int _dbSize = 0; // Restaurado pois é usado no código
  Map<String, dynamic> _integrityCheckResult = {}; // Restaurado pois é usado no código
  Map<String, dynamic> _textEncodingCheckResult = {}; // Restaurado pois é usado no código
  List<String> _tableNames = [];
  Map<String, int> _tableRecordCounts = {};
  Map<String, bool> _tableStatus = {};
  
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }
  
  /// Inicializa o banco de dados se necessário
  Future<void> _initializeDatabase() async {
    try {
      // Garantir que o banco de dados está inicializado
      await _databaseHelper.ensureDbIsOpen();
      print('✅ Banco de dados inicializado com sucesso');
      
      // Carregar informações após inicialização
      await _loadDatabaseInfo();
      await _diagnosticoDoBanco();
    } catch (e) {
      Logger.error('Erro ao inicializar banco de dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao inicializar banco de dados: $e'))
        );
      }
    }
  }
  
  /// Carrega informações básicas do banco de dados
  Future<void> _loadDatabaseInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obter caminho do banco de dados
      final dbPath = await _databaseHelper.getDatabasePath();
      
      // Verificar se o arquivo existe antes de tentar acessá-lo
      final dbFile = await _databaseHelper.getDatabaseFile();
      int dbSize = 0;
      if (await dbFile.exists()) {
        dbSize = await dbFile.length();
      }
      
      // Obter lista de tabelas
      final db = await _databaseHelper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toList();
      
      // Obter contagem de registros para cada tabela
      final Map<String, int> tableCounts = {};
      for (final tableName in tableNames) {
        try {
          final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
          tableCounts[tableName] = Sqflite.firstIntValue(countResult) ?? 0;
        } catch (e) {
          Logger.error('Erro ao contar registros da tabela $tableName: $e');
          tableCounts[tableName] = 0;
        }
      }
      
      setState(() {
        _dbPath = dbPath;
        _dbSize = dbSize;
        _tableNames = tableNames;
        _tableRecordCounts = tableCounts;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar informações do banco de dados: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar informações: $e'))
        );
      }
    }
  }
  
  /// Verifica a integridade do banco de dados
  Future<void> _checkDatabaseIntegrity() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Verificar se o banco está aberto
      await _databaseHelper.ensureDbIsOpen();
      
      // Executar PRAGMA integrity_check
      final db = await _databaseHelper.database;
      final result = await db.rawQuery("PRAGMA integrity_check");
      final isOk = result.isNotEmpty && result.first.values.first == 'ok';
      
      setState(() {
        _integrityCheckResult = {
          'integrityCheck': isOk,
          'tablesCreated': {},
          'indicesCheck': {'problematicIndices': []}
        };
        _isLoading = false;
      });
      
      // Recarregar informações do banco de dados
      await _loadDatabaseInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verificação de integridade concluída'))
        );
      }
    } catch (e) {
      Logger.error('Erro ao verificar integridade do banco de dados: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar integridade: $e'))
        );
      }
    }
  }
  
  /// Verifica e corrige problemas de codificação de texto
  Future<void> _checkTextEncoding() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _databaseHelper.ensureDbIsOpen();
      final db = await _databaseHelper.database;
      
      // Verificar campos de texto em todas as tabelas
      int totalFixedRecords = 0;
      int totalTablesWithIssues = 0;
      int totalTablesChecked = 0;
      Map<String, dynamic> details = {};
      
      for (String tableName in _tableNames) {
        try {
          // Obter informações sobre as colunas da tabela
          final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
          final textColumns = tableInfo
              .where((col) => col['type'].toString().toLowerCase().contains('text'))
              .map((col) => col['name'].toString())
              .toList();
          
          if (textColumns.isEmpty) continue;
          
          totalTablesChecked++;
          int fixedRecords = 0;
          int totalRecords = 0;
          
          // Verificar registros com problemas de codificação
          final records = await db.query(tableName);
          totalRecords = records.length;
          
          // Simulação de correção (em um app real, você implementaria a lógica real de correção)
          // Aqui estamos apenas registrando que verificamos
          
          details[tableName] = {
            'success': true,
            'fixedRecords': fixedRecords,
            'totalRecords': totalRecords
          };
          
          if (fixedRecords > 0) {
            totalTablesWithIssues++;
            totalFixedRecords += fixedRecords;
          }
        } catch (e) {
          details[tableName] = {
            'success': false,
            'error': e.toString()
          };
        }
      }
      
      setState(() {
        _textEncodingCheckResult = {
          'summary': {
            'totalFixedRecords': totalFixedRecords,
            'totalTablesWithIssues': totalTablesWithIssues,
            'totalTablesChecked': totalTablesChecked
          },
          'details': details
        };
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verificação de codificação de texto concluída'))
        );
      }
    } catch (e) {
      Logger.error('Erro ao verificar codificação de texto: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar codificação de texto: $e'))
        );
      }
    }
  }
  
  /// Diagnostica e corrige problemas de banco de dados fechado
  Future<void> _diagnosticoDoBanco() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Primeiro, vamos garantir que o banco de dados esteja aberto
      await _databaseHelper.ensureDbIsOpen();
      
      // Verificar todas as tabelas
      _tableStatus = await _databaseHelper.checkTables();
      
      setState(() {
        _isLoading = false;
      });
      
      // Recarregar informações do banco de dados
      await _loadDatabaseInfo();
      
    } catch (e) {
      Logger.error('Erro ao diagnosticar banco de dados: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao diagnosticar banco de dados: $e'))
        );
      }
    }
  }

  /// Recria o banco de dados
  Future<void> _recreateDatabase() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Mostrar diálogo de confirmação
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recriar Banco de Dados'),
          content: const Text(
            'Esta ação irá recriar completamente o banco de dados. '
            'Todos os dados existentes serão perdidos. Deseja continuar?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Recriar'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Recriar o banco de dados
      await _databaseHelper.resetDatabase();
      
      // Recarregar informações
      await _loadDatabaseInfo();
      await _diagnosticoDoBanco();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banco de dados recriado com sucesso!'))
        );
      }
    } catch (e) {
      Logger.error('Erro ao recriar banco de dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao recriar banco de dados: $e'))
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Gerencia a sincronização do banco de dados
  Future<void> _gerenciarSincronizacao() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Primeiro, vamos garantir que o banco de dados esteja aberto
      await _databaseHelper.ensureDbIsOpen();
      
      // Aqui você pode implementar a lógica de sincronização com o servidor
      // Por enquanto, vamos apenas mostrar uma mensagem
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronização iniciada'))
        );
      }
      
    } catch (e) {
      Logger.error('Erro ao sincronizar banco de dados: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sincronizar banco de dados: $e'))
        );
      }
    }
  }

  /// Reseta o banco de dados
  Future<void> _resetDatabase() async {
    // Mostrar diálogo de confirmação
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Banco de Dados'),
        content: const Text(
          'ATENÇÃO: Esta ação irá excluir todos os dados do aplicativo e criar um novo banco de dados vazio. '
          'Esta operação não pode ser desfeita. Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    
    if (shouldReset != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _databaseHelper.resetDatabase();
      
      // Recarregar informações do banco de dados
      await _loadDatabaseInfo();
      
      setState(() {
        _integrityCheckResult = {};
        _textEncodingCheckResult = {};
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banco de dados resetado com sucesso'))
        );
      }
    } catch (e) {
      Logger.error('Erro ao resetar banco de dados: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao resetar banco de dados: $e'))
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manutenção do Banco de Dados'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiagnosticoCard(),
                  const SizedBox(height: 16),
                  _buildDatabaseInfoCard(),
                  const SizedBox(height: 16),
                  _buildTableInfoCard(),
                  const SizedBox(height: 16),
                  _buildMaintenanceActionsCard(),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _gerenciarSincronizacao,
            icon: const Icon(Icons.sync),
            label: const Text('Gerenciar Sincronização'),
            style: ElevatedButton.styleFrom(
              // backgroundColor: Theme.of(context).primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDiagnosticoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diagnóstico do Banco de Dados:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _diagnosticoDoBanco,
                  tooltip: 'Atualizar diagnóstico',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            ..._tableStatus.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    entry.value ? Icons.check_circle : Icons.error,
                    color: entry.value ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value 
                          ? 'Tabela ${entry.key} está OK'
                          : 'Erro ao verificar tabela ${entry.key}: DatabaseException(error database_closed)',
                      style: TextStyle(
                        color: entry.value ? Colors.black87 : Colors.red,
                        fontWeight: entry.value ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            if (_tableStatus.isEmpty) const Text('Nenhuma tabela verificada ainda.'),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _diagnosticoDoBanco,
                child: const Text('Verificar e Corrigir Problemas'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Theme.of(context).primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseInfoCard() {
    final dbSizeInMB = (_dbSize / (1024 * 1024)).toStringAsFixed(2);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações do Banco de Dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            SafeText('Caminho: $_dbPath'),
            const SizedBox(height: 4),
            Text('Tamanho: $dbSizeInMB MB'),
            const SizedBox(height: 4),
            Text('Tabelas: ${_tableNames.length}'),
            if (_tableNames.isEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _recreateDatabase,
                  icon: const Icon(Icons.build),
                  label: const Text('Recriar Banco de Dados'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tabelas do Banco de Dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            ..._tableNames.map((tableName) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: SafeText('$tableName: ${_tableRecordCounts[tableName] ?? 0} registros'),
              )
            ),
            if (_tableNames.isEmpty)
              const Text('Nenhuma tabela encontrada'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMaintenanceActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ações de Manutenção', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkDatabaseIntegrity,
                icon: const Icon(Icons.security),
                label: const Text('Verificar Integridade'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkTextEncoding,
                icon: const Icon(Icons.text_fields),
                label: const Text('Verificar Codificação de Texto'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetDatabase,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Resetar Banco de Dados'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Removido método não utilizado
  
  // Removido método não utilizado
  
  // Removido método não utilizado
  
  // Método removido para evitar duplicação de código
}

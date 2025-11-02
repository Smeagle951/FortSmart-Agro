import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/app_database.dart';
import '../../services/database_diagnostic_service.dart';
import 'dart:io';
import '../../utils/logger.dart';

class DatabaseDiagnosticScreen extends StatefulWidget {
  const DatabaseDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseDiagnosticScreen> createState() => _DatabaseDiagnosticScreenState();
}

class _DatabaseDiagnosticScreenState extends State<DatabaseDiagnosticScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _diagnosticResults;
  final DatabaseDiagnosticService _diagnosticService = DatabaseDiagnosticService();

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('Iniciando diagnóstico do banco de dados...');
      
      // Usar o novo serviço de diagnóstico
      final results = await _diagnosticService.runFullDiagnostic();
      
      setState(() {
        _diagnosticResults = results;
        _isLoading = false;
      });
      
      Logger.info('Diagnóstico concluído com sucesso');
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao executar diagnóstico: ${e.toString()}';
        _isLoading = false;
      });
      Logger.error('Erro ao executar diagnóstico', e);
    }
  }

  Future<void> _repairDatabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repairResults = await _diagnosticService.repairDatabase();
      
      if (repairResults['status'] == 'OK') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banco de dados reparado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recarregar diagnóstico
        await _loadDatabaseInfo();
      } else {
        setState(() {
          _errorMessage = 'Erro ao reparar: ${repairResults['error']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao reparar banco de dados: ${e.toString()}';
        _isLoading = false;
      });
      Logger.error('Erro ao reparar banco de dados', e);
    }
  }

  Future<void> _forceRecreateDatabase() async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recriar Banco de Dados'),
        content: const Text(
          'Esta ação irá excluir o banco de dados atual e criar um novo com todas as tabelas necessárias. '
          'Todos os dados serão perdidos. Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Recriar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recreateResults = await _diagnosticService.forceRecreateDatabase();
      
      if (recreateResults['status'] == 'OK') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banco de dados recriado com sucesso${recreateResults['backupCreated'] ? ' (backup criado)' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recarregar diagnóstico
        await _loadDatabaseInfo();
      } else {
        setState(() {
          _errorMessage = 'Erro ao recriar: ${recreateResults['error']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao recriar banco de dados: ${e.toString()}';
        _isLoading = false;
      });
      Logger.error('Erro ao recriar banco de dados', e);
    }
  }

  Widget _buildDiagnosticSection(String title, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((entry) {
                if (entry.value is Map) {
                  return _buildDiagnosticSection(entry.key, entry.value);
                } else {
                  return Padding(
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
                            entry.value.toString(),
                            style: TextStyle(
                              color: entry.value.toString().contains('ERROR') 
                                ? Colors.red 
                                : entry.value.toString().contains('OK') 
                                  ? Colors.green 
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico do Banco de Dados'),
        backgroundColor: const Color(0xFF2A4F3D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDatabaseInfo,
            tooltip: 'Atualizar diagnóstico',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Executando diagnóstico...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erro no Diagnóstico',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDatabaseInfo,
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _diagnosticResults == null
                  ? const Center(
                      child: Text('Nenhum resultado disponível'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resumo geral
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Resumo do Diagnóstico',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Status: ${_diagnosticResults!['status'] ?? 'Desconhecido'}',
                                    style: TextStyle(
                                      color: _diagnosticResults!['status'] == 'FAILED' 
                                        ? Colors.red 
                                        : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Ações
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _repairDatabase,
                                  icon: const Icon(Icons.build),
                                  label: const Text('Reparar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _forceRecreateDatabase,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Recriar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Detalhes do diagnóstico
                          if (_diagnosticResults!['databaseAccess'] != null)
                            _buildDiagnosticSection('Acesso ao Banco', _diagnosticResults!['databaseAccess']),
                          
                          if (_diagnosticResults!['integrity'] != null)
                            _buildDiagnosticSection('Integridade', _diagnosticResults!['integrity']),
                          
                          if (_diagnosticResults!['tables'] != null)
                            _buildDiagnosticSection('Tabelas', _diagnosticResults!['tables']),
                          
                          if (_diagnosticResults!['tableStructure'] != null)
                            _buildDiagnosticSection('Estrutura das Tabelas', _diagnosticResults!['tableStructure']),
                          
                          if (_diagnosticResults!['dataCheck'] != null)
                            _buildDiagnosticSection('Verificação de Dados', _diagnosticResults!['dataCheck']),
                          
                          if (_diagnosticResults!['performance'] != null)
                            _buildDiagnosticSection('Performance', _diagnosticResults!['performance']),
                        ],
                      ),
                    ),
    );
  }
}

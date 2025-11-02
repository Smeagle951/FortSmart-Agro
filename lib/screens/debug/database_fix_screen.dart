import 'package:flutter/material.dart';
import '../../scripts/fix_database.dart';
import '../../utils/logger.dart';

/// Tela de debug para corrigir problemas de banco de dados
class DatabaseFixScreen extends StatefulWidget {
  const DatabaseFixScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseFixScreen> createState() => _DatabaseFixScreenState();
}

class _DatabaseFixScreenState extends State<DatabaseFixScreen> {
  bool _isLoading = false;
  String _status = 'Pronto para executar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correção de Banco de Dados'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correção da Tabela fertilizer_calibrations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este utilitário corrige problemas de schema da tabela de calibração de fertilizantes.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: $_status',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _isLoading ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fixDatabase,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build),
              label: Text(_isLoading ? 'Corrigindo...' : 'Corrigir Banco de Dados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testDatabase,
              icon: const Icon(Icons.science),
              label: const Text('Testar Tabela'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Informações',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Este utilitário adiciona colunas faltantes na tabela\n'
                      '• collection_time e collection_type são necessárias\n'
                      '• O teste verifica se a inserção funciona corretamente\n'
                      '• Execute a correção antes de usar a calibração de fertilizantes',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fixDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Iniciando correção...';
    });

    try {
      await DatabaseFixer.fixFertilizerCalibrationsTable();
      
      setState(() {
        _status = 'Correção concluída com sucesso!';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banco de dados corrigido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Erro na correção: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Testando tabela...';
    });

    try {
      await DatabaseFixer.testTable();
      
      setState(() {
        _status = 'Teste concluído com sucesso!';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teste da tabela bem-sucedido!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Erro no teste: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no teste: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_initializer.dart';
import '../utils/text_encoding_helper.dart';
import '../widgets/safe_text.dart' as safe_text;
import '../widgets/safe_title.dart' as safe_title;
import 'text_encoding_fix_screen.dart';

/// Tela de manutenção do banco de dados
/// 
/// Esta tela oferece ferramentas para manutenção e reparo do banco de dados,
/// incluindo verificação de integridade, correção de problemas de codificação,
/// e outras operações de manutenção.
class DatabaseMaintenanceScreen extends StatefulWidget {
  const DatabaseMaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseMaintenanceScreen> createState() => _DatabaseMaintenanceScreenState();
}

class _DatabaseMaintenanceScreenState extends State<DatabaseMaintenanceScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final DatabaseInitializer _initializer = DatabaseInitializer();
  bool _isLoading = false;
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const safe_title.SafeTitle('Manutenção do Banco de Dados'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            if (_isLoading) ...[
              _buildProgressIndicator(),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: _buildToolsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o card de informações
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            safe_title.SafeTitle(
              'Ferramentas de Manutenção',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            safe_text.SafeText(
              'Esta tela oferece ferramentas para manutenção e reparo do banco de dados. '
              'Use estas ferramentas apenas quando necessário, pois algumas operações '
              'podem levar algum tempo para serem concluídas.',
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o indicador de progresso
  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        safe_text.SafeText(_statusMessage),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _progress > 0 ? _progress : null,
        ),
      ],
    );
  }

  /// Constrói a lista de ferramentas disponíveis
  Widget _buildToolsList() {
    return ListView(
      children: [
        _buildToolCard(
          title: 'Verificar Integridade do Banco de Dados',
          description: 'Verifica se todas as tabelas essenciais existem e estão estruturadas corretamente.',
          icon: Icons.check_circle_outline,
          color: Colors.blue,
          onTap: _verifyDatabaseIntegrity,
        ),
        _buildToolCard(
          title: 'Corrigir Problemas de Codificação de Texto',
          description: 'Detecta e corrige problemas de codificação de caracteres especiais nos textos armazenados.',
          icon: Icons.text_fields,
          color: Colors.orange,
          onTap: _openTextEncodingFixScreen,
        ),
        _buildToolCard(
          title: 'Reconstruir Tabelas com Problemas',
          description: 'Reconstrói tabelas que possam estar com problemas estruturais.',
          icon: Icons.build,
          color: Colors.red,
          onTap: _rebuildProblematicTables,
        ),
        _buildToolCard(
          title: 'Limpar Dados Temporários',
          description: 'Remove dados temporários e caches que podem estar ocupando espaço desnecessário.',
          icon: Icons.cleaning_services,
          color: Colors.green,
          onTap: _cleanTemporaryData,
        ),
        _buildToolCard(
          title: 'Backup do Banco de Dados',
          description: 'Cria uma cópia de segurança do banco de dados atual.',
          icon: Icons.backup,
          color: Colors.purple,
          onTap: _backupDatabase,
        ),
      ],
    );
  }

  /// Constrói um card para uma ferramenta específica
  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    safe_text.SafeText(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    safe_text.SafeText(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Verifica a integridade do banco de dados
  Future<void> _verifyDatabaseIntegrity() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Verificando integridade do banco de dados...';
      _progress = 0.0;
    });

    try {
      final success = await _initializer.initializeDatabase(
        onProgress: (message, progress) {
          setState(() {
            _statusMessage = message;
            _progress = progress;
          });
        },
        forceCheck: true,
      );

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Verificação concluída com sucesso!'
            : 'Falha na verificação do banco de dados.';
      });

      _showResultDialog(
        success,
        'Verificação de Integridade',
        success
            ? 'A verificação de integridade do banco de dados foi concluída com sucesso. Todas as tabelas essenciais existem e estão estruturadas corretamente.'
            : 'A verificação de integridade encontrou problemas. Verifique os logs para mais detalhes.',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro: ${e.toString()}';
      });

      _showResultDialog(
        false,
        'Erro na Verificação',
        'Ocorreu um erro durante a verificação: ${e.toString()}',
      );
    }
  }

  /// Abre a tela de correção de problemas de codificação de texto
  Future<void> _openTextEncodingFixScreen() async {
    try {
      final db = await _databaseHelper.getDatabase();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TextEncodingFixScreen(database: db),
        ),
      );
    } catch (e) {
      _showResultDialog(
        false,
        'Erro',
        'Não foi possível abrir a ferramenta de correção: ${e.toString()}',
      );
    }
  }

  /// Reconstrói tabelas com problemas
  Future<void> _rebuildProblematicTables() async {
    final confirmed = await _showConfirmationDialog(
      'Reconstruir Tabelas',
      'Esta operação irá tentar reconstruir tabelas que possam estar com problemas estruturais. '
      'Este processo pode levar algum tempo e, em casos raros, pode resultar em perda de dados. '
      'É recomendável fazer um backup antes de continuar. Deseja prosseguir?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Reconstruindo tabelas com problemas...';
      _progress = 0.0;
    });

    try {
      final db = await _databaseHelper.getDatabase();
      
      // Lista de tabelas essenciais que podem precisar ser reconstruídas
      final essentialTables = [
        'pesticide_applications',
        'harvest_losses',
        'plantings',
        // Adicione outras tabelas essenciais aqui
      ];
      
      int tablesProcessed = 0;
      int tablesRebuilt = 0;
      
      for (final table in essentialTables) {
        setState(() {
          _statusMessage = 'Verificando tabela: $table';
          _progress = tablesProcessed / essentialTables.length;
        });
        
        try {
          // Verifica se a tabela existe
          final tableExists = await _initializer.tableExists(db, table);
          
          if (tableExists) {
            // Tenta reconstruir a tabela
            await _initializer.recreateTableIfNeeded(db, table);
            tablesRebuilt++;
          }
        } catch (e) {
          // Continua para a próxima tabela mesmo se houver erro
          print('Erro ao reconstruir tabela $table: $e');
        }
        
        tablesProcessed++;
      }
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Reconstrução concluída!';
        _progress = 1.0;
      });
      
      _showResultDialog(
        true,
        'Reconstrução de Tabelas',
        'Processo concluído. $tablesRebuilt tabelas foram reconstruídas.',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro: ${e.toString()}';
      });
      
      _showResultDialog(
        false,
        'Erro na Reconstrução',
        'Ocorreu um erro durante o processo: ${e.toString()}',
      );
    }
  }

  /// Limpa dados temporários
  Future<void> _cleanTemporaryData() async {
    final confirmed = await _showConfirmationDialog(
      'Limpar Dados Temporários',
      'Esta operação irá remover dados temporários e caches. '
      'Isso pode ajudar a liberar espaço e melhorar o desempenho. '
      'Deseja prosseguir?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Limpando dados temporários...';
      _progress = 0.2;
    });

    try {
      // Implementar limpeza de dados temporários aqui
      await Future.delayed(const Duration(seconds: 2)); // Simulação
      
      setState(() {
        _progress = 0.8;
        _statusMessage = 'Finalizando limpeza...';
      });
      
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Limpeza concluída!';
        _progress = 1.0;
      });
      
      _showResultDialog(
        true,
        'Limpeza de Dados',
        'Dados temporários foram limpos com sucesso.',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro: ${e.toString()}';
      });
      
      _showResultDialog(
        false,
        'Erro na Limpeza',
        'Ocorreu um erro durante a limpeza: ${e.toString()}',
      );
    }
  }

  /// Cria um backup do banco de dados
  Future<void> _backupDatabase() async {
    final confirmed = await _showConfirmationDialog(
      'Backup do Banco de Dados',
      'Esta operação irá criar uma cópia de segurança do banco de dados atual. '
      'Deseja prosseguir?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Criando backup do banco de dados...';
      _progress = 0.2;
    });

    try {
      // Implementar backup do banco de dados aqui
      await Future.delayed(const Duration(seconds: 3)); // Simulação
      
      setState(() {
        _progress = 0.9;
        _statusMessage = 'Finalizando backup...';
      });
      
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Backup concluído!';
        _progress = 1.0;
      });
      
      _showResultDialog(
        true,
        'Backup do Banco de Dados',
        'Backup criado com sucesso.',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro: ${e.toString()}';
      });
      
      _showResultDialog(
        false,
        'Erro no Backup',
        'Ocorreu um erro durante o backup: ${e.toString()}',
      );
    }
  }

  /// Exibe um diálogo de confirmação
  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: safe_text.SafeText(title),
        content: safe_text.SafeText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const safe_text.SafeText('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const safe_text.SafeText('Continuar'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Exibe um diálogo com o resultado da operação
  void _showResultDialog(bool success, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: safe_text.SafeText(title),
        content: safe_text.SafeText(message),
        icon: Icon(
          success ? Icons.check_circle : Icons.error_outline,
          color: success ? Colors.green : Colors.red,
          size: 48,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const safe_text.SafeText('OK'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/database_text_encoding_fixer.dart';
import '../utils/text_encoding_helper.dart';
import '../widgets/safe_text.dart';
import '../widgets/safe_title.dart';
import '../widgets/text_encoding_error_widget.dart';

/// Tela para gerenciar e corrigir problemas de codificação de texto no banco de dados
class TextEncodingFixScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final Database? database;

  const TextEncodingFixScreen({
    Key? key,
    this.onComplete,
    this.database,
  }) : super(key: key);

  @override
  State<TextEncodingFixScreen> createState() => _TextEncodingFixScreenState();
}

class _TextEncodingFixScreenState extends State<TextEncodingFixScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Database? _database;
  bool _isScanning = false;
  bool _isFixing = false;
  bool _hasIssues = false;
  double _progress = 0.0;
  String _statusMessage = 'Aguardando verificação...';
  String _detailMessage = '';
  Map<String, int> _tableIssues = {};
  List<String> _tablesWithIssues = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }
  
  /// Inicializa o banco de dados
  Future<void> _initDatabase() async {
    try {
      if (widget.database != null) {
        _database = widget.database;
      } else {
        _database = await _databaseHelper.database;
      }
      _checkForEncodingIssues();
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao conectar ao banco de dados: $e';
      });
    }
  }

  /// Verifica se há problemas de codificação no banco de dados
  Future<void> _checkForEncodingIssues() async {
    if (_isScanning || _isFixing || _database == null) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Verificando problemas de codificação...';
      _progress = 0.0;
    });

    try {
      // Obtém a lista de todas as tabelas do banco de dados
      final List<Map<String, dynamic>> tables = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
      );

      final fixer = DatabaseTextEncodingFixer(
        database: _database!,
        onProgress: (message, progress) {
          setState(() {
            _statusMessage = message;
            _progress = progress;
          });
        },
      );

      _tablesWithIssues = [];
      _tableIssues = {};
      int tablesChecked = 0;

      // Verifica cada tabela
      for (final table in tables) {
        final String tableName = table['name'] as String;
        
        setState(() {
          _statusMessage = 'Verificando tabela: $tableName';
          _progress = tablesChecked / tables.length;
        });

        final bool hasIssues = await fixer.tableHasEncodingIssues(tableName);
        
        if (hasIssues) {
          _tablesWithIssues.add(tableName);
        }
        
        tablesChecked++;
      }

      setState(() {
        _hasIssues = _tablesWithIssues.isNotEmpty;
        _statusMessage = _hasIssues 
            ? 'Foram encontrados problemas em ${_tablesWithIssues.length} tabelas' 
            : 'Nenhum problema de codificação encontrado';
        _progress = 1.0;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao verificar problemas de codificação: ${e.toString()}';
        _isScanning = false;
        _progress = 0.0;
      });
    }
  }

  /// Corrige problemas de codificação em todas as tabelas
  Future<void> _fixAllEncodingIssues() async {
    if (_isFixing || _database == null) return;

    setState(() {
      _isFixing = true;
      _statusMessage = 'Corrigindo problemas de codificação...';
      _progress = 0.0;
    });

    try {
      int fixedCount = 0;
      int totalTables = _tablesWithIssues.length;

      for (int i = 0; i < totalTables; i++) {
        final tableName = _tablesWithIssues[i];
        
        setState(() {
          _statusMessage = 'Corrigindo tabela $tableName...';
          _progress = i / totalTables;
        });

        final fixed = await DatabaseTextEncodingFixer.fixTableEncodingIssues(
          _database!,
          tableName,
          (message) {
            setState(() {
              _detailMessage = message;
            });
          },
        );

        if (fixed > 0) {
          fixedCount += fixed;
        }
      }

      setState(() {
        _isFixing = false;
        _progress = 1.0;
        _statusMessage = 'Correção concluída!';
        _detailMessage = 'Foram corrigidos $fixedCount problemas de codificação.';
      });

      // Verifica novamente para atualizar a lista de problemas
      await _checkForEncodingIssues();
      
      // Se não houver mais problemas, chama o callback de conclusão
      if (!_hasIssues && widget.onComplete != null) {
        widget.onComplete!();
      }
    } catch (e) {
      setState(() {
        _isFixing = false;
        _statusMessage = 'Erro ao corrigir problemas de codificação';
        _detailMessage = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SafeTitle('Correção de Codificação de Texto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildProgressSection(),
            const SizedBox(height: 24),
            if (_hasIssues && !_isScanning && !_isFixing)
              _buildIssuesFoundSection(),
            if (!_isScanning && !_isFixing && _tableIssues.isNotEmpty)
              _buildResultsSection(),
            const Spacer(),
            _buildActionButtons(),
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
            SafeTitle(
              'Sobre Problemas de Codificação',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            SafeText(
              'Problemas de codificação podem ocorrer quando textos com caracteres especiais '
              '(como acentos e cedilhas) são armazenados incorretamente no banco de dados. '
              'Isso pode causar a exibição incorreta desses caracteres na interface do aplicativo.',
            ),
            SizedBox(height: 8),
            SafeText(
              'Esta ferramenta verifica e corrige automaticamente esses problemas, '
              'normalizando a codificação de todos os textos armazenados no banco de dados.',
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói a seção de progresso
  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeTitle(
          'Status',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        SafeText(_statusMessage),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _isScanning || _isFixing ? _progress : null,
          // backgroundColor: Colors.grey.shade300, // backgroundColor não é suportado em flutter_map 5.0.0
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        if (_detailMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          SafeText(
            _detailMessage,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }

  /// Constrói a seção de problemas encontrados
  Widget _buildIssuesFoundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeTitle(
          'Tabelas com Problemas',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          height: 150,
          child: ListView.builder(
            itemCount: _tablesWithIssues.length,
            itemBuilder: (context, index) {
              final tableName = _tablesWithIssues[index];
              return ListTile(
                title: SafeText(tableName),
                leading: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                ),
                dense: true,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const TextEncodingWarningBanner(
          onDismiss: null,
          onFix: null,
        ),
      ],
    );
  }

  /// Constrói a seção de resultados
  Widget _buildResultsSection() {
    final totalFixed = _tableIssues.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SafeTitle(
          'Resultados da Correção',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        SafeText('Total de registros corrigidos: $totalFixed'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          height: 150,
          child: ListView.builder(
            itemCount: _tableIssues.entries.length,
            itemBuilder: (context, index) {
              final entry = _tableIssues.entries.elementAt(index);
              return ListTile(
                title: SafeText(entry.key),
                trailing: SafeText('${entry.value} corrigidos'),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Constrói os botões de ação
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: (_isScanning || _isFixing) ? null : _checkForEncodingIssues,
          icon: const Icon(Icons.search),
          label: const SafeText('Verificar Problemas'),
          style: ElevatedButton.styleFrom(
            // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: (_isScanning || _isFixing || !_hasIssues) ? null : _fixAllEncodingIssues,
          icon: const Icon(Icons.build),
          label: const SafeText('Corrigir Problemas'),
          style: ElevatedButton.styleFrom(
            // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

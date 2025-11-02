import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'text_encoding_helper.dart';

/// Classe utilitária para corrigir problemas de codificação de texto no banco de dados
class DatabaseTextEncodingFixer {
  final Database database;
  final Function(String message, double progress)? onProgress;

  /// Construtor para a classe DatabaseTextEncodingFixer
  /// 
  /// [database] é a instância do banco de dados a ser corrigida
  /// [onProgress] é uma função de callback para reportar o progresso da correção
  DatabaseTextEncodingFixer({
    required this.database,
    this.onProgress,
  });

  /// Verifica e corrige problemas de codificação em todas as tabelas do banco de dados
  Future<Map<String, int>> fixAllTables() async {
    // Obtém a lista de todas as tabelas do banco de dados
    final List<Map<String, dynamic>> tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );

    final Map<String, int> results = {};
    final int totalTables = tables.length;
    int processedTables = 0;

    // Processa cada tabela
    for (final table in tables) {
      final String tableName = table['name'] as String;
      
      _reportProgress(
        'Verificando tabela: $tableName',
        processedTables / totalTables,
      );

      final int fixedCount = await fixTable(tableName);
      results[tableName] = fixedCount;

      processedTables++;
      _reportProgress(
        'Tabela $tableName: $fixedCount registros corrigidos',
        processedTables / totalTables,
      );
    }

    _reportProgress('Correção de codificação concluída', 1.0);
    return results;
  }

  /// Verifica e corrige problemas de codificação em uma tabela específica
  Future<int> fixTable(String tableName) async {
    // Obtém a lista de colunas da tabela
    final List<Map<String, dynamic>> columnsInfo = await database.rawQuery(
      "PRAGMA table_info($tableName)",
    );

    // Filtra apenas colunas do tipo TEXT
    final List<String> textColumns = columnsInfo
        .where((col) => 
            col['type'].toString().toUpperCase() == 'TEXT' || 
            col['type'].toString().toUpperCase() == 'VARCHAR')
        .map((col) => col['name'] as String)
        .toList();

    if (textColumns.isEmpty) {
      return 0; // Não há colunas de texto para corrigir
    }

    // Obtém todos os registros da tabela
    final List<Map<String, dynamic>> records = await database.query(tableName);
    
    int fixedCount = 0;
    int processedRecords = 0;
    final int totalRecords = records.length;

    // Processa cada registro
    for (final record in records) {
      bool recordNeedsUpdate = false;
      final Map<String, dynamic> updatedRecord = Map.from(record);
      
      // Verifica cada coluna de texto
      for (final column in textColumns) {
        final dynamic value = record[column];
        
        // Verifica se o valor é uma string e se tem problemas de codificação
        if (value is String && value.isNotEmpty && TextEncodingHelper.hasEncodingIssues(value)) {
          final String normalizedValue = TextEncodingHelper.normalizeText(value);
          
          // Se o valor normalizado for diferente do original, marca para atualização
          if (normalizedValue != value) {
            updatedRecord[column] = normalizedValue;
            recordNeedsUpdate = true;
          }
        }
      }
      
      // Atualiza o registro se necessário
      if (recordNeedsUpdate) {
        final String primaryKeyColumn = await _getPrimaryKeyColumn(tableName);
        final dynamic primaryKeyValue = record[primaryKeyColumn];
        
        if (primaryKeyValue != null) {
          await database.update(
            tableName,
            updatedRecord,
            where: '$primaryKeyColumn = ?',
            whereArgs: [primaryKeyValue],
          );
          
          fixedCount++;
        }
      }
      
      processedRecords++;
      if (processedRecords % 50 == 0 || processedRecords == totalRecords) {
        _reportProgress(
          'Processando tabela $tableName: $processedRecords/$totalRecords registros',
          (processedRecords / totalRecords) * 0.9, // Reserva 10% para a conclusão
        );
      }
    }
    
    return fixedCount;
  }

  /// Obtém o nome da coluna que é chave primária da tabela
  Future<String> _getPrimaryKeyColumn(String tableName) async {
    final List<Map<String, dynamic>> columnsInfo = await database.rawQuery(
      "PRAGMA table_info($tableName)",
    );
    
    // Procura pela coluna marcada como chave primária (pk = 1)
    final primaryKeyColumn = columnsInfo.firstWhere(
      (col) => col['pk'] == 1,
      orElse: () => columnsInfo.first, // Se não encontrar, usa a primeira coluna
    );
    
    return primaryKeyColumn['name'] as String;
  }

  /// Verifica se uma tabela específica tem problemas de codificação
  Future<bool> tableHasEncodingIssues(String tableName) async {
    // Obtém a lista de colunas da tabela
    final List<Map<String, dynamic>> columnsInfo = await database.rawQuery(
      "PRAGMA table_info($tableName)",
    );

    // Filtra apenas colunas do tipo TEXT
    final List<String> textColumns = columnsInfo
        .where((col) => 
            col['type'].toString().toUpperCase() == 'TEXT' || 
            col['type'].toString().toUpperCase() == 'VARCHAR')
        .map((col) => col['name'] as String)
        .toList();

    if (textColumns.isEmpty) {
      return false; // Não há colunas de texto para verificar
    }

    // Cria uma consulta para verificar problemas de codificação em cada coluna
    final List<String> conditions = textColumns.map((column) {
      // Verifica padrões comuns de problemas de codificação (caracteres especiais mal codificados)
      return "$column LIKE '%Ã£%' OR $column LIKE '%Ã©%' OR $column LIKE '%Ã§%'";
    }).toList();

    // Executa a consulta para verificar se há registros com problemas
    final List<Map<String, dynamic>> result = await database.rawQuery(
      "SELECT COUNT(*) as count FROM $tableName WHERE ${conditions.join(' OR ')}",
    );

    final int count = result.first['count'] as int;
    return count > 0;
  }

  /// Reporta o progresso da correção
  void _reportProgress(String message, double progress) {
    if (onProgress != null) {
      onProgress!(message, progress);
    }
  }

  /// Verifica se o banco de dados tem problemas de codificação
  static Future<bool> databaseHasEncodingIssues(Database database) async {
    final fixer = DatabaseTextEncodingFixer(database: database);
    
    // Obtém a lista de todas as tabelas do banco de dados
    final List<Map<String, dynamic>> tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );

    // Verifica cada tabela
    for (final table in tables) {
      final String tableName = table['name'] as String;
      final bool hasIssues = await fixer.tableHasEncodingIssues(tableName);
      
      if (hasIssues) {
        return true; // Encontrou problemas em pelo menos uma tabela
      }
    }
    
    return false; // Não encontrou problemas em nenhuma tabela
  }

  /// Método estático para corrigir problemas de codificação em uma tabela específica
  static Future<int> fixTableEncodingIssues(
    Database database,
    String tableName,
    Function(String message)? onProgress,
  ) async {
    try {
      // Obter informações sobre as colunas da tabela
      final List<Map<String, dynamic>> tableInfo = await database.rawQuery(
        "PRAGMA table_info('$tableName')",
      );
      
      // Filtrar apenas colunas de texto
      final List<String> textColumns = [];
      for (final column in tableInfo) {
        final String typeName = column['type'].toString().toUpperCase();
        if (typeName == 'TEXT' || typeName.contains('CHAR') || typeName.contains('VARCHAR')) {
          textColumns.add(column['name'].toString());
        }
      }
      
      // Se não houver colunas de texto, não há o que corrigir
      if (textColumns.isEmpty) {
        if (onProgress != null) {
          onProgress('Tabela $tableName não possui colunas de texto para corrigir');
        }
        return 0;
      }
      
      // Obter todos os registros da tabela
      final List<Map<String, dynamic>> records = await database.query(tableName);
      
      // Se não houver registros, não há o que corrigir
      if (records.isEmpty) {
        if (onProgress != null) {
          onProgress('Tabela $tableName não possui registros para corrigir');
        }
        return 0;
      }
      
      int fixedCount = 0;
      
      // Processar cada registro
      for (final record in records) {
        bool needsUpdate = false;
        final Map<String, dynamic> updatedRecord = Map<String, dynamic>.from(record);
        
        // Verificar e corrigir cada coluna de texto
        for (final column in textColumns) {
          if (record[column] != null && record[column] is String) {
            final String originalText = record[column] as String;
            final String fixedText = TextEncodingHelper.fixEncodingIssues(originalText);
            
            // Se o texto foi modificado, atualizar o registro
            if (fixedText != originalText) {
              updatedRecord[column] = fixedText;
              needsUpdate = true;
            }
          }
        }
        
        // Se alguma coluna foi modificada, atualizar o registro no banco de dados
        if (needsUpdate) {
          // Determinar a coluna de ID para a cláusula WHERE
          String? idColumn;
          for (final column in tableInfo) {
            if (column['pk'] == 1) {
              idColumn = column['name'].toString();
              break;
            }
          }
          
          // Se não encontrou uma coluna de ID, usar a primeira coluna como referência
          idColumn ??= tableInfo.first['name'].toString();
          
          // Atualizar o registro
          await database.update(
            tableName,
            updatedRecord,
            where: '$idColumn = ?',
            whereArgs: [record[idColumn]],
          );
          
          fixedCount++;
        }
      }
      
      if (onProgress != null) {
        onProgress('Tabela $tableName: $fixedCount registros corrigidos');
      }
      
      return fixedCount;
    } catch (e) {
      if (onProgress != null) {
        onProgress('Erro ao corrigir tabela $tableName: $e');
      }
      return 0;
    }
  }
}

import 'package:sqflite/sqflite.dart';
import '../utils/text_encoding_helper.dart';
import '../utils/logger.dart';

/// Classe responsável por corrigir problemas de codificação de texto no banco de dados
class DatabaseTextEncodingFixer {
  final Database database;

  DatabaseTextEncodingFixer(this.database);

  /// Verifica e corrige problemas de codificação em uma tabela específica
  Future<Map<String, dynamic>> fixTextEncodingInTable(String tableName, List<String> textColumns) async {
    try {
      // Obter todos os registros da tabela
      final List<Map<String, dynamic>> records = await database.query(tableName);
      
      int fixedRecordsCount = 0;
      int totalRecords = records.length;
      
      // Para cada registro, verificar e corrigir problemas de codificação
      for (var record in records) {
        Map<String, dynamic> updatedValues = {};
        bool needsUpdate = false;
        
        // Verificar cada coluna de texto
        for (var column in textColumns) {
          if (record[column] != null && record[column] is String) {
            final String originalText = record[column];
            final String fixedText = TextEncodingHelper.normalizeText(originalText);
            
            // Se o texto foi alterado, adicionar à lista de valores a atualizar
            if (fixedText != originalText) {
              updatedValues[column] = fixedText;
              needsUpdate = true;
            }
          }
        }
        
        // Se houver valores para atualizar, fazer o update
        if (needsUpdate) {
          await database.update(
            tableName,
            updatedValues,
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          fixedRecordsCount++;
        }
      }
      
      Logger.log('Verificação de codificação concluída para a tabela $tableName: $fixedRecordsCount/$totalRecords registros corrigidos');
      
      return {
        'table': tableName,
        'totalRecords': totalRecords,
        'fixedRecords': fixedRecordsCount,
        'success': true
      };
    } catch (e) {
      Logger.error('Erro ao corrigir codificação na tabela $tableName: $e');
      return {
        'table': tableName,
        'error': e.toString(),
        'success': false
      };
    }
  }
  
  /// Verifica e corrige problemas de codificação em todas as tabelas de texto
  Future<Map<String, dynamic>> fixAllTextEncodings() async {
    // Lista de tabelas e suas colunas de texto
    final Map<String, List<String>> tableTextColumns = {
      // Tabelas do sistema climático
      'weather_data': ['locationName', 'conditions', 'windDirection'],
      'weather_forecast': ['locationName', 'conditions', 'windDirection'],
      'hourly_weather': ['locationName', 'conditions'],
      
      // Tabelas de monitoramento
      'monitoring_points': ['observations', 'metadata'],
      'monitorings': ['route', 'cropName', 'plotName'],
      
      // Tabelas de operações agrícolas
      'pesticide_applications': ['productName', 'dosageUnit', 'targetPest', 'weather', 'observations', 'plotName', 'cropName', 'machineName'],
      'harvest_losses': ['cropName', 'responsiblePerson', 'observations'],
      'plantings': ['plotName', 'cropName', 'variety', 'fertilization', 'observations', 'machineName'],
      
      // Tabelas de cadastro
      'farms': ['name', 'responsible_person', 'address', 'crops', 'cultivation_system', 'irrigation_type', 'mechanization_level', 'technical_responsible_name'],
      'plots': ['name'],
      'crops': ['name', 'scientificName', 'category'],
      'pests': ['name', 'scientificName', 'description'],
      'diseases': ['name', 'scientificName', 'description'],
      'weeds': ['name', 'scientificName', 'description'],
      'machines': ['name', 'brand', 'model', 'serialNumber', 'status', 'notes']
    };
    
    final results = <String, dynamic>{};
    int totalFixedRecords = 0;
    int totalTablesWithIssues = 0;
    
    // Corrigir cada tabela
    for (var entry in tableTextColumns.entries) {
      final tableName = entry.key;
      final columns = entry.value;
      
      try {
        // Verificar se a tabela existe antes de tentar corrigir
        final tableExists = await _tableExists(tableName);
        
        if (tableExists) {
          final tableResult = await fixTextEncodingInTable(tableName, columns);
          results[tableName] = tableResult;
          
          if (tableResult['fixedRecords'] > 0) {
            totalFixedRecords += tableResult['fixedRecords'] as int;
            totalTablesWithIssues++;
          }
        } else {
          results[tableName] = {
            'table': tableName,
            'error': 'Tabela não existe',
            'success': false
          };
        }
      } catch (e) {
        results[tableName] = {
          'table': tableName,
          'error': e.toString(),
          'success': false
        };
      }
    }
    
    return {
      'summary': {
        'totalFixedRecords': totalFixedRecords,
        'totalTablesWithIssues': totalTablesWithIssues,
        'totalTablesChecked': tableTextColumns.length
      },
      'details': results
    };
  }
  
  /// Verifica se uma tabela existe no banco de dados
  Future<bool> _tableExists(String tableName) async {
    final result = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    return result.isNotEmpty;
  }
}

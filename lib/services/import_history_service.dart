import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/file_import/file_import_main_screen.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar histórico de importações
class ImportHistoryService {
  static const String _historyKey = 'import_history';
  static const int _maxHistoryItems = 50; // Limitar histórico a 50 itens

  /// Salva resultado de importação no histórico
  static Future<void> saveImportResult(ImportResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      // Converter resultado para JSON
      final resultJson = _importResultToJson(result);
      
      // Adicionar ao início da lista
      historyJson.insert(0, resultJson);
      
      // Limitar tamanho do histórico
      if (historyJson.length > _maxHistoryItems) {
        historyJson.removeRange(_maxHistoryItems, historyJson.length);
      }
      
      // Salvar no SharedPreferences
      await prefs.setStringList(_historyKey, historyJson);
      
      Logger.info('💾 [IMPORT_HISTORY] Resultado salvo no histórico: ${result.fileName}');
    } catch (e) {
      Logger.error('❌ [IMPORT_HISTORY] Erro ao salvar histórico: $e');
    }
  }

  /// Carrega histórico de importações
  static Future<List<ImportResult>> loadImportHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      final history = historyJson
          .map((json) => _importResultFromJson(json))
          .where((result) => result != null)
          .cast<ImportResult>()
          .toList();
      
      Logger.info('📖 [IMPORT_HISTORY] ${history.length} itens carregados do histórico');
      return history;
    } catch (e) {
      Logger.error('❌ [IMPORT_HISTORY] Erro ao carregar histórico: $e');
      return [];
    }
  }

  /// Remove item do histórico
  static Future<void> removeImportResult(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      // Remover item com o nome do arquivo especificado
      historyJson.removeWhere((json) {
        try {
          final data = jsonDecode(json);
          return data['fileName'] == fileName;
        } catch (e) {
          return false;
        }
      });
      
      await prefs.setStringList(_historyKey, historyJson);
      
      Logger.info('🗑️ [IMPORT_HISTORY] Item removido do histórico: $fileName');
    } catch (e) {
      Logger.error('❌ [IMPORT_HISTORY] Erro ao remover do histórico: $e');
    }
  }

  /// Limpa todo o histórico
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      
      Logger.info('🧹 [IMPORT_HISTORY] Histórico limpo');
    } catch (e) {
      Logger.error('❌ [IMPORT_HISTORY] Erro ao limpar histórico: $e');
    }
  }

  /// Obtém estatísticas do histórico
  static Future<Map<String, dynamic>> getHistoryStatistics() async {
    try {
      final history = await loadImportHistory();
      
      if (history.isEmpty) {
        return {
          'totalImports': 0,
          'successfulImports': 0,
          'failedImports': 0,
          'totalItems': 0,
          'importTypes': {},
          'lastImport': null,
        };
      }
      
      final successfulImports = history.where((r) => r.status == ImportStatus.success).length;
      final failedImports = history.where((r) => r.status == ImportStatus.error).length;
      final totalItems = history.fold<int>(0, (sum, r) => sum + r.itemCount);
      
      // Contar tipos de importação
      final importTypes = <String, int>{};
      for (final result in history) {
        final type = result.importType ?? 'genérico';
        importTypes[type] = (importTypes[type] ?? 0) + 1;
      }
      
      return {
        'totalImports': history.length,
        'successfulImports': successfulImports,
        'failedImports': failedImports,
        'totalItems': totalItems,
        'importTypes': importTypes,
        'lastImport': history.isNotEmpty ? history.first.importDate.toIso8601String() : null,
      };
    } catch (e) {
      Logger.error('❌ [IMPORT_HISTORY] Erro ao calcular estatísticas: $e');
      return {};
    }
  }

  /// Converte ImportResult para JSON
  static String _importResultToJson(ImportResult result) {
    return jsonEncode({
      'fileName': result.fileName,
      'filePath': result.filePath,
      'itemCount': result.itemCount,
      'status': result.status.toString(),
      'importDate': result.importDate.toIso8601String(),
      'data': result.data,
      'errors': result.errors,
      'statistics': result.statistics,
      'importType': result.importType,
    });
  }

  /// Converte JSON para ImportResult
  static ImportResult? _importResultFromJson(String json) {
    try {
      final data = jsonDecode(json);
      
      return ImportResult(
        fileName: data['fileName'] ?? '',
        filePath: data['filePath'] ?? '',
        itemCount: data['itemCount'] ?? 0,
        status: _parseImportStatus(data['status']),
        importDate: DateTime.parse(data['importDate']),
        data: Map<String, dynamic>.from(data['data'] ?? {}),
        errors: List<String>.from(data['errors'] ?? []),
        statistics: data['statistics'] != null 
            ? Map<String, dynamic>.from(data['statistics']) 
            : null,
        importType: data['importType'],
      );
    } catch (e) {
      Logger.error('❌ [IMPORT_HISTORY] Erro ao converter JSON: $e');
      return null;
    }
  }

  /// Converte string para ImportStatus
  static ImportStatus _parseImportStatus(String? statusString) {
    switch (statusString) {
      case 'ImportStatus.success':
        return ImportStatus.success;
      case 'ImportStatus.error':
        return ImportStatus.error;
      case 'ImportStatus.warning':
        return ImportStatus.warning;
      default:
        return ImportStatus.error;
    }
  }
}

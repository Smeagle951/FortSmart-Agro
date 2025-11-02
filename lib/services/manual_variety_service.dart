import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar variedades manuais (digitadas pelo usuário)
class ManualVarietyService {
  static const String _keyPrefix = 'manual_variety_';
  
  /// Armazena o nome de uma variedade manual
  static Future<void> storeManualVarietyName(String varietyId, String varietyName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$varietyId', varietyName);
      Logger.info('✅ Nome da variedade manual armazenado: $varietyName');
    } catch (e) {
      Logger.error('❌ Erro ao armazenar nome da variedade manual: $e');
    }
  }
  
  /// Recupera o nome de uma variedade manual
  static Future<String?> getManualVarietyName(String varietyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_keyPrefix$varietyId');
    } catch (e) {
      Logger.error('❌ Erro ao recuperar nome da variedade manual: $e');
      return null;
    }
  }
  
  /// Remove uma variedade manual armazenada
  static Future<void> removeManualVarietyName(String varietyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$varietyId');
      Logger.info('✅ Nome da variedade manual removido: $varietyId');
    } catch (e) {
      Logger.error('❌ Erro ao remover nome da variedade manual: $e');
    }
  }
  
  /// Lista todas as variedades manuais armazenadas
  static Future<Map<String, String>> getAllManualVarieties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix)).toList();
      
      final Map<String, String> varieties = {};
      for (String key in keys) {
        final varietyId = key.replaceFirst(_keyPrefix, '');
        final varietyName = prefs.getString(key);
        if (varietyName != null) {
          varieties[varietyId] = varietyName;
        }
      }
      
      return varieties;
    } catch (e) {
      Logger.error('❌ Erro ao listar variedades manuais: $e');
      return {};
    }
  }
}

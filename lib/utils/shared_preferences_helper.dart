import 'package:shared_preferences/shared_preferences.dart';

/// Classe auxiliar para facilitar o acesso ao SharedPreferences
class SharedPreferencesHelper {
  /// Obtém uma string do SharedPreferences
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  
  /// Define uma string no SharedPreferences
  Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }
  
  /// Remove um valor do SharedPreferences
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }
  
  /// Verifica se uma chave existe no SharedPreferences
  Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}

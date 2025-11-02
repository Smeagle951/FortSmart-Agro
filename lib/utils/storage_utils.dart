import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

/// Classe utilitária para operações de armazenamento local
class StorageUtils {
  static final StorageUtils _instance = StorageUtils._internal();
  static SharedPreferences? _prefs;
  
  /// Construtor de fábrica para o singleton
  factory StorageUtils() {
    return _instance;
  }
  
  StorageUtils._internal();
  
  /// Inicializa o armazenamento
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      Logger.error('Erro ao inicializar o armazenamento', e);
    }
  }
  
  /// Retorna a instância de SharedPreferences
  static Future<SharedPreferences> getPrefs() async {
    if (_prefs == null) await init();
    return _prefs!;
  }
  
  /// Salva uma string
  static Future<bool> saveString(String key, String value) async {
    try {
      if (_prefs == null) await init();
      return await _prefs!.setString(key, value);
    } catch (e) {
      Logger.error('Erro ao salvar string', e);
      return false;
    }
  }
  
  /// Obtém uma string
  static String? getString(String key) {
    try {
      if (_prefs == null) return null;
      return _prefs!.getString(key);
    } catch (e) {
      Logger.error('Erro ao obter string', e);
      return null;
    }
  }
  
  /// Verifica se há espaço suficiente para sincronização
  Future<bool> hasEnoughStorageForSync() async {
    try {
      // Implementação simplificada - assumindo que há espaço suficiente
      // Em uma implementação real, verificaria o espaço disponível no dispositivo
      return true;
    } catch (e) {
      Logger.error('Erro ao verificar espaço disponível', e);
      return false;
    }
  }
  
  /// Salva um inteiro
  static Future<bool> saveInt(String key, int value) async {
    try {
      if (_prefs == null) await init();
      return await _prefs!.setInt(key, value);
    } catch (e) {
      Logger.error('Erro ao salvar inteiro', e);
      return false;
    }
  }
  
  /// Obtém um inteiro
  static int? getInt(String key) {
    try {
      if (_prefs == null) return null;
      return _prefs!.getInt(key);
    } catch (e) {
      Logger.error('Erro ao obter inteiro', e);
      return null;
    }
  }
  
  /// Salva um booleano
  static Future<bool> saveBool(String key, bool value) async {
    try {
      if (_prefs == null) await init();
      return await _prefs!.setBool(key, value);
    } catch (e) {
      Logger.error('Erro ao salvar booleano', e);
      return false;
    }
  }
  
  /// Obtém um booleano
  static bool? getBool(String key) {
    try {
      if (_prefs == null) return null;
      return _prefs!.getBool(key);
    } catch (e) {
      Logger.error('Erro ao obter booleano', e);
      return null;
    }
  }
  
  /// Salva uma lista de strings
  static Future<bool> saveStringList(String key, List<String> value) async {
    try {
      if (_prefs == null) await init();
      return await _prefs!.setStringList(key, value);
    } catch (e) {
      Logger.error('Erro ao salvar lista de strings', e);
      return false;
    }
  }
  
  /// Obtém uma lista de strings
  static List<String>? getStringList(String key) {
    try {
      if (_prefs == null) return null;
      return _prefs!.getStringList(key);
    } catch (e) {
      Logger.error('Erro ao obter lista de strings', e);
      return null;
    }
  }
  
  /// Salva um objeto como JSON
  static Future<bool> saveObject(String key, dynamic value) async {
    try {
      if (_prefs == null) await init();
      final String jsonString = json.encode(value);
      return await _prefs!.setString(key, jsonString);
    } catch (e) {
      Logger.error('Erro ao salvar objeto', e);
      return false;
    }
  }
  
  /// Obtém um objeto de JSON
  static dynamic getObject(String key) {
    try {
      if (_prefs == null) return null;
      final String? jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;
      return json.decode(jsonString);
    } catch (e) {
      Logger.error('Erro ao obter objeto', e);
      return null;
    }
  }
  
  /// Remove um item
  static Future<bool> remove(String key) async {
    try {
      if (_prefs == null) await init();
      return await _prefs!.remove(key);
    } catch (e) {
      Logger.error('Erro ao remover item', e);
      return false;
    }
  }
  
  /// Limpa todos os dados
  static Future<bool> clear() async {
    try {
      if (_prefs == null) await init();
      return await _prefs!.clear();
    } catch (e) {
      Logger.error('Erro ao limpar armazenamento', e);
      return false;
    }
  }
  
  /// Verifica se uma chave existe
  static bool containsKey(String key) {
    try {
      if (_prefs == null) return false;
      return _prefs!.containsKey(key);
    } catch (e) {
      Logger.error('Erro ao verificar existência de chave', e);
      return false;
    }
  }
  
  /// Obtém todas as chaves
  static Set<String> getKeys() {
    try {
      if (_prefs == null) return {};
      return _prefs!.getKeys();
    } catch (e) {
      Logger.error('Erro ao obter chaves', e);
      return {};
    }
  }
}

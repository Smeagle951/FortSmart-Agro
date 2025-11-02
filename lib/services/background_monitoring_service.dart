import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monitoring_point.dart';
import '../models/infestacao_model.dart';
import '../utils/logger.dart';

/// Serviço de persistência em segundo plano para monitoramento
/// 
/// Funcionalidades:
/// - Salvamento automático de dados
/// - Recuperação de dados após reinicialização
/// - Sincronização com servidor
/// - Cache local inteligente
class BackgroundMonitoringService {
  static const String _keyMonitoringData = 'monitoring_data';
  static const String _keyCurrentPoint = 'current_point';
  static const String _keyOccurrences = 'occurrences';
  static const String _keyNavigationState = 'navigation_state';
  
  Timer? _autoSaveTimer;
  Timer? _syncTimer;
  bool _isSaving = false;
  bool _isSyncing = false;
  
  // Callbacks
  Function()? onDataSaved;
  Function()? onDataRestored;
  Function(String error)? onError;
  
  /// Inicia o serviço de persistência em segundo plano
  Future<void> startBackgroundService({
    Function()? onDataSaved,
    Function()? onDataRestored,
    Function(String error)? onError,
  }) async {
    Logger.info('🚀 [BACKGROUND] Iniciando serviço de persistência em segundo plano');
    
    this.onDataSaved = onDataSaved;
    this.onDataRestored = onDataRestored;
    this.onError = onError;
    
    // Iniciar salvamento automático
    _startAutoSave();
    
    // Iniciar sincronização
    _startSync();
    
    // Restaurar dados salvos
    await _restoreSavedData();
  }
  
  /// Para o serviço de persistência
  void stopBackgroundService() {
    Logger.info('🛑 [BACKGROUND] Parando serviço de persistência');
    
    _autoSaveTimer?.cancel();
    _syncTimer?.cancel();
    _autoSaveTimer = null;
    _syncTimer = null;
  }
  
  /// Inicia salvamento automático
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isSaving) {
        await _performAutoSave();
      }
    });
  }
  
  /// Inicia sincronização
  void _startSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!_isSyncing) {
        await _performSync();
      }
    });
  }
  
  /// Executa salvamento automático
  Future<void> _performAutoSave() async {
    if (_isSaving) return;
    
    _isSaving = true;
    
    try {
      Logger.info('💾 [BACKGROUND] Executando salvamento automático');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar timestamp da última atualização
      await prefs.setString('last_save', DateTime.now().toIso8601String());
      
      // Aqui você pode implementar a lógica de salvamento específica
      // Por exemplo, salvar dados do formulário, imagens, etc.
      
      onDataSaved?.call();
      
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro no salvamento automático: $e');
      onError?.call('Erro no salvamento automático: $e');
    } finally {
      _isSaving = false;
    }
  }
  
  /// Executa sincronização
  Future<void> _performSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      Logger.info('🔄 [BACKGROUND] Executando sincronização');
      
      // Aqui você pode implementar a lógica de sincronização
      // Por exemplo, enviar dados para servidor, baixar atualizações, etc.
      
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro na sincronização: $e');
      onError?.call('Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Restaura dados salvos
  Future<void> _restoreSavedData() async {
    try {
      Logger.info('🔄 [BACKGROUND] Restaurando dados salvos');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar se há dados salvos
      final hasSavedData = prefs.containsKey(_keyMonitoringData);
      
      if (hasSavedData) {
        Logger.info('📱 [BACKGROUND] Dados encontrados, restaurando...');
        onDataRestored?.call();
      }
      
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro ao restaurar dados: $e');
      onError?.call('Erro ao restaurar dados: $e');
    }
  }
  
  /// Salva dados de monitoramento
  Future<void> saveMonitoringData({
    required MonitoringPoint currentPoint,
    required List<InfestacaoModel> occurrences,
    required Map<String, dynamic> navigationState,
  }) async {
    try {
      Logger.info('💾 [BACKGROUND] Salvando dados de monitoramento');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar ponto atual
      await prefs.setString(_keyCurrentPoint, jsonEncode({
        'id': currentPoint.id,
        'latitude': currentPoint.latitude,
        'longitude': currentPoint.longitude,
        'plotName': currentPoint.plotName,
        'plantasAvaliadas': currentPoint.plantasAvaliadas,
      }));
      
      // Salvar ocorrências
      final occurrencesJson = occurrences.map((occ) => {
        'id': occ.id,
        'tipo': occ.tipo,
        'organismo': occ.organismo,
        'quantidade': occ.quantidade,
        'observacao': occ.observacao,
        'dataRegistro': occ.dataRegistro.toIso8601String(),
        'latitude': occ.latitude,
        'longitude': occ.longitude,
      }).toList();
      
      await prefs.setString(_keyOccurrences, jsonEncode(occurrencesJson));
      
      // Salvar estado de navegação
      await prefs.setString(_keyNavigationState, jsonEncode(navigationState));
      
      // Salvar timestamp
      await prefs.setString('last_save', DateTime.now().toIso8601String());
      
      Logger.info('✅ [BACKGROUND] Dados salvos com sucesso');
      
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro ao salvar dados: $e');
      onError?.call('Erro ao salvar dados: $e');
    }
  }
  
  /// Restaura dados de monitoramento
  Future<Map<String, dynamic>?> restoreMonitoringData() async {
    try {
      Logger.info('🔄 [BACKGROUND] Restaurando dados de monitoramento');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar se há dados salvos
      final hasCurrentPoint = prefs.containsKey(_keyCurrentPoint);
      final hasOccurrences = prefs.containsKey(_keyOccurrences);
      final hasNavigationState = prefs.containsKey(_keyNavigationState);
      
      if (!hasCurrentPoint && !hasOccurrences && !hasNavigationState) {
        Logger.info('📱 [BACKGROUND] Nenhum dado salvo encontrado');
        return null;
      }
      
      Map<String, dynamic> restoredData = {};
      
      // Restaurar ponto atual
      if (hasCurrentPoint) {
        final pointJson = prefs.getString(_keyCurrentPoint);
        if (pointJson != null) {
          restoredData['currentPoint'] = jsonDecode(pointJson);
        }
      }
      
      // Restaurar ocorrências
      if (hasOccurrences) {
        final occurrencesJson = prefs.getString(_keyOccurrences);
        if (occurrencesJson != null) {
          restoredData['occurrences'] = jsonDecode(occurrencesJson);
        }
      }
      
      // Restaurar estado de navegação
      if (hasNavigationState) {
        final navigationJson = prefs.getString(_keyNavigationState);
        if (navigationJson != null) {
          restoredData['navigationState'] = jsonDecode(navigationJson);
        }
      }
      
      Logger.info('✅ [BACKGROUND] Dados restaurados com sucesso');
      return restoredData;
      
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro ao restaurar dados: $e');
      onError?.call('Erro ao restaurar dados: $e');
      return null;
    }
  }
  
  /// Limpa dados salvos
  Future<void> clearSavedData() async {
    try {
      Logger.info('🗑️ [BACKGROUND] Limpando dados salvos');
      
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyMonitoringData);
      await prefs.remove(_keyCurrentPoint);
      await prefs.remove(_keyOccurrences);
      await prefs.remove(_keyNavigationState);
      await prefs.remove('last_save');
      
      Logger.info('✅ [BACKGROUND] Dados limpos com sucesso');
      
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro ao limpar dados: $e');
      onError?.call('Erro ao limpar dados: $e');
    }
  }
  
  /// Verifica se há dados salvos
  Future<bool> hasSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyCurrentPoint) || 
             prefs.containsKey(_keyOccurrences) || 
             prefs.containsKey(_keyNavigationState);
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro ao verificar dados salvos: $e');
      return false;
    }
  }
  
  /// Obtém timestamp da última atualização
  Future<DateTime?> getLastSaveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSave = prefs.getString('last_save');
      
      if (lastSave != null) {
        return DateTime.parse(lastSave);
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ [BACKGROUND] Erro ao obter timestamp: $e');
      return null;
    }
  }
  
  /// Força salvamento imediato
  Future<void> forceSave() async {
    if (_isSaving) return;
    
    Logger.info('💾 [BACKGROUND] Forçando salvamento imediato');
    await _performAutoSave();
  }
  
  /// Força sincronização imediata
  Future<void> forceSync() async {
    if (_isSyncing) return;
    
    Logger.info('🔄 [BACKGROUND] Forçando sincronização imediata');
    await _performSync();
  }
}

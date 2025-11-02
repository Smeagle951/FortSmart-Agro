import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import '../utils/device_id_manager.dart';
import '../services/app_initialization_service.dart';

class AppInitializer {
  static bool _initialized = false;
  static final Completer<void> _initCompleter = Completer<void>();

  /// Inicializa a aplicação de forma assíncrona
  static Future<void> initialize() async {
    if (_initialized) {
      return _initCompleter.future;
    }

    try {
      developer.log('🚀 Iniciando aplicação...', name: 'AppInitializer');

      // 1. Inicializar serviços básicos
      await _initializeBasicServices();

      // 2. Inicializar banco de dados
      await _initializeDatabase();

      // 3. Verificar integridade do banco
      await _checkDatabaseIntegrity();

      // 4. Inicializar serviços da aplicação
      await _initializeAppServices();

      // 5. Carregar dados iniciais
      await _loadInitialData();

      _initialized = true;
      _initCompleter.complete();
      
      developer.log('✅ Aplicação inicializada com sucesso!', name: 'AppInitializer');
    } catch (e, stackTrace) {
      developer.log('❌ Erro na inicialização: $e', name: 'AppInitializer');
      developer.log('Stack trace: $stackTrace', name: 'AppInitializer');
      
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, stackTrace);
      }
      rethrow;
    }
  }

  /// Inicializa serviços básicos
  static Future<void> _initializeBasicServices() async {
    developer.log('📱 Inicializando serviços básicos...', name: 'AppInitializer');
    
    // Inicializar logger
    await Logger.initialize();
    
    // Obter device ID
    await DeviceIdManager.getDeviceId();
    
    developer.log('✅ Serviços básicos inicializados', name: 'AppInitializer');
  }

  /// Inicializa o banco de dados
  static Future<void> _initializeDatabase() async {
    developer.log('🗄️ Inicializando banco de dados...', name: 'AppInitializer');
    
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;
      
      // Verificar se o banco foi aberto corretamente
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      developer.log('📊 Tabelas encontradas: ${tables.length}', name: 'AppInitializer');
      
      developer.log('✅ Banco de dados inicializado', name: 'AppInitializer');
    } catch (e) {
      developer.log('❌ Erro ao inicializar banco: $e', name: 'AppInitializer');
      rethrow;
    }
  }

  /// Verifica a integridade do banco de dados
  static Future<void> _checkDatabaseIntegrity() async {
    developer.log('🔍 Verificando integridade do banco...', name: 'AppInitializer');
    
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;
      
      // Verificar integridade
      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      final integrity = integrityResult.first['integrity_check'] as String?;
      
      if (integrity == 'ok') {
        developer.log('✅ Integridade do banco OK', name: 'AppInitializer');
      } else {
        developer.log('⚠️ Problemas de integridade detectados: $integrity', name: 'AppInitializer');
        // Aqui você pode implementar correções automáticas se necessário
      }
    } catch (e) {
      developer.log('❌ Erro ao verificar integridade: $e', name: 'AppInitializer');
      // Não rethrow aqui, pois não é crítico para a inicialização
    }
  }

  /// Inicializa serviços da aplicação
  static Future<void> _initializeAppServices() async {
    developer.log('⚙️ Inicializando serviços da aplicação...', name: 'AppInitializer');
    
    try {
      // Inicializar serviço de inicialização da aplicação
      await AppInitializationService.initialize();
      
      developer.log('✅ Serviços da aplicação inicializados', name: 'AppInitializer');
    } catch (e) {
      developer.log('❌ Erro ao inicializar serviços: $e', name: 'AppInitializer');
      // Não rethrow aqui, pois alguns serviços podem falhar sem afetar o app
    }
  }

  /// Carrega dados iniciais
  static Future<void> _loadInitialData() async {
    developer.log('📥 Carregando dados iniciais...', name: 'AppInitializer');
    
    try {
      // Aqui você pode carregar dados essenciais como:
      // - Configurações do usuário
      // - Dados de fazenda atual
      // - Cache de mapas offline
      // - etc.
      
      developer.log('✅ Dados iniciais carregados', name: 'AppInitializer');
    } catch (e) {
      developer.log('❌ Erro ao carregar dados iniciais: $e', name: 'AppInitializer');
      // Não rethrow aqui, pois não é crítico para a inicialização
    }
  }

  /// Verifica se a aplicação foi inicializada
  static bool get isInitialized => _initialized;

  /// Aguarda a inicialização ser concluída
  static Future<void> waitForInitialization() async {
    if (_initialized) return;
    await _initCompleter.future;
  }

  /// Reseta o estado de inicialização (útil para testes)
  static void reset() {
    _initialized = false;
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  /// Obtém informações de diagnóstico
  static Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;
      
      // Informações do banco
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      final dbSize = await _getDatabaseSize();
      
      // Informações do dispositivo
      final documentsDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      
      return {
        'initialized': _initialized,
        'database': {
          'tables_count': tables.length,
          'size_bytes': dbSize,
          'path': db.path,
        },
        'device': {
          'documents_dir': documentsDir.path,
          'temp_dir': tempDir.path,
          'device_id': await DeviceIdManager.getDeviceId(),
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'initialized': _initialized,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Obtém o tamanho do banco de dados
  static Future<int> _getDatabaseSize() async {
    try {
      final dbHelper = AppDatabase();
      final db = await dbHelper.database;
      
      // Obter informações de páginas
      final pageCountResult = await db.rawQuery('PRAGMA page_count');
      final pageSizeResult = await db.rawQuery('PRAGMA page_size');
      
      final pageCount = pageCountResult.first['page_count'] as int;
      final pageSize = pageSizeResult.first['page_size'] as int;
      
      return pageCount * pageSize;
    } catch (e) {
      return 0;
    }
  }
}

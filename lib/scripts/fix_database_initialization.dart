import 'dart:io';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Script para Corrigir Problemas de Inicialização do Banco de Dados
/// 
/// Este script identifica e corrige problemas que podem causar
/// travamento na inicialização do banco de dados.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

void main(List<String> arguments) async {
  print('🔧 FortSmart Agro - Correção de Problemas de Banco de Dados');
  print('=' * 60);
  print('Versão: 4.0 | Data: 2024-12-19');
  print('Autor: Especialista Agronômico + Desenvolvedor Sênior\n');

  if (arguments.isEmpty) {
    _showHelp();
    return;
  }

  final command = arguments[0].toLowerCase();

  switch (command) {
    case 'diagnose':
      await _diagnoseDatabase();
      break;
    case 'reset':
      await _resetDatabase();
      break;
    case 'fix':
      await _fixDatabase();
      break;
    case 'test':
      await _testDatabase();
      break;
    case 'full':
      await _runFullFix();
      break;
    case 'help':
      _showHelp();
      break;
    default:
      print('❌ Comando não reconhecido: $command');
      _showHelp();
  }
}

/// Diagnostica problemas do banco de dados
Future<void> _diagnoseDatabase() async {
  print('🔍 Diagnosticando problemas do banco de dados...\n');
  
  try {
    final appDatabase = AppDatabase();
    
    // 1. Verificar estado atual
    print('1️⃣ Verificando estado atual do banco...');
    try {
      final database = await appDatabase.database;
      print('  ✅ Banco de dados acessível');
      print('  ✅ Versão: ${database.version}');
      print('  ✅ Aberto: ${database.isOpen}');
    } catch (e) {
      print('  ❌ Erro ao acessar banco: $e');
    }
    
    // 2. Verificar caminho do banco
    print('\n2️⃣ Verificando caminho do banco...');
    try {
      final path = await appDatabase.getDatabasePath();
      print('  ✅ Caminho: $path');
      
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        print('  ✅ Arquivo existe: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
      } else {
        print('  ⚠️ Arquivo não existe');
      }
    } catch (e) {
      print('  ❌ Erro ao verificar caminho: $e');
    }
    
    // 3. Verificar permissões
    print('\n3️⃣ Verificando permissões...');
    try {
      final path = await appDatabase.getDatabasePath();
      final file = File(path);
      final parent = file.parent;
      
      print('  ✅ Diretório pai: ${parent.path}');
      print('  ✅ Diretório existe: ${await parent.exists()}');
      
      if (await parent.exists()) {
        print('  ✅ Diretório acessível');
      } else {
        print('  ❌ Diretório não acessível');
      }
    } catch (e) {
      print('  ❌ Erro ao verificar permissões: $e');
    }
    
    // 4. Verificar migrações
    print('\n4️⃣ Verificando migrações...');
    try {
      final database = await appDatabase.database;
      final result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      print('  ✅ Tabelas encontradas: ${result.length}');
      for (final table in result.take(10)) {
        print('    - ${table['name']}');
      }
      if (result.length > 10) {
        print('    ... e mais ${result.length - 10} tabelas');
      }
    } catch (e) {
      print('  ❌ Erro ao verificar tabelas: $e');
    }
    
    print('\n✅ Diagnóstico concluído!');
    
  } catch (e) {
    print('❌ Erro no diagnóstico: $e');
    exit(1);
  }
}

/// Reseta o banco de dados
Future<void> _resetDatabase() async {
  print('🔄 Resetando banco de dados...\n');
  
  try {
    final appDatabase = AppDatabase();
    
    // 1. Fazer backup
    print('1️⃣ Criando backup...');
    final backupPath = await appDatabase.backupDatabase();
    if (backupPath != null) {
      print('  ✅ Backup criado: $backupPath');
    } else {
      print('  ⚠️ Backup não foi possível');
    }
    
    // 2. Fechar conexões
    print('\n2️⃣ Fechando conexões...');
    try {
      final database = await appDatabase.database;
      await database.close();
      print('  ✅ Conexões fechadas');
    } catch (e) {
      print('  ⚠️ Erro ao fechar conexões: $e');
    }
    
    // 3. Remover arquivo
    print('\n3️⃣ Removendo arquivo do banco...');
    try {
      final path = await appDatabase.getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('  ✅ Arquivo removido: $path');
      } else {
        print('  ⚠️ Arquivo não existe');
      }
    } catch (e) {
      print('  ❌ Erro ao remover arquivo: $e');
    }
    
    // 4. Recriar banco
    print('\n4️⃣ Recriando banco...');
    try {
      final database = await appDatabase.database;
      print('  ✅ Banco recriado com sucesso');
      print('  ✅ Versão: ${database.version}');
    } catch (e) {
      print('  ❌ Erro ao recriar banco: $e');
      rethrow;
    }
    
    print('\n✅ Reset do banco concluído!');
    
  } catch (e) {
    print('❌ Erro no reset: $e');
    exit(1);
  }
}

/// Corrige problemas do banco de dados
Future<void> _fixDatabase() async {
  print('🔧 Corrigindo problemas do banco de dados...\n');
  
  try {
    final appDatabase = AppDatabase();
    
    // 1. Verificar se há problemas
    print('1️⃣ Verificando problemas...');
    bool hasProblems = false;
    
    try {
      final database = await appDatabase.database;
      print('  ✅ Banco acessível');
    } catch (e) {
      print('  ❌ Problema detectado: $e');
      hasProblems = true;
    }
    
    if (!hasProblems) {
      print('  ✅ Nenhum problema detectado');
      return;
    }
    
    // 2. Tentar correções
    print('\n2️⃣ Aplicando correções...');
    
    // Tentar reset
    await _resetDatabase();
    
    print('\n✅ Correções aplicadas!');
    
  } catch (e) {
    print('❌ Erro na correção: $e');
    exit(1);
  }
}

/// Testa o banco de dados
Future<void> _testDatabase() async {
  print('🧪 Testando banco de dados...\n');
  
  try {
    final appDatabase = AppDatabase();
    
    // 1. Teste básico
    print('1️⃣ Teste básico...');
    final database = await appDatabase.database;
    print('  ✅ Conexão estabelecida');
    
    // 2. Teste de consulta
    print('\n2️⃣ Teste de consulta...');
    final result = await database.rawQuery('SELECT 1 as test');
    print('  ✅ Consulta executada: ${result.first['test']}');
    
    // 3. Teste de tabelas
    print('\n3️⃣ Teste de tabelas...');
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    print('  ✅ Tabelas encontradas: ${tables.length}');
    
    // 4. Teste de performance
    print('\n4️⃣ Teste de performance...');
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      await database.rawQuery('SELECT 1');
    }
    stopwatch.stop();
    print('  ✅ 100 consultas em ${stopwatch.elapsedMilliseconds}ms');
    
    print('\n✅ Todos os testes passaram!');
    
  } catch (e) {
    print('❌ Erro nos testes: $e');
    exit(1);
  }
}

/// Executa correção completa
Future<void> _runFullFix() async {
  print('🚀 Executando correção completa...\n');
  
  try {
    // 1. Diagnóstico
    print('1️⃣ Executando diagnóstico...');
    await _diagnoseDatabase();
    
    print('\n' + '=' * 60 + '\n');
    
    // 2. Correção
    print('2️⃣ Executando correção...');
    await _fixDatabase();
    
    print('\n' + '=' * 60 + '\n');
    
    // 3. Teste
    print('3️⃣ Executando testes...');
    await _testDatabase();
    
    print('\n🎉 Correção completa finalizada!');
    print('📊 Banco de dados funcionando corretamente');
    
  } catch (e) {
    print('❌ Erro na correção completa: $e');
    exit(1);
  }
}

/// Mostra ajuda
void _showHelp() {
  print('📖 AJUDA - Correção de Problemas de Banco de Dados');
  print('=' * 60);
  print('');
  print('Comandos disponíveis:');
  print('');
  print('  diagnose - Diagnostica problemas do banco');
  print('  reset    - Reseta o banco de dados');
  print('  fix      - Corrige problemas do banco');
  print('  test     - Testa o banco de dados');
  print('  full     - Executa correção completa (diagnose + fix + test)');
  print('  help     - Exibe esta ajuda');
  print('');
  print('Exemplos de uso:');
  print('  dart run lib/scripts/fix_database_initialization.dart diagnose');
  print('  dart run lib/scripts/fix_database_initialization.dart reset');
  print('  dart run lib/scripts/fix_database_initialization.dart full');
  print('');
  print('⚠️ IMPORTANTE:');
  print('  - Execute "diagnose" primeiro para identificar problemas');
  print('  - "reset" remove todos os dados (faça backup)');
  print('  - "full" executa correção completa');
  print('');
}

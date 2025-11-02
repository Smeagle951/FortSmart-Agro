import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// Utilitário para limpar e recriar o banco de dados corrompido
class DatabaseCleanup {

  /// Limpa completamente o banco de dados e força a recriação
  static Future<bool> cleanupDatabase() async {
    try {
      print('Iniciando limpeza do banco de dados...');

      // Obter o caminho do banco de dados unificado
      final dbPath = await AppDatabase.instance.getDatabasePath();

      // Verificar se o arquivo existe
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        // Criar backup antes de excluir
        final backupPath = '$dbPath.backup_${DateTime.now().millisecondsSinceEpoch}';
        await dbFile.copy(backupPath);
        print('Backup criado em: $backupPath');
        
        // Excluir o arquivo do banco de dados
        await dbFile.delete();
        print('Arquivo do banco de dados excluído');
      }
      
      // Verificar se há arquivos WAL ou SHM (modo WAL)
      final walFile = File('$dbPath-wal');
      final shmFile = File('$dbPath-shm');
      
      if (await walFile.exists()) {
        await walFile.delete();
        print('Arquivo WAL excluído');
      }
      
      if (await shmFile.exists()) {
        await shmFile.delete();
        print('Arquivo SHM excluído');
      }
      
      print('Limpeza do banco de dados concluída com sucesso');
      return true;
    } catch (e) {
      print('Erro durante a limpeza do banco de dados: $e');
      return false;
    }
  }
  
  /// Verifica se o banco de dados está corrompido
  static Future<bool> isDatabaseCorrupted() async {
    try {
      final dbPath = await AppDatabase.instance.getDatabasePath();
      
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        return false; // Não está corrompido, apenas não existe
      }
      
      // Tentar abrir o banco de dados
      final db = await openDatabase(dbPath, readOnly: true);
      await db.close();
      
      return false; // Banco de dados está íntegro
    } catch (e) {
      print('Banco de dados corrompido detectado: $e');
      return true;
    }
  }
  
  /// Força a recriação do banco de dados
  static Future<bool> forceRecreateDatabase() async {
    try {
      print('Forçando recriação do banco de dados...');
      
      // Limpar o banco de dados existente
      final cleaned = await cleanupDatabase();
      if (!cleaned) {
        print('Falha ao limpar banco de dados');
        return false;
      }
      
      // Aguardar um pouco para garantir que os arquivos foram liberados
      await Future.delayed(Duration(milliseconds: 500));
      
      print('Recriação do banco de dados concluída');
      return true;
    } catch (e) {
      print('Erro durante recriação do banco de dados: $e');
      return false;
    }
  }
  
  /// Obtém informações sobre o banco de dados
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final dbPath = await AppDatabase.instance.getDatabasePath();
      
      final dbFile = File(dbPath);
      final walFile = File('$dbPath-wal');
      final shmFile = File('$dbPath-shm');
      
      return {
        'exists': await dbFile.exists(),
        'size': await dbFile.exists() ? await dbFile.length() : 0,
        'walExists': await walFile.exists(),
        'shmExists': await shmFile.exists(),
        'path': dbPath,
        'isCorrupted': await isDatabaseCorrupted(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isCorrupted': true,
      };
    }
  }
} 
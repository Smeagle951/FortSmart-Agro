import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';
import '../database/app_database.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

class BackupService {
  static final BackupService _instance = BackupService._internal();
  final AppDatabase _database = AppDatabase();
  
  factory BackupService() {
    return _instance;
  }
  
  BackupService._internal();
  
  // Diretório para armazenar os backups
  static const String _backupDir = 'backups';
  
  // Inicializa o diretório de backups
  Future<void> init() async {
    await _createBackupDirectory();
  }
  
  // Cria o diretório de backups se ele não existir
  // CORREÇÃO: Salvar em pasta externa que persiste após desinstalar o app
  Future<Directory> _createBackupDirectory() async {
    try {
      // CORREÇÃO CRÍTICA: Usar pasta Downloads ou External Storage que persiste após desinstalar
      Directory? directory;
      
      if (Platform.isAndroid) {
        // No Android, tentar salvar em Downloads (persiste após desinstalar)
        directory = Directory('/storage/emulated/0/Download/FortSmartAgro/Backups');
        
        // Se não conseguir acessar Downloads, usar External Storage
        if (!await directory.exists()) {
          try {
            await directory.create(recursive: true);
          } catch (e) {
            print('⚠️ Não foi possível criar diretório em Downloads: $e');
            // Fallback para getExternalStorageDirectory
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              directory = Directory(path.join(externalDir.path, _backupDir));
            } else {
              // Último fallback: usar diretório de documentos do app
              final appDocDir = await getApplicationDocumentsDirectory();
              directory = Directory(path.join(appDocDir.path, _backupDir));
            }
          }
        }
      } else {
        // No iOS, usar diretório de documentos do app (iOS não permite salvar em Downloads)
        final appDocDir = await getApplicationDocumentsDirectory();
        directory = Directory(path.join(appDocDir.path, _backupDir));
      }
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      print('✅ Diretório de backup: ${directory.path}');
      return directory;
    } catch (e) {
      print('❌ Erro ao criar diretório de backup: $e');
      // Fallback: usar diretório de documentos do app
      final appDocDir = await getApplicationDocumentsDirectory();
      final directory = Directory(path.join(appDocDir.path, _backupDir));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
  }
  
  // Cria um backup do banco de dados
  Future<String?> createBackup({String? customName}) async {
    Database? db;
    try {
      print('🔄 [BACKUP] Iniciando criação de backup...');
      
      // Obter estatísticas ANTES de fechar o banco
      db = await _database.database;
      final stats = await _getBackupStats();
      print('📊 [BACKUP] Estatísticas coletadas: ${stats.toString()}');
      
      // Obter o caminho do banco de dados ANTES de fechar
      final dbPath = await getDatabasesPath();
      final dbFile = path.join(dbPath, AppDatabase.databaseName);
      print('📁 [BACKUP] Caminho do banco: $dbFile');
      
      // Verificar se o arquivo do banco de dados existe
      if (!await File(dbFile).exists()) {
        print('❌ [BACKUP] Arquivo do banco de dados não encontrado: $dbFile');
        throw Exception('Arquivo do banco de dados não encontrado');
      }
      
      // Fechar o banco de dados para garantir que todas as transações estejam completas
      print('🔒 [BACKUP] Fechando banco de dados...');
      await db.close();
      db = null; // Marcar como fechado
      
      // Criar nome do arquivo de backup
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = customName != null 
          ? '${customName}_$timestamp.zip' 
          : 'fortsmartagro_backup_$timestamp.zip';
      
      // Obter diretório de backup
      print('📂 [BACKUP] Criando diretório de backup...');
      final backupDir = await _createBackupDirectory();
      final backupPath = path.join(backupDir.path, backupFileName);
      print('📂 [BACKUP] Caminho do backup: $backupPath');
      
      // Verificar se o diretório existe e tem permissão de escrita
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
        print('✅ [BACKUP] Diretório criado: ${backupDir.path}');
      }
      
      // Verificar permissão de escrita
      try {
        final testFile = File(path.join(backupDir.path, 'test_write.tmp'));
        await testFile.writeAsString('test');
        await testFile.delete();
        print('✅ [BACKUP] Permissão de escrita confirmada');
      } catch (e) {
        print('⚠️ [BACKUP] Sem permissão de escrita em ${backupDir.path}, tentando fallback...');
        // Fallback para diretório do app
        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory(path.join(appDocDir.path, _backupDir));
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        final fallbackPath = path.join(fallbackDir.path, backupFileName);
        print('📂 [BACKUP] Usando fallback: $fallbackPath');
        throw Exception('Redirecionando para fallback');
      }
      
      // Ler arquivo do banco de dados
      print('📖 [BACKUP] Lendo arquivo do banco de dados...');
      final dbBytes = await File(dbFile).readAsBytes();
      print('📊 [BACKUP] Tamanho do banco: ${(dbBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // Criar um arquivo zip para o backup
      print('📦 [BACKUP] Criando arquivo ZIP...');
      final archive = Archive();
      archive.addFile(
        ArchiveFile(
          path.basename(dbFile), 
          dbBytes.length, 
          dbBytes
        )
      );
      
      // Adicionar informações sobre o backup
      final infoContent = 'Backup criado em: ${DateTime.now().toIso8601String()}\n'
          'Versão do aplicativo: 1.0.0\n'
          'Dispositivo: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
          'Tabelas incluídas: talhoes, safras, poligonos, plantios, estande_plantas, monitorings, '
          'pontos_monitoramento, culturas, crop_varieties, agricultural_products, '
          'germination_tests, germination_subtests, germination_daily_records, '
          'inventory_products, calibration_history, phenological_records, occurrences, '
          'monitoring_sessions, monitoring_points, monitoring_occurrences, infestation_map, catalog_organisms\n\n'
          'Estatísticas:\n'
          '- Talhões: ${stats['talhoes']}\n'
          '- Safras: ${stats['safras']}\n'
          '- Plantios: ${stats['plantios']}\n'
          '- Monitoramentos: ${stats['monitorings']}\n'
          '- Culturas: ${stats['culturas']}\n'
          '- Produtos Agrícolas: ${stats['agricultural_products']}\n'
          '- Catálogo de Organismos: ${stats['catalog_organisms']}\n';
      
      archive.addFile(
        ArchiveFile(
          'backup_info.txt', 
          utf8.encode(infoContent).length, 
          utf8.encode(infoContent)
        )
      );
      
      // Salvar o arquivo zip
      print('💾 [BACKUP] Salvando arquivo ZIP...');
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null || zipData.isEmpty) {
        throw Exception('Falha ao criar arquivo zip: dados zip vazios');
      }
      
      print('💾 [BACKUP] Escrevendo ${(zipData.length / 1024 / 1024).toStringAsFixed(2)} MB...');
      final backupFile = File(backupPath);
      await backupFile.writeAsBytes(zipData);
      
      // Verificar se o arquivo foi criado
      if (!await backupFile.exists()) {
        throw Exception('Arquivo de backup não foi criado');
      }
      
      final fileSize = await backupFile.length();
      print('✅ [BACKUP] Arquivo criado com sucesso: $backupPath (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      
      // Reabrir o banco de dados
      print('🔓 [BACKUP] Reabrindo banco de dados...');
      await _database.database;
      
      return backupPath;
    } catch (e, stackTrace) {
      print('❌ [BACKUP] Erro ao criar backup: $e');
      print('❌ [BACKUP] Stack trace: $stackTrace');
      
      // Garantir que o banco de dados seja reaberto em caso de erro
      try {
        if (db != null && db.isOpen) {
          await db.close();
        }
        await _database.database;
        print('✅ [BACKUP] Banco de dados reaberto após erro');
      } catch (reopenError) {
        print('❌ [BACKUP] Erro ao reabrir banco: $reopenError');
      }
      
      return null;
    }
  }
  
  // Obtém estatísticas para incluir no backup
  Future<Map<String, int>> _getBackupStats() async {
    final db = await _database.database;
    final stats = <String, int>{};
    
    try {
      // Contar talhões
      final talhoesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM talhoes')
      ) ?? 0;
      stats['talhoes'] = talhoesCount;
      
      // Contar safras
      final safrasCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM safras')
      ) ?? 0;
      stats['safras'] = safrasCount;
      
      // Contar plantios
      final plantiosCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM plantios')
      ) ?? 0;
      stats['plantios'] = plantiosCount;
      
      // Contar monitoramentos
      final monitoringsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitorings')
      ) ?? 0;
      stats['monitorings'] = monitoringsCount;
      
      // Contar culturas
      final culturasCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM culturas')
      ) ?? 0;
      stats['culturas'] = culturasCount;
      
      // Contar produtos agrícolas
      final productsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM agricultural_products')
      ) ?? 0;
      stats['agricultural_products'] = productsCount;
      
      // Contar organismos do catálogo
      try {
        final organismsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM catalog_organisms')
        ) ?? 0;
        stats['catalog_organisms'] = organismsCount;
      } catch (e) {
        stats['catalog_organisms'] = 0;
      }
      
    } catch (e) {
      print('❌ Erro ao obter estatísticas: $e');
      // Definir valores padrão em caso de erro
      stats['talhoes'] = 0;
      stats['safras'] = 0;
      stats['plantios'] = 0;
      stats['monitorings'] = 0;
      stats['culturas'] = 0;
      stats['agricultural_products'] = 0;
      stats['catalog_organisms'] = 0;
    }
    
    return stats;
  }
  
  // Exporta apenas os dados de culturas e catálogo de organismos
  Future<String?> exportCropData({String? customName}) async {
    try {
      final db = await _database.database;
      
      // Criar nome do arquivo de exportação
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFileName = customName != null 
          ? '${customName}_$timestamp.zip' 
          : 'fortsmartagro_crop_export_$timestamp.zip';
      
      // Obter diretório de backup
      final backupDir = await _createBackupDirectory();
      final exportPath = path.join(backupDir.path, exportFileName);
      
      // Criar um arquivo zip para a exportação
      final archive = Archive();
      
      // Obter dados de culturas
      try {
        final culturas = await db.query('culturas');
        final culturasJson = json.encode(culturas);
        
        archive.addFile(
          ArchiveFile(
            'culturas.json', 
            culturasJson.length, 
            culturasJson.codeUnits
          )
        );
      } catch (e) {
        print('⚠️ Erro ao exportar culturas: $e');
      }
      
      // Obter dados de variedades de culturas
      try {
        final cropVarieties = await db.query('crop_varieties');
        final cropVarietiesJson = json.encode(cropVarieties);
        
        archive.addFile(
          ArchiveFile(
            'crop_varieties.json', 
            cropVarietiesJson.length, 
            cropVarietiesJson.codeUnits
          )
        );
      } catch (e) {
        print('⚠️ Erro ao exportar variedades: $e');
      }
      
      // Obter dados de produtos agrícolas
      try {
        final agriculturalProducts = await db.query('agricultural_products');
        final productsJson = json.encode(agriculturalProducts);
        
        archive.addFile(
          ArchiveFile(
            'agricultural_products.json', 
            productsJson.length, 
            productsJson.codeUnits
          )
        );
      } catch (e) {
        print('⚠️ Erro ao exportar produtos agrícolas: $e');
      }
      
      // Obter dados do catálogo de organismos
      try {
        final catalogOrganisms = await db.query('catalog_organisms');
        final organismsJson = json.encode(catalogOrganisms);
        
        archive.addFile(
          ArchiveFile(
            'catalog_organisms.json', 
            organismsJson.length, 
            organismsJson.codeUnits
          )
        );
      } catch (e) {
        print('⚠️ Erro ao exportar catálogo de organismos: $e');
      }
      
      // Adicionar informações sobre a exportação
      final stats = await _getBackupStats();
      final infoContent = 'Exportação criada em: ${DateTime.now().toIso8601String()}\n'
          'Versão do aplicativo: 1.0.0\n'
          'Dispositivo: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n\n'
          'Estatísticas:\n'
          '- Culturas: ${stats['culturas']}\n'
          '- Produtos Agrícolas: ${stats['agricultural_products']}\n'
          '- Catálogo de Organismos: ${stats['catalog_organisms']}\n';
      
      archive.addFile(
        ArchiveFile(
          'export_info.txt', 
          infoContent.length, 
          infoContent.codeUnits
        )
      );
      
      // Salvar o arquivo zip
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await File(exportPath).writeAsBytes(zipData);
      } else {
        throw Exception('Falha ao criar arquivo zip');
      }
      
      return exportPath;
    } catch (e) {
      print('❌ Erro ao exportar dados: $e');
      return null;
    }
  }
  
  // Importa dados de culturas e catálogo de organismos
  Future<bool> importCropData(String exportPath) async {
    try {
      // Verificar se o arquivo de exportação existe
      if (!await File(exportPath).exists()) {
        throw Exception('Arquivo de exportação não encontrado');
      }
      
      // Ler o arquivo de exportação
      final bytes = await File(exportPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final db = await _database.database;
      await db.transaction((txn) async {
        // Importar culturas
        final culturasFile = archive.findFile('culturas.json');
        if (culturasFile != null) {
          final culturasContent = String.fromCharCodes(culturasFile.content as List<int>);
          final List<dynamic> culturasData = _parseJsonList(culturasContent);
          
          for (final culturaData in culturasData) {
            try {
              // Verificar se a cultura já existe
              final existing = await txn.query(
                'culturas',
                where: 'id = ?',
                whereArgs: [culturaData['id']],
              );
              
              if (existing.isEmpty) {
                // Se não existir, inserir
                await txn.insert('culturas', Map<String, dynamic>.from(culturaData));
              }
            } catch (e) {
              print('⚠️ Erro ao importar cultura: $e');
            }
          }
        }
        
        // Importar variedades de culturas
        final cropVarietiesFile = archive.findFile('crop_varieties.json');
        if (cropVarietiesFile != null) {
          final varietiesContent = String.fromCharCodes(cropVarietiesFile.content as List<int>);
          final List<dynamic> varietiesData = _parseJsonList(varietiesContent);
          
          for (final varietyData in varietiesData) {
            try {
              final existing = await txn.query(
                'crop_varieties',
                where: 'id = ?',
                whereArgs: [varietyData['id']],
              );
              
              if (existing.isEmpty) {
                await txn.insert('crop_varieties', Map<String, dynamic>.from(varietyData));
              }
            } catch (e) {
              print('⚠️ Erro ao importar variedade: $e');
            }
          }
        }
        
        // Importar produtos agrícolas
        final productsFile = archive.findFile('agricultural_products.json');
        if (productsFile != null) {
          final productsContent = String.fromCharCodes(productsFile.content as List<int>);
          final List<dynamic> productsData = _parseJsonList(productsContent);
          
          for (final productData in productsData) {
            try {
              final existing = await txn.query(
                'agricultural_products',
                where: 'id = ?',
                whereArgs: [productData['id']],
              );
              
              if (existing.isEmpty) {
                await txn.insert('agricultural_products', Map<String, dynamic>.from(productData));
              }
            } catch (e) {
              print('⚠️ Erro ao importar produto agrícola: $e');
            }
          }
        }
        
        // Importar catálogo de organismos
        final organismsFile = archive.findFile('catalog_organisms.json');
        if (organismsFile != null) {
          final organismsContent = String.fromCharCodes(organismsFile.content as List<int>);
          final List<dynamic> organismsData = _parseJsonList(organismsContent);
          
          for (final organismData in organismsData) {
            try {
              final existing = await txn.query(
                'catalog_organisms',
                where: 'id = ?',
                whereArgs: [organismData['id']],
              );
              
              if (existing.isEmpty) {
                await txn.insert('catalog_organisms', Map<String, dynamic>.from(organismData));
              }
            } catch (e) {
              print('⚠️ Erro ao importar organismo: $e');
            }
          }
        }
      });
      
      return true;
    } catch (e) {
      print('❌ Erro ao importar dados: $e');
      return false;
    }
  }
  
  // Converte uma string JSON para uma lista de mapas
  List<dynamic> _parseJsonList(String jsonString) {
    // Remover caracteres indesejados e formatar corretamente
    String cleanJson = jsonString.trim();
    
    // Se a string começar e terminar com colchetes, considerar como uma lista JSON válida
    if (cleanJson.startsWith('[') && cleanJson.endsWith(']')) {
      try {
        return json.decode(cleanJson);
      } catch (e) {
        print('Erro ao analisar JSON: $e');
        return [];
      }
    }
    
    // Caso contrário, tentar analisar como uma lista de mapas em formato de string
    try {
      // Dividir a string em linhas
      final lines = cleanJson.split('\n');
      final List<dynamic> result = [];
      
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          try {
            final map = json.decode(line);
            result.add(map);
          } catch (e) {
            // Ignorar linhas que não podem ser analisadas
          }
        }
      }
      
      return result;
    } catch (e) {
      print('Erro ao analisar lista de JSON: $e');
      return [];
    }
  }
  
  // Restaura um backup
  Future<bool> restoreBackup(String backupPath) async {
    try {
      // Verificar se o arquivo de backup existe
      if (!await File(backupPath).exists()) {
        throw Exception('Arquivo de backup não encontrado');
      }
      
      // Fechar o banco de dados
      final db = await _database.database;
      await db.close();
      
      // Ler o arquivo de backup
      final bytes = await File(backupPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Encontrar o arquivo do banco de dados no arquivo zip
      final dbFile = archive.findFile(AppDatabase.databaseName);
      if (dbFile == null) {
        throw Exception('Arquivo de banco de dados não encontrado no backup');
      }
      
      // Obter o caminho do banco de dados
      final dbPath = await getDatabasesPath();
      final dbFilePath = path.join(dbPath, AppDatabase.databaseName);
      
      // Extrair e salvar o banco de dados
      await File(dbFilePath).writeAsBytes(dbFile.content as List<int>);
      
      // Reabrir o banco de dados
      await _database.database;
      
      return true;
    } catch (e) {
      print('Erro ao restaurar backup: $e');
      // Garantir que o banco de dados seja reaberto em caso de erro
      await _database.database;
      return false;
    }
  }
  
  // Lista todos os backups disponíveis
  Future<List<BackupFile>> listBackups() async {
    try {
      final backupDir = await _createBackupDirectory();
      final List<BackupFile> backups = [];
      
      await for (FileSystemEntity entity in backupDir.list()) {
        if (entity is File && entity.path.endsWith('.zip')) {
          final stat = await entity.stat();
          backups.add(BackupFile(
            fileName: path.basename(entity.path),
            filePath: entity.path,
            createdAt: stat.modified,
            sizeInBytes: stat.size,
          ));
        }
      }
      
      // Ordenar por data de criação (mais recente primeiro)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return backups;
    } catch (e) {
      print('Erro ao listar backups: $e');
      return [];
    }
  }
  
  // Obtém a lista de arquivos de backup (alias para listBackups)
  Future<List<BackupFile>> getBackupFiles() async {
    return await listBackups();
  }
  
  // Exclui um backup
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao excluir backup: $e');
      return false;
    }
  }
  
  // Configura backup automático
  Future<void> configureAutoBackup({
    required bool enabled,
    required int intervalDays,
    required int maxBackups,
  }) async {
    final db = await _database.database;
    
    // Salvar configurações
    await db.delete('backup_settings');
    await db.insert('backup_settings', {
      'auto_backup_enabled': enabled ? 1 : 0,
      'interval_days': intervalDays,
      'max_backups': maxBackups,
      'last_auto_backup': DateTime.now().toIso8601String(),
    });
  }
  
  // Verifica e executa backup automático se necessário
  Future<bool> checkAndRunAutoBackup() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> settings = await db.query('backup_settings');
      
      if (settings.isEmpty) {
        return false;
      }
      
      final enabled = settings.first['auto_backup_enabled'] == 1;
      if (!enabled) {
        return false;
      }
      
      final intervalDays = settings.first['interval_days'] as int;
      final lastBackup = DateTime.parse(settings.first['last_auto_backup'] as String);
      final now = DateTime.now();
      
      if (now.difference(lastBackup).inDays >= intervalDays) {
        // Criar backup automático
        final backupPath = await createBackup(customName: 'auto');
        
        if (backupPath != null) {
          // Atualizar data do último backup
          await db.update(
            'backup_settings',
            {'last_auto_backup': now.toIso8601String()},
          );
          
          // Limitar número de backups automáticos
          await _limitBackups(settings.first['max_backups'] as int);
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Erro ao verificar backup automático: $e');
      return false;
    }
  }
  
  // Limita o número de backups automáticos
  Future<void> _limitBackups(int maxBackups) async {
    try {
      final backups = await listBackups();
      final autoBackups = backups.where((b) => b.fileName.startsWith('auto_')).toList();
      
      if (autoBackups.length > maxBackups) {
        // Excluir backups mais antigos
        for (int i = maxBackups; i < autoBackups.length; i++) {
          await deleteBackup(autoBackups[i].filePath);
        }
      }
    } catch (e) {
      print('Erro ao limitar backups: $e');
    }
  }
}

// Classe para representar informações de um backup
class BackupFile {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int sizeInBytes;

  BackupFile({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.sizeInBytes,
  });
}

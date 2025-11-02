import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/estande_plantas_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EstandePlantasRepository {
  static const String tableName = 'estande_plantas';

  // Método para criar a tabela se não existir
  Future<void> createTableIfNotExists() async {
    final db = await AppDatabase.instance.database;
    
    // Verifica se a tabela já existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );
    
    if (tables.isEmpty) {
      // Cria a tabela se não existir
      await db.execute('''
        CREATE TABLE $tableName (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          data_emergencia TEXT,
          data_avaliacao TEXT,
          dias_apos_emergencia INTEGER,
          metros_lineares_medidos REAL,
          plantas_contadas INTEGER,
          espacamento REAL,
          plantas_por_metro REAL,
          plantas_por_hectare REAL,
          populacao_ideal REAL,
          eficiencia REAL,
          fotos TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0
        )
      ''');
      
      print('Tabela $tableName criada com sucesso!');
    } else {
      // Verifica se as colunas necessárias existem e as adiciona se necessário
      await _verificarEAdicionarColunas(db);
    }
  }

  // Método privado para verificar e adicionar colunas faltantes
  Future<void> _verificarEAdicionarColunas(Database db) async {
    try {
      // Obtém todas as colunas existentes na tabela
      final tableInfo = await db.rawQuery("PRAGMA table_info($tableName)");
      final columns = tableInfo.map((col) => col['name']).toList();
      
      // Lista de colunas necessárias com seus tipos
      final Map<String, String> colunasNecessarias = {
        'id': 'TEXT PRIMARY KEY',
        'talhao_id': 'TEXT NOT NULL',
        'cultura_id': 'TEXT NOT NULL',
        'data_emergencia': 'TEXT',
        'data_avaliacao': 'TEXT',
        'dias_apos_emergencia': 'INTEGER',
        'metros_lineares_medidos': 'REAL',
        'plantas_contadas': 'INTEGER',
        'espacamento': 'REAL',
        'plantas_por_metro': 'REAL',
        'plantas_por_hectare': 'REAL',
        'populacao_ideal': 'REAL',
        'eficiencia': 'REAL',
        'fotos': 'TEXT',
        'created_at': 'TEXT NOT NULL',
        'updated_at': 'TEXT NOT NULL',
        'sync_status': 'INTEGER DEFAULT 0',
      };
      
      // Adiciona colunas que não existem
      for (final entry in colunasNecessarias.entries) {
        if (!columns.contains(entry.key)) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN ${entry.key} ${entry.value}'
          );
          print('Coluna ${entry.key} adicionada à tabela $tableName');
        }
      }
      
      // Remove colunas antigas em camelCase se existirem
      final colunasAntigas = ['talhaoId', 'culturaId', 'dataEmergencia', 'dataAvaliacao', 
                              'diasAposEmergencia', 'metrosLinearesMedidos', 'plantasContadas',
                              'espacamento', 'plantasPorMetro', 'plantasPorHectare',
                              'populacaoIdeal', 'eficiencia', 'criadoEm', 'atualizadoEm',
                              'sincronizado'];
      
      for (final colunaAntiga in colunasAntigas) {
        if (columns.contains(colunaAntiga)) {
          print('Coluna antiga em camelCase encontrada: $colunaAntiga');
          // SQLite não suporta DROP COLUMN diretamente, então apenas registramos
          print('AVISO: Coluna $colunaAntiga está em camelCase e pode causar conflitos');
        }
      }
    } catch (e) {
      print('Erro ao verificar/adicionar colunas: $e');
    }
  }

  // Método para salvar um estande de plantas
  Future<String> salvar(EstandePlantasModel estande) async {
    await createTableIfNotExists();
    final db = await AppDatabase.instance.database;
    
    // Processa as fotos para salvar permanentemente
    final List<String> fotosSalvas = await _salvarFotosPermanentes(estande.fotos);
    estande = estande.copyWith(fotos: fotosSalvas);
    
    // Atualiza a data de modificação
    estande = estande.copyWith(updatedAt: DateTime.now());
    
    // Verifica se o registro já existe
    final existingRecord = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [estande.id],
    );
    
    if (existingRecord.isNotEmpty) {
      // Atualiza o registro existente
      await db.update(
        tableName,
        estande.toMap(),
        where: 'id = ?',
        whereArgs: [estande.id],
      );
    } else {
      // Insere um novo registro
      await db.insert(
        tableName,
        estande.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    return estande.id!;
  }

  // Método para buscar todos os registros
  Future<List<EstandePlantasModel>> buscarTodos() async {
    await createTableIfNotExists();
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return EstandePlantasModel.fromMap(maps[i]);
    });
  }

  // Método para buscar por ID
  Future<EstandePlantasModel?> buscarPorId(String id) async {
    await createTableIfNotExists();
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return EstandePlantasModel.fromMap(maps.first);
    }
    
    return null;
  }

  // Método para buscar por talhão
  Future<List<EstandePlantasModel>> buscarPorTalhao(String talhaoId) async {
    await createTableIfNotExists();
    final db = await AppDatabase.instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return EstandePlantasModel.fromMap(maps[i]);
    });
  }

  // Método para buscar o registro mais recente por talhão e cultura
  Future<EstandePlantasModel?> getLatestByTalhaoAndCultura(String talhaoId, String culturaId) async {
    await createTableIfNotExists();
    final db = await AppDatabase.instance.database;
    
    // 🔍 Normalizar IDs para evitar problemas de match
    final talhaoIdNorm = talhaoId.trim();
    final culturaIdNorm = culturaId.trim();
    
    print('📊 ESTANDE REPO: Buscando estande');
    print('   - Talhão solicitado: "$talhaoIdNorm"');
    print('   - Cultura solicitada: "$culturaIdNorm"');
    
    // ✅ ESTRATÉGIA 1: Busca exata
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'talhao_id = ? AND cultura_id = ?',
      whereArgs: [talhaoIdNorm, culturaIdNorm],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    print('   - Estratégia 1 (exata): ${maps.length} resultado(s)');
    
    // ✅ ESTRATÉGIA 2: Case-insensitive
    if (maps.isEmpty) {
      maps = await db.query(
        tableName,
        where: 'LOWER(TRIM(talhao_id)) = ? AND LOWER(TRIM(cultura_id)) = ?',
        whereArgs: [talhaoIdNorm.toLowerCase(), culturaIdNorm.toLowerCase()],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      print('   - Estratégia 2 (case-insensitive): ${maps.length} resultado(s)');
    }
    
    // ✅ ESTRATÉGIA 3: Buscar por talhão E cultura (ignorando prefixo "custom_")
    if (maps.isEmpty) {
      print('   - Estratégia 3: Buscando com cultura normalizada (removendo "custom_")...');
      final culturaSemPrefixo = culturaIdNorm.toLowerCase().replaceAll('custom_', '');
      maps = await db.query(
        tableName,
        where: 'talhao_id = ? AND (LOWER(TRIM(REPLACE(cultura_id, "custom_", ""))) = ? OR LOWER(TRIM(cultura_id)) = ?)',
        whereArgs: [talhaoIdNorm, culturaSemPrefixo, culturaSemPrefixo],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      print('   - Estratégia 3 (ignorando prefixo): ${maps.length} resultado(s)');
    }
    
    // ✅ ESTRATÉGIA 4: Buscar apenas por talhão (última tentativa)
    if (maps.isEmpty) {
      print('   - Estratégia 4: Buscando apenas por talhão...');
      maps = await db.query(
        tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoIdNorm],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      print('   - Estratégia 4 (só talhão): ${maps.length} resultado(s)');
      
      if (maps.isNotEmpty) {
        final estandeCultura = maps.first['cultura_id'];
        print('   ⚠️ ATENÇÃO: Encontrado estande com cultura diferente: "$estandeCultura"');
        print('   💡 DICA: Plantio usa "$culturaIdNorm", estande usa "$estandeCultura"');
      }
    }
    
    // 🔍 DEBUG: Mostrar todos os estandes se nada foi encontrado
    if (maps.isEmpty) {
      final todosEstandes = await db.query(tableName, orderBy: 'created_at DESC', limit: 10);
      print('   ❌ NENHUM ESTANDE ENCONTRADO!');
      print('   📋 Últimos 10 estandes cadastrados:');
      for (var e in todosEstandes) {
        print('      - ID: ${e['id']}');
        print('        Talhão: "${e['talhao_id']}"');
        print('        Cultura: "${e['cultura_id']}"');
        print('        População: ${e['plantas_por_hectare']} plantas/ha');
        print('        Data: ${e['data_avaliacao']}');
        print('        ---');
      }
    }
    
    if (maps.isNotEmpty) {
      print('   ✅ ESTANDE ENCONTRADO!');
      final estande = EstandePlantasModel.fromMap(maps.first);
      print('      - ID: ${estande.id}');
      print('      - Talhão no banco: "${estande.talhaoId}"');
      print('      - Cultura no banco: "${estande.culturaId}"');
      print('      - População: ${estande.plantasPorHectare} plantas/ha');
      print('      - Eficiência: ${estande.eficiencia}%');
      return estande;
    }
    
    return null;
  }

  // Método para excluir um registro
  Future<int> excluir(String id) async {
    await createTableIfNotExists();
    final db = await AppDatabase.instance.database;
    
    // Busca o registro para excluir as fotos
    final estande = await buscarPorId(id);
    if (estande != null) {
      // Exclui as fotos do armazenamento
      for (final foto in estande.fotos) {
        final file = File(foto);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método privado para salvar fotos permanentemente
  Future<List<String>> _salvarFotosPermanentes(List<String> fotos) async {
    final List<String> fotosSalvas = [];
    
    // Se não houver fotos, retorna a lista vazia
    if (fotos.isEmpty) return fotosSalvas;
    
    try {
      // Obtém o diretório de documentos do aplicativo
      final appDocDir = await getApplicationDocumentsDirectory();
      final String fotosDir = path.join(appDocDir.path, 'estande_plantas_fotos');
      
      // Cria o diretório se não existir
      final dir = Directory(fotosDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Processa cada foto
      for (final fotoPath in fotos) {
        final File fotoFile = File(fotoPath);
        
        // Verifica se o arquivo já está no diretório permanente
        if (fotoPath.contains(fotosDir)) {
          fotosSalvas.add(fotoPath);
          continue;
        }
        
        // Se o arquivo existir, salva permanentemente
        if (await fotoFile.exists()) {
          final String fileName = path.basename(fotoPath);
          final String newPath = path.join(fotosDir, fileName);
          
          // Copia o arquivo para o diretório permanente
          await fotoFile.copy(newPath);
          fotosSalvas.add(newPath);
          
          // Exclui o arquivo temporário se estiver em um diretório temporário
          if (fotoPath.contains('temp') || fotoPath.contains('cache')) {
            await fotoFile.delete().catchError((e) => print('Erro ao excluir arquivo temporário: $e'));
          }
        }
      }
    } catch (e) {
      print('Erro ao salvar fotos permanentemente: $e');
    }
    
    return fotosSalvas;
  }
}

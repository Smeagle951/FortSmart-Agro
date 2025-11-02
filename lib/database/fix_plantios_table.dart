import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_database.dart';

/// Script para corrigir a tabela plantios
class FixPlantiosTable {
  static Future<void> fixTable() async {
    try {
      print('🔧 Iniciando correção da tabela plantios...');
      
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'fortsmartagro.db');
      
      final db = await openDatabase(path);
      
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plantios'"
      );
      
      if (tables.isNotEmpty) {
        print('📋 Tabela plantios encontrada, verificando estrutura...');
        
        // Obter estrutura atual da tabela
        final columns = await db.rawQuery("PRAGMA table_info(plantios)");
        final existingColumns = columns.map((col) => col['name'] as String).toSet();
        
        print('📊 Colunas existentes: ${existingColumns.join(', ')}');
        
        // Lista de colunas necessárias
        final requiredColumns = {
          'talhaold', 'culturald', 'variedadeld', 'safrald', 'usuariold',
          'descricao', 'dataPlantio', 'areaPlantada', 'densidade',
          'pesoMedioSemente', 'sementesMetro', 'sementesHa', 'kgHa',
          'sacasHa', 'metodoCalibragrem', 'fonteEstoqueld',
          'fonteEstoqueQuantidade', 'fotos', 'dataCriacao', 'dataAtualizacao',
          'device_id'
        };
        
        // Adicionar colunas faltantes
        for (final column in requiredColumns) {
          if (!existingColumns.contains(column)) {
            try {
              await db.execute('ALTER TABLE plantios ADD COLUMN $column TEXT');
              print('✅ Coluna $column adicionada');
            } catch (e) {
              print('⚠️ Erro ao adicionar coluna $column: $e');
            }
          } else {
            print('✅ Coluna $column já existe');
          }
        }
        
        // Verificar se há colunas de área que precisam ser REAL
        final realColumns = {'areaPlantada', 'densidade', 'pesoMedioSemente', 
                           'sementesMetro', 'sementesHa', 'kgHa', 'sacasHa', 
                           'fonteEstoqueQuantidade'};
        
        for (final column in realColumns) {
          if (existingColumns.contains(column)) {
            try {
              // SQLite não suporta ALTER COLUMN TYPE, então vamos recriar a tabela se necessário
              print('📝 Coluna $column será mantida como está');
            } catch (e) {
              print('⚠️ Erro ao verificar coluna $column: $e');
            }
          }
        }
        
      } else {
        print('❌ Tabela plantios não encontrada, criando nova...');
        
        // Criar tabela com estrutura completa
        await db.execute('''
          CREATE TABLE plantios (
            id TEXT PRIMARY KEY,
            talhaold TEXT,
            culturald TEXT,
            variedadeld TEXT,
            safrald TEXT,
            usuariold TEXT,
            descricao TEXT,
            dataPlantio TEXT,
            areaPlantada REAL,
            espacamento REAL,
            densidade REAL,
            germinacao REAL,
            pesoMedioSemente REAL,
            sementesMetro REAL,
            sementesHa REAL,
            kgHa REAL,
            sacasHa REAL,
            metodoCalibragrem TEXT,
            fonteEstoqueld TEXT,
            fonteEstoqueQuantidade REAL,
            fotos TEXT,
            dataCriacao TEXT,
            dataAtualizacao TEXT,
            created_at TEXT,
            updated_at TEXT,
            device_id TEXT,
            talhao_id TEXT,
            cultura_id TEXT,
            variedade_id TEXT,
            data_plantio TEXT,
            populacao INTEGER,
            profundidade REAL,
            maquinas_ids TEXT,
            densidade_linear REAL,
            metodo_calibragem TEXT,
            fonte_sementes_id TEXT,
            resultados TEXT,
            observacoes TEXT,
            trator_id TEXT,
            plantadeira_id TEXT,
            calibragem_id TEXT,
            estande_id TEXT,
            peso_mil_sementes REAL,
            gramas_coletadas REAL,
            distancia_percorrida REAL,
            engrenagem_motora INTEGER,
            engrenagem_movida INTEGER,
            sync_status INTEGER NOT NULL DEFAULT 0,
            remote_id TEXT
          )
        ''');
        print('✅ Tabela plantios criada com sucesso');
      }
      
      await db.close();
      print('🎉 Correção da tabela plantios concluída!');
      
    } catch (e) {
      print('❌ Erro ao corrigir tabela plantios: $e');
      rethrow;
    }
  }
}

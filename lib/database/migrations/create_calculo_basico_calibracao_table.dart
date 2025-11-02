import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela de cálculo básico de calibração
class CreateCalculoBasicoCalibracaoTable {
  static const String tableName = 'calculo_basico_calibracao';

  static Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        data_calibragem TEXT NOT NULL,
        equipamento TEXT NOT NULL,
        operador TEXT NOT NULL,
        fertilizante TEXT NOT NULL,
        velocidade_trator REAL NOT NULL,
        largura_trabalho REAL NOT NULL,
        abertura_comporta REAL NOT NULL,
        tipo_coleta TEXT NOT NULL,
        tempo_coletado REAL,
        distancia_percorrida REAL,
        volume_coletado REAL NOT NULL,
        unidade_volume TEXT NOT NULL,
        meta_aplicacao REAL,
        densidade REAL,
        area_percorrida REAL,
        area_hectares REAL,
        taxa_aplicada_l REAL,
        taxa_aplicada_kg REAL,
        sacas_ha REAL,
        diferenca_meta REAL,
        erro_porcentagem REAL,
        status_calibragem TEXT,
        sugestao_ajuste TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $tableName');
  }
}

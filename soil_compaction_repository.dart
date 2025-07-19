import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'soil_compaction_model.dart';
import 'soil_compaction_photo_model.dart';

class SoilCompactionRepository {
  static final SoilCompactionRepository _instance = SoilCompactionRepository._internal();
  static Database? _database;

  // Nome das tabelas
  static const String tableCompactacao = 'compactacao_solo';
  static const String tableFotos = 'compactacao_fotos';

  factory SoilCompactionRepository() {
    return _instance;
  }

  SoilCompactionRepository._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'fortsmart_agro.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Criar tabela de compactação de solo
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCompactacao (
        id TEXT PRIMARY KEY,
        talhaoId TEXT,
        talhaoNome TEXT,
        safraId TEXT,
        safraNome TEXT,
        profundidade REAL,
        diametroCone REAL,
        forcaAplicada REAL,
        resistenciaPenetracao REAL,
        interpretacao TEXT,
        cor INTEGER,
        dataCalculo TEXT,
        latitude REAL,
        longitude REAL,
        observacoes TEXT
      )
    ''');

    // Criar tabela de fotos de compactação
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFotos (
        id TEXT PRIMARY KEY,
        compactionId TEXT,
        imagePath TEXT,
        descricao TEXT,
        dataCriacao TEXT,
        FOREIGN KEY (compactionId) REFERENCES $tableCompactacao (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migrações futuras se necessário
  }

  // Métodos para operações CRUD na tabela de compactação

  Future<String> inserirCompactacao(SoilCompactionModel compactacao) async {
    final db = await database;
    await db.insert(
      tableCompactacao,
      compactacao.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return compactacao.id;
  }

  Future<SoilCompactionModel?> obterCompactacao(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCompactacao,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return SoilCompactionModel.fromMap(maps.first);
  }

  Future<List<SoilCompactionModel>> listarCompactacoes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCompactacao,
      orderBy: 'dataCalculo DESC',
    );

    return List.generate(maps.length, (i) {
      return SoilCompactionModel.fromMap(maps[i]);
    });
  }

  Future<List<SoilCompactionModel>> listarCompactacoesPorTalhao(String talhaoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCompactacao,
      where: 'talhaoId = ?',
      whereArgs: [talhaoId],
      orderBy: 'dataCalculo DESC',
    );

    return List.generate(maps.length, (i) {
      return SoilCompactionModel.fromMap(maps[i]);
    });
  }

  Future<void> atualizarCompactacao(SoilCompactionModel compactacao) async {
    final db = await database;
    await db.update(
      tableCompactacao,
      compactacao.toMap(),
      where: 'id = ?',
      whereArgs: [compactacao.id],
    );
  }

  Future<void> excluirCompactacao(String id) async {
    final db = await database;
    
    // Primeiro exclui as fotos relacionadas
    await db.delete(
      tableFotos,
      where: 'compactionId = ?',
      whereArgs: [id],
    );
    
    // Depois exclui o registro de compactação
    await db.delete(
      tableCompactacao,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para operações CRUD na tabela de fotos

  Future<String> inserirFoto(SoilCompactionPhotoModel foto) async {
    final db = await database;
    await db.insert(
      tableFotos,
      foto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return foto.id;
  }

  Future<List<SoilCompactionPhotoModel>> listarFotosPorCompactacao(String compactionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFotos,
      where: 'compactionId = ?',
      whereArgs: [compactionId],
      orderBy: 'dataCriacao ASC',
    );

    return List.generate(maps.length, (i) {
      return SoilCompactionPhotoModel.fromMap(maps[i]);
    });
  }

  Future<void> excluirFoto(String id) async {
    final db = await database;
    await db.delete(
      tableFotos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> excluirFotosPorCompactacao(String compactionId) async {
    final db = await database;
    await db.delete(
      tableFotos,
      where: 'compactionId = ?',
      whereArgs: [compactionId],
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/experimento_completo_model.dart';
import '../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// Serviço para gerenciar experimentos de talhão
class ExperimentoService {
  static final ExperimentoService _instance = ExperimentoService._internal();
  factory ExperimentoService() => _instance;
  ExperimentoService._internal();

  final AppDatabase _appDatabase = AppDatabase();
  static const String _tableName = 'experimentos';
  static const String _subareasTableName = 'subareas_experimento';

  /// Garante que as tabelas existem
  Future<void> _ensureTablesExist() async {
    final db = await _appDatabase.database;
    
    // Tabela de experimentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        talhaoId TEXT NOT NULL,
        talhaoNome TEXT NOT NULL,
        dataInicio TEXT NOT NULL,
        dataFim TEXT NOT NULL,
        status INTEGER NOT NULL,
        descricao TEXT,
        objetivo TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabela de subáreas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_subareasTableName (
        id TEXT PRIMARY KEY,
        experimentoId TEXT NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        cor INTEGER NOT NULL,
        pontos TEXT NOT NULL,
        area REAL NOT NULL,
        perimetro REAL NOT NULL,
        descricao TEXT,
        cultura TEXT,
        variedade TEXT,
        observacoes TEXT,
        status INTEGER NOT NULL,
        dataCriacao TEXT NOT NULL,
        dataFinalizacao TEXT,
        dadosPlantio TEXT,
        dadosColheita TEXT,
        FOREIGN KEY (experimentoId) REFERENCES $_tableName (id) ON DELETE CASCADE
      )
    ''');

    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_experimentos_talhao ON $_tableName (talhaoId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subareas_experimento ON $_subareasTableName (experimentoId)');
  }

  /// Cria um novo experimento
  Future<String> criarExperimento({
    required String nome,
    required String talhaoId,
    required String talhaoNome,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? descricao,
    String? objetivo,
  }) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    final experimento = ExperimentoCompleto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      talhaoId: talhaoId,
      talhaoNome: talhaoNome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      status: ExperimentoStatus.ativo,
      descricao: descricao,
      objetivo: objetivo,
      subareas: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await db.insert(_tableName, experimento.toMap());
    return experimento.id;
  }

  /// Atualiza um experimento
  Future<void> atualizarExperimento(ExperimentoCompleto experimento) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    final experimentoAtualizado = experimento.copyWith(
      updatedAt: DateTime.now(),
    );

    await db.update(
      _tableName,
      experimentoAtualizado.toMap(),
      where: 'id = ?',
      whereArgs: [experimento.id],
    );
  }

  /// Busca experimento por ID
  Future<ExperimentoCompleto?> buscarExperimentoPorId(String id) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    final experimentoMap = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (experimentoMap.isEmpty) return null;

    final experimento = ExperimentoCompleto.fromMap(experimentoMap.first);
    
    // Carregar subáreas
    final subareas = await _carregarSubareas(experimento.id);
    return experimento.copyWith(subareas: subareas);
  }

  /// Busca experimentos por talhão
  Future<List<ExperimentoCompleto>> buscarExperimentosPorTalhao(String talhaoId) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    final experimentosMap = await db.query(
      _tableName,
      where: 'talhaoId = ?',
      whereArgs: [talhaoId],
      orderBy: 'createdAt DESC',
    );

    final List<ExperimentoCompleto> experimentos = [];

    for (final map in experimentosMap) {
      final experimento = ExperimentoCompleto.fromMap(map);
      final subareas = await _carregarSubareas(experimento.id);
      experimentos.add(experimento.copyWith(subareas: subareas));
    }

    return experimentos;
  }

  /// Lista todos os experimentos
  Future<List<ExperimentoCompleto>> listarExperimentos() async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    final experimentosMap = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    final List<ExperimentoCompleto> experimentos = [];

    for (final map in experimentosMap) {
      final experimento = ExperimentoCompleto.fromMap(map);
      final subareas = await _carregarSubareas(experimento.id);
      experimentos.add(experimento.copyWith(subareas: subareas));
    }

    return experimentos;
  }

  /// Carrega subáreas de um experimento
  Future<List<SubareaCompleta>> _carregarSubareas(String experimentoId) async {
    final db = await _appDatabase.database;

    final subareasMap = await db.query(
      _subareasTableName,
      where: 'experimentoId = ?',
      whereArgs: [experimentoId],
      orderBy: 'dataCriacao ASC',
    );

    return subareasMap.map((map) => SubareaCompleta.fromMap(map)).toList();
  }

  /// Cria uma nova subárea
  Future<String> criarSubarea({
    required String experimentoId,
    required String nome,
    required String tipo,
    required List<LatLng> pontos,
    required Color cor,
    String? descricao,
    String? cultura,
    String? variedade,
    String? observacoes,
  }) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    // Calcular área e perímetro
    final area = _calcularArea(pontos);
    final perimetro = _calcularPerimetro(pontos);

    final subarea = SubareaCompleta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      experimentoId: experimentoId,
      nome: nome,
      tipo: tipo,
      cor: cor,
      pontos: pontos,
      area: area,
      perimetro: perimetro,
      descricao: descricao,
      cultura: cultura,
      variedade: variedade,
      observacoes: observacoes,
      status: SubareaStatus.ativa,
      dataCriacao: DateTime.now(),
    );

    await db.insert(_subareasTableName, subarea.toMap());
    return subarea.id;
  }

  /// Atualiza uma subárea
  Future<void> atualizarSubarea(SubareaCompleta subarea) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    await db.update(
      _subareasTableName,
      subarea.toMap(),
      where: 'id = ?',
      whereArgs: [subarea.id],
    );
  }

  /// Remove uma subárea
  Future<void> removerSubarea(String subareaId) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    await db.delete(
      _subareasTableName,
      where: 'id = ?',
      whereArgs: [subareaId],
    );
  }

  /// Busca subárea por ID
  Future<SubareaCompleta?> buscarSubareaPorId(String id) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    final subareaMap = await db.query(
      _subareasTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (subareaMap.isEmpty) return null;

    return SubareaCompleta.fromMap(subareaMap.first);
  }

  /// Calcula a área de um polígono usando a fórmula de Shoelace
  double _calcularArea(List<LatLng> pontos) {
    if (pontos.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      final j = (i + 1) % pontos.length;
      area += pontos[i].longitude * pontos[j].latitude;
      area -= pontos[j].longitude * pontos[i].latitude;
    }
    
    // Converter para hectares (aproximação)
    area = (area.abs() / 2) * 111320 * 111320 / 10000;
    return area;
  }

  /// Calcula o perímetro de um polígono
  double _calcularPerimetro(List<LatLng> pontos) {
    if (pontos.length < 2) return 0.0;

    double perimetro = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      final j = (i + 1) % pontos.length;
      perimetro += _calcularDistancia(pontos[i], pontos[j]);
    }
    
    return perimetro;
  }

  /// Calcula distância entre dois pontos
  double _calcularDistancia(LatLng ponto1, LatLng ponto2) {
    const double raioTerra = 6371000; // Raio da Terra em metros
    
    final lat1Rad = ponto1.latitude * pi / 180;
    final lat2Rad = ponto2.latitude * pi / 180;
    final deltaLatRad = (ponto2.latitude - ponto1.latitude) * pi / 180;
    final deltaLngRad = (ponto2.longitude - ponto1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return raioTerra * c;
  }

  /// Verifica se pode criar mais subáreas
  Future<bool> podeCriarSubarea(String experimentoId) async {
    final experimento = await buscarExperimentoPorId(experimentoId);
    return experimento?.podeCriarSubarea ?? false;
  }

  /// Obtém próxima cor disponível para subárea
  Color obterProximaCor(String experimentoId, List<SubareaCompleta> subareasExistentes) {
    final coresUsadas = subareasExistentes.map((s) => s.cor.value).toSet();
    
    for (final cor in PaletaCoresSubareas.cores) {
      if (!coresUsadas.contains(cor.value)) {
        return cor;
      }
    }
    
    // Se todas as cores foram usadas, retornar uma cor aleatória
    final random = Random();
    return PaletaCoresSubareas.cores[random.nextInt(PaletaCoresSubareas.cores.length)];
  }

  /// Remove experimento e todas suas subáreas
  Future<void> removerExperimento(String experimentoId) async {
    await _ensureTablesExist();
    final db = await _appDatabase.database;

    // Remover subáreas primeiro (cascade)
    await db.delete(
      _subareasTableName,
      where: 'experimentoId = ?',
      whereArgs: [experimentoId],
    );

    // Remover experimento
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [experimentoId],
    );
  }

  /// Finaliza experimento
  Future<void> finalizarExperimento(String experimentoId) async {
    final experimento = await buscarExperimentoPorId(experimentoId);
    if (experimento != null) {
      final experimentoFinalizado = experimento.copyWith(
        status: ExperimentoStatus.concluido,
        updatedAt: DateTime.now(),
      );
      
      await atualizarExperimento(experimentoFinalizado);
    }
  }

  /// Atualiza dados de plantio de uma subárea
  Future<void> atualizarDadosPlantio(String subareaId, Map<String, dynamic> dadosPlantio) async {
    final subarea = await buscarSubareaPorId(subareaId);
    if (subarea != null) {
      final subareaAtualizada = subarea.copyWith(dadosPlantio: dadosPlantio);
      await atualizarSubarea(subareaAtualizada);
    }
  }

  /// Atualiza dados de colheita de uma subárea
  Future<void> atualizarDadosColheita(String subareaId, Map<String, dynamic> dadosColheita) async {
    final subarea = await buscarSubareaPorId(subareaId);
    if (subarea != null) {
      final subareaAtualizada = subarea.copyWith(dadosColheita: dadosColheita);
      await atualizarSubarea(subareaAtualizada);
    }
  }
}

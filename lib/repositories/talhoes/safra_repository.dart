import 'package:sqflite/sqflite.dart';
import '../../database/app_database.dart';
import '../../services/perfil_service.dart';

/// Modelo para representar uma safra agrícola
class SafraModel {
  String id;
  String nome;
  String periodo; // Ex: "2023/2024"
  DateTime dataInicio;
  DateTime dataFim;
  bool ativa;
  DateTime dataCriacao;
  DateTime dataAtualizacao;

  SafraModel({
    required this.id,
    required this.nome,
    required this.periodo,
    required this.dataInicio,
    required this.dataFim,
    this.ativa = true,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'periodo': periodo,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      'ativa': ativa ? 1 : 0,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um mapa
  factory SafraModel.fromMap(Map<String, dynamic> map) {
    return SafraModel(
      id: map['id'],
      nome: map['nome'],
      periodo: map['periodo'],
      dataInicio: DateTime.parse(map['dataInicio']),
      dataFim: DateTime.parse(map['dataFim']),
      ativa: map['ativa'] == 1,
      dataCriacao: DateTime.parse(map['dataCriacao']),
      dataAtualizacao: DateTime.parse(map['dataAtualizacao']),
    );
  }
}

/// Repositório para gerenciar safras
class SafraRepository {
  final AppDatabase _appDatabase = AppDatabase();
  PerfilService? _perfilService;
  
  /// Obtém a instância do PerfilService de forma lazy
  PerfilService get perfilService {
    _perfilService ??= PerfilService();
    return _perfilService!;
  }

  // Nome da tabela
  static const String tabelaSafra = 'safra';

  Future<Database> get database async => await _appDatabase.database;

  /// Inicializa a tabela no banco de dados
  Future<void> inicializarTabela(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaSafra (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        periodo TEXT NOT NULL,
        dataInicio TEXT NOT NULL,
        dataFim TEXT NOT NULL,
        ativa INTEGER DEFAULT 1,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL
      )
    ''');
  }

  /// Adiciona uma nova safra
  Future<String> adicionarSafra(SafraModel safra) async {
    final db = await database;
    
    await db.insert(
      tabelaSafra,
      safra.toMap(),
    );
    
    return safra.id;
  }

  /// Atualiza uma safra existente
  Future<void> atualizarSafra(SafraModel safra) async {
    final db = await database;
    
    await db.update(
      tabelaSafra,
      {
        'nome': safra.nome,
        'periodo': safra.periodo,
        'dataInicio': safra.dataInicio.toIso8601String(),
        'dataFim': safra.dataFim.toIso8601String(),
        'ativa': safra.ativa ? 1 : 0,
        'dataAtualizacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [safra.id],
    );
  }

  /// Remove uma safra (desativa)
  Future<void> removerSafra(String id) async {
    final db = await database;
    
    await db.update(
      tabelaSafra,
      {
        'ativa': 0,
        'dataAtualizacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca todas as safras ativas
  Future<List<SafraModel>> buscarSafrasAtivas() async {
    final db = await database;
    
    final safras = await db.query(
      tabelaSafra,
      where: 'ativa = 1',
      orderBy: 'dataInicio DESC',
    );
    
    return safras.map((s) => SafraModel.fromMap(s)).toList();
  }

  /// Busca todas as safras (ativas e inativas)
  Future<List<SafraModel>> buscarTodasSafras() async {
    final db = await database;
    
    final safras = await db.query(
      tabelaSafra,
      orderBy: 'dataInicio DESC',
    );
    
    return safras.map((s) => SafraModel.fromMap(s)).toList();
  }

  /// Busca uma safra pelo ID
  Future<SafraModel?> buscarSafraPorId(String id) async {
    final db = await database;
    
    final safras = await db.query(
      tabelaSafra,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (safras.isEmpty) return null;
    
    return SafraModel.fromMap(safras.first);
  }

  /// Busca a safra atual (a mais recente ativa)
  Future<SafraModel?> buscarSafraAtual() async {
    final db = await database;
    
    final safras = await db.query(
      tabelaSafra,
      where: 'ativa = 1',
      orderBy: 'dataInicio DESC',
      limit: 1,
    );
    
    if (safras.isEmpty) {
      // Se não encontrar nenhuma safra ativa, criar uma safra padrão
      return await _criarSafraPadrao();
    }
    
    return SafraModel.fromMap(safras.first);
  }

  /// Cria uma safra padrão se não existir nenhuma
  Future<SafraModel> _criarSafraPadrao() async {
    final now = DateTime.now();
    final anoAtual = now.year;
    final anoProximo = anoAtual + 1;
    
    // Definir período da safra (geralmente começa em setembro e termina em agosto)
    var dataInicio = DateTime(anoAtual, 9, 1);
    var dataFim = DateTime(anoProximo, 8, 31);
    
    // Se já passou de setembro, ajustar para o próximo ano
    if (now.isAfter(dataFim)) {
      dataInicio = DateTime(anoAtual + 1, 9, 1);
      dataFim = DateTime(anoAtual + 2, 8, 31);
    }
    
    final periodo = '${dataInicio.year}/${dataFim.year}';
    
    final safra = SafraModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: 'Safra $periodo',
      periodo: periodo,
      dataInicio: dataInicio,
      dataFim: dataFim,
      ativa: true,
      dataCriacao: now,
      dataAtualizacao: now,
    );
    
    await adicionarSafra(safra);
    return safra;
  }

  /// Duplica uma safra existente para criar uma nova
  Future<SafraModel> duplicarSafra(String idSafraOriginal) async {
    final safraOriginal = await buscarSafraPorId(idSafraOriginal);
    if (safraOriginal == null) {
      throw Exception('Safra original não encontrada');
    }
    
    final now = DateTime.now();
    final anoInicio = safraOriginal.dataInicio.year + 1;
    final anoFim = safraOriginal.dataFim.year + 1;
    
    final dataInicio = DateTime(anoInicio, safraOriginal.dataInicio.month, safraOriginal.dataInicio.day);
    final dataFim = DateTime(anoFim, safraOriginal.dataFim.month, safraOriginal.dataFim.day);
    
    final periodo = '${dataInicio.year}/${dataFim.year}';
    
    final novaSafra = SafraModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: 'Safra $periodo',
      periodo: periodo,
      dataInicio: dataInicio,
      dataFim: dataFim,
      ativa: true,
      dataCriacao: now,
      dataAtualizacao: now,
    );
    
    await adicionarSafra(novaSafra);
    return novaSafra;
  }
}

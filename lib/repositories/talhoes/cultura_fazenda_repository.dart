import 'package:sqflite/sqflite.dart';
import '../../models/talhoes/talhao_safra_model.dart';
import '../../models/agricultural_product_model.dart';
import '../../models/cultura_model.dart';
import '../../database/app_database.dart';
import '../../services/perfil_service.dart';

/// Repositório para gerenciar culturas da fazenda
class CulturaFazendaRepository {
  final PerfilService _perfilService = PerfilService();

  // Nome da tabela
  static const String tabelaCulturaFazenda = 'cultura_fazenda';

  /// Inicializa a tabela no banco de dados
  Future<void> inicializarTabela(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaCulturaFazenda (
        id TEXT PRIMARY KEY,
        idFazenda TEXT NOT NULL,
        nome TEXT NOT NULL,
        corHex TEXT NOT NULL,
        imagem TEXT,
        ativa INTEGER DEFAULT 1,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL
      )
    ''');
  }

  /// Adiciona uma nova cultura da fazenda
  Future<String> adicionarCultura(CulturaFazendaModel cultura) async {
    final db = await AppDatabase().database;
    
    await db.insert(
      tabelaCulturaFazenda,
      {
        'id': cultura.id,
        'idFazenda': cultura.idFazenda,
        'nome': cultura.name,
        'corHex': cultura.corHex,
        'imagem': cultura.imagem,
        'ativa': cultura.ativa ? 1 : 0,
        'dataCriacao': cultura.dataCriacao.toIso8601String(),
        'dataAtualizacao': cultura.dataAtualizacao.toIso8601String(),
      },
    );
    
    return cultura.id;
  }

  /// Atualiza uma cultura da fazenda existente
  Future<void> atualizarCultura(CulturaFazendaModel cultura) async {
    final db = await AppDatabase().database;
    
    await db.update(
      tabelaCulturaFazenda,
      {
        'nome': cultura.name,
        'corHex': cultura.corHex,
        'imagem': cultura.imagem,
        'ativa': cultura.ativa ? 1 : 0,
        'dataAtualizacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [cultura.id],
    );
  }

  /// Remove uma cultura da fazenda
  Future<void> removerCultura(String id) async {
    final db = await AppDatabase().database;
    
    await db.update(
      tabelaCulturaFazenda,
      {
        'ativa': 0,
        'dataAtualizacao': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca todas as culturas da fazenda atual
  Future<List<CulturaFazendaModel>> buscarCulturasPorFazenda() async {
    final fazendaAtual = await _perfilService.getFazendaAtual();
    if (fazendaAtual == null) return [];
    
    return buscarCulturasPorIdFazenda(fazendaAtual.id);
  }

  /// Busca culturas por ID da fazenda
  Future<List<CulturaFazendaModel>> buscarCulturasPorIdFazenda(String idFazenda) async {
    final db = await AppDatabase().database;
    
    final culturas = await db.query(
      tabelaCulturaFazenda,
      where: 'idFazenda = ? AND ativa = 1',
      whereArgs: [idFazenda],
    );
    
    return culturas.map((c) => CulturaFazendaModel.fromMap(c)).toList();
  }

  /// Busca uma cultura da fazenda pelo ID
  Future<CulturaFazendaModel?> buscarCulturaPorId(String id) async {
    final db = await AppDatabase().database;
    
    final culturas = await db.query(
      tabelaCulturaFazenda,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (culturas.isEmpty) return null;
    
    return CulturaFazendaModel.fromMap(culturas.first);
  }

  /// Importa culturas do módulo de Culturas e Pragas
  Future<int> importarCulturasGlobais(List<AgriculturalProduct> culturasGlobais) async {
    final fazendaAtual = await _perfilService.getFazendaAtual();
    if (fazendaAtual == null) return 0;
    
    final db = await AppDatabase().database;
    int contador = 0;
    
    // Filtrar apenas culturas
    final culturas = culturasGlobais.where((c) => c.type == 'culture' && !c.isDeleted).toList();
    
    for (var cultura in culturas) {
      // Verificar se já existe
      final existentes = await db.query(
        tabelaCulturaFazenda,
        where: 'idFazenda = ? AND nome = ?',
        whereArgs: [fazendaAtual.id, cultura.name],
        limit: 1,
      );
      
      if (existentes.isEmpty) {
        // Converter para CulturaFazendaModel
        final culturaFazenda = CulturaFazendaModel.fromAgriculturalProduct(
          cultura, 
          fazendaAtual.id,
        );
        
        // Adicionar ao banco
        await adicionarCultura(culturaFazenda);
        contador++;
      }
    }
    
    return contador;
  }

  /// Importa culturas do modelo antigo
  Future<int> importarCulturasAntigas(List<CulturaModel> culturasAntigas) async {
    final fazendaAtual = await _perfilService.getFazendaAtual();
    if (fazendaAtual == null) return 0;
    
    final db = await AppDatabase().database;
    int contador = 0;
    
    for (var cultura in culturasAntigas) {
      // Verificar se já existe
      final existentes = await db.query(
        tabelaCulturaFazenda,
        where: 'idFazenda = ? AND nome = ?',
        whereArgs: [fazendaAtual.id, cultura.name],
        limit: 1,
      );
      
      if (existentes.isEmpty) {
        // Converter para CulturaFazendaModel
        final culturaFazenda = CulturaFazendaModel.fromCulturaModel(
          cultura, 
          fazendaAtual.id,
        );
        
        // Adicionar ao banco
        await adicionarCultura(culturaFazenda);
        contador++;
      }
    }
    
    return contador;
  }
}

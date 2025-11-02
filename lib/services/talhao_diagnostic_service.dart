import 'package:flutter/material.dart';
import '../repositories/talhoes/talhao_sqlite_repository.dart';
import '../repositories/talhao_repository_v2.dart';
import '../repositories/plot_repository.dart';
import '../models/talhao_model.dart';
import '../models/plot.dart';
import '../database/talhao_database.dart';

/// Serviço para diagnosticar problemas com carregamento de talhões
class TalhaoDiagnosticService {
  static final TalhaoDiagnosticService _instance = TalhaoDiagnosticService._internal();
  factory TalhaoDiagnosticService() => _instance;
  TalhaoDiagnosticService._internal();

  final TalhaoSQLiteRepository _sqliteRepository = TalhaoSQLiteRepository();
  final TalhaoRepositoryV2 _repositoryV2 = TalhaoRepositoryV2();
  final PlotRepository _plotRepository = PlotRepository();
  final TalhaoDatabase _database = TalhaoDatabase();

  /// Executa diagnóstico completo dos talhões
  Future<Map<String, dynamic>> executarDiagnostico() async {
    final resultado = <String, dynamic>{};
    
    try {
      // 1. Verificar banco SQLite
      resultado['sqlite'] = await _diagnosticarSQLite();
      
      // 2. Verificar repositório V2
      resultado['repository_v2'] = await _diagnosticarRepositoryV2();
      
      // 3. Verificar repositório antigo (Plot)
      resultado['plot_repository'] = await _diagnosticarPlotRepository();
      
      // 4. Verificar banco de dados direto
      resultado['database_direct'] = await _diagnosticarDatabaseDireto();
      
      // 5. Resumo geral
      resultado['resumo'] = _gerarResumo(resultado);
      
    } catch (e) {
      resultado['erro_geral'] = e.toString();
    }
    
    return resultado;
  }

  /// Gera relatório de diagnóstico (alias para executarDiagnostico)
  Future<Map<String, dynamic>> gerarRelatorioDiagnostico() async {
    return executarDiagnostico();
  }

  /// Diagnostica o repositório SQLite
  Future<Map<String, dynamic>> _diagnosticarSQLite() async {
    try {
      final talhoes = await _sqliteRepository.listarTodos();
      return {
        'sucesso': true,
        'quantidade': talhoes.length,
        'talhoes': talhoes.map((t) => {
          'id': t.id,
          'nome': t.name,
          'area': t.area,
          'fazenda_id': t.fazendaId,
        }).toList(),
      };
    } catch (e) {
      return {
        'sucesso': false,
        'erro': e.toString(),
        'quantidade': 0,
      };
    }
  }

  /// Diagnostica o repositório V2
  Future<Map<String, dynamic>> _diagnosticarRepositoryV2() async {
    try {
      final talhoes = await _repositoryV2.listarTodos();
      return {
        'sucesso': true,
        'quantidade': talhoes.length,
        'talhoes': talhoes.map((t) => {
          'id': t.id,
          'nome': t.name,
          'area': t.area,
          'fazenda_id': t.fazendaId,
        }).toList(),
      };
    } catch (e) {
      return {
        'sucesso': false,
        'erro': e.toString(),
        'quantidade': 0,
      };
    }
  }

  /// Diagnostica o repositório antigo (Plot)
  Future<Map<String, dynamic>> _diagnosticarPlotRepository() async {
    try {
      final plots = await _plotRepository.getPlots();
      return {
        'sucesso': true,
        'quantidade': plots.length,
        'plots': plots.map((p) => {
          'id': p.id,
          'nome': p.name,
          'area': p.area,
          'farm_id': p.farmId,
        }).toList(),
      };
    } catch (e) {
      return {
        'sucesso': false,
        'erro': e.toString(),
        'quantidade': 0,
      };
    }
  }

  /// Diagnostica o banco de dados direto
  Future<Map<String, dynamic>> _diagnosticarDatabaseDireto() async {
    try {
      final talhoes = await _database.listarTodos();
      return {
        'sucesso': true,
        'quantidade': talhoes.length,
        'talhoes': talhoes.map((t) => {
          'id': t.id,
          'nome': t.name,
          'area': t.area,
          'fazenda_id': t.fazendaId,
        }).toList(),
      };
    } catch (e) {
      return {
        'sucesso': false,
        'erro': e.toString(),
        'quantidade': 0,
      };
    }
  }

  /// Gera resumo do diagnóstico
  Map<String, dynamic> _gerarResumo(Map<String, dynamic> resultado) {
    int totalTalhoes = 0;
    List<String> fontesComDados = [];
    List<String> problemas = [];

    // Contar talhões de cada fonte
    if (resultado['sqlite']?['sucesso'] == true) {
      totalTalhoes += resultado['sqlite']['quantidade'] as int;
      if (resultado['sqlite']['quantidade'] > 0) {
        fontesComDados.add('SQLite Repository');
      }
    } else {
      problemas.add('SQLite Repository: ${resultado['sqlite']?['erro'] ?? 'Erro desconhecido'}');
    }

    if (resultado['repository_v2']?['sucesso'] == true) {
      totalTalhoes += resultado['repository_v2']['quantidade'] as int;
      if (resultado['repository_v2']['quantidade'] > 0) {
        fontesComDados.add('Repository V2');
      }
    } else {
      problemas.add('Repository V2: ${resultado['repository_v2']?['erro'] ?? 'Erro desconhecido'}');
    }

    if (resultado['plot_repository']?['sucesso'] == true) {
      totalTalhoes += resultado['plot_repository']['quantidade'] as int;
      if (resultado['plot_repository']['quantidade'] > 0) {
        fontesComDados.add('Plot Repository');
      }
    } else {
      problemas.add('Plot Repository: ${resultado['plot_repository']?['erro'] ?? 'Erro desconhecido'}');
    }

    if (resultado['database_direct']?['sucesso'] == true) {
      if (resultado['database_direct']['quantidade'] > 0) {
        fontesComDados.add('Database Direct');
      }
    } else {
      problemas.add('Database Direct: ${resultado['database_direct']?['erro'] ?? 'Erro desconhecido'}');
    }

    return {
      'total_talhoes': totalTalhoes,
      'fontes_com_dados': fontesComDados,
      'problemas': problemas,
      'tem_talhoes': totalTalhoes > 0,
      'status': totalTalhoes > 0 ? 'OK' : 'SEM_DADOS',
    };
  }

  /// Cria talhões de exemplo para teste
  Future<bool> criarTalhoesExemplo() async {
    try {
      final talhoesExemplo = [
        TalhaoModel(
          id: 'talhao_001',
          name: 'Talhão A - Soja',
          area: 25.5,
          fazendaId: 'fazenda_001',
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          sincronizado: false,
          safras: [],
          culturaId: 'soja',
          cropId: 1,
          poligonos: [],
        ),
        TalhaoModel(
          id: 'talhao_002',
          name: 'Talhão B - Milho',
          area: 18.3,
          fazendaId: 'fazenda_001',
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          sincronizado: false,
          safras: [],
          culturaId: 'milho',
          cropId: 2,
          poligonos: [],
        ),
        TalhaoModel(
          id: 'talhao_003',
          name: 'Talhão C - Algodão',
          area: 32.1,
          fazendaId: 'fazenda_001',
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          sincronizado: false,
          safras: [],
          culturaId: 'algodao',
          cropId: 3,
          poligonos: [],
        ),
      ];

      for (final talhao in talhoesExemplo) {
        await _sqliteRepository.salvar(talhao);
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao criar talhões de exemplo: $e');
      return false;
    }
  }

  /// Limpa todos os talhões (para teste)
  Future<bool> limparTodosTalhoes() async {
    try {
      // Limpar do banco SQLite - usar método existente
      final talhoes = await _database.listarTodos();
      for (final talhao in talhoes) {
        await _database.excluir(int.parse(talhao.id));
      }
      
      // Recarregar repositórios
      await _sqliteRepository.listarTodos();
      
      return true;
    } catch (e) {
      debugPrint('Erro ao limpar talhões: $e');
      return false;
    }
  }
}
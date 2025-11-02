import 'package:intl/intl.dart';
import '../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class PlotHistoryService {
  // Tabelas
  final _tabelaRegistroTalhao = 'registro_talhao';
  final _tabelaAnaliseSolo = 'analise_solo';
  final _tabelaProdutividade = 'produtividade';
  final _tabelaSafras = 'safras';

  // Obter banco de dados
  Future<Database> _getDatabase() async {
    return await AppDatabase.instance.database;
  }

  // Obter anos disponíveis para um talhão
  Future<List<int>> getAnosDisponiveisParaTalhao(String talhaoId) async {
    final db = await _getDatabase();
    
    // Buscar anos onde há registros de talhão
    final List<Map<String, dynamic>> registros = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y', data) as ano FROM $_tabelaRegistroTalhao 
      WHERE talhao_id = ? ORDER BY ano DESC
    ''', [talhaoId]);
    
    // Buscar anos onde há análises de solo
    final List<Map<String, dynamic>> analises = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y', data) as ano FROM $_tabelaAnaliseSolo 
      WHERE talhao_id = ? ORDER BY ano DESC
    ''', [talhaoId]);
    
    // Buscar anos onde há registros de produtividade
    final List<Map<String, dynamic>> produtividades = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y', data_colheita) as ano FROM $_tabelaProdutividade 
      WHERE talhao_id = ? ORDER BY ano DESC
    ''', [talhaoId]);
    
    // Combinar e dedupliocar os anos
    final Set<int> anos = {};
    
    for (var r in registros) {
      if (r['ano'] != null) {
        anos.add(int.parse(r['ano'].toString()));
      }
    }
    
    for (var a in analises) {
      if (a['ano'] != null) {
        anos.add(int.parse(a['ano'].toString()));
      }
    }
    
    for (var p in produtividades) {
      if (p['ano'] != null) {
        anos.add(int.parse(p['ano'].toString()));
      }
    }
    
    // Se não houver anos, incluir o ano atual
    if (anos.isEmpty) {
      anos.add(DateTime.now().year);
    }
    
    // Ordenar os anos em ordem decrescente
    final List<int> anosOrdenados = anos.toList()..sort((a, b) => b.compareTo(a));
    return anosOrdenados;
  }
  
  // Obter registros de um talhão por ano
  Future<List<Map<String, dynamic>>> getRegistrosTalhaoPorAno(String talhaoId, int ano) async {
    final db = await _getDatabase();
    
    final safraId = await _getSafraIdPorAno(ano);
    
    if (safraId != null) {
      final List<Map<String, dynamic>> registros = await db.query(
        _tabelaRegistroTalhao,
        where: 'talhao_id = ? AND safra_id = ?',
        whereArgs: [talhaoId, safraId],
        orderBy: 'data DESC',
      );
      
      return registros;
    } else {
      // Se não encontrou a safra, busca pelo ano na data
      final anoInicio = '$ano-01-01';
      final anoFim = '$ano-12-31';
      
      final List<Map<String, dynamic>> registros = await db.query(
        _tabelaRegistroTalhao,
        where: 'talhao_id = ? AND data BETWEEN ? AND ?',
        whereArgs: [talhaoId, anoInicio, anoFim],
        orderBy: 'data DESC',
      );
      
      return registros;
    }
  }
  
  // Obter análise de solo de um talhão por ano
  Future<Map<String, dynamic>?> getAnaliseSoloPorAno(String talhaoId, int ano) async {
    final db = await _getDatabase();
    
    final safraId = await _getSafraIdPorAno(ano);
    
    if (safraId != null) {
      final List<Map<String, dynamic>> analises = await db.query(
        _tabelaAnaliseSolo,
        where: 'talhao_id = ? AND safra_id = ?',
        whereArgs: [talhaoId, safraId],
        orderBy: 'data DESC',
        limit: 1,
      );
      
      if (analises.isNotEmpty) {
        return analises.first;
      }
    } else {
      // Se não encontrou a safra, busca pelo ano na data
      final anoInicio = '$ano-01-01';
      final anoFim = '$ano-12-31';
      
      final List<Map<String, dynamic>> analises = await db.query(
        _tabelaAnaliseSolo,
        where: 'talhao_id = ? AND data BETWEEN ? AND ?',
        whereArgs: [talhaoId, anoInicio, anoFim],
        orderBy: 'data DESC',
        limit: 1,
      );
      
      if (analises.isNotEmpty) {
        return analises.first;
      }
    }
    
    return null;
  }
  
  // Obter produtividade de um talhão por ano
  Future<Map<String, dynamic>?> getProdutividadePorAno(String talhaoId, int ano) async {
    final db = await _getDatabase();
    
    final safraId = await _getSafraIdPorAno(ano);
    
    if (safraId != null) {
      final List<Map<String, dynamic>> produtividades = await db.query(
        _tabelaProdutividade,
        where: 'talhao_id = ? AND safra_id = ?',
        whereArgs: [talhaoId, safraId],
        orderBy: 'data_colheita DESC',
        limit: 1,
      );
      
      if (produtividades.isNotEmpty) {
        return produtividades.first;
      }
    } else {
      // Se não encontrou a safra, busca pelo ano na data
      final anoInicio = '$ano-01-01';
      final anoFim = '$ano-12-31';
      
      final List<Map<String, dynamic>> produtividades = await db.query(
        _tabelaProdutividade,
        where: 'talhao_id = ? AND data_colheita BETWEEN ? AND ?',
        whereArgs: [talhaoId, anoInicio, anoFim],
        orderBy: 'data_colheita DESC',
        limit: 1,
      );
      
      if (produtividades.isNotEmpty) {
        return produtividades.first;
      }
    }
    
    return null;
  }
  
  // Obter histórico de produtividade
  Future<List<Map<String, dynamic>>> getHistoricoProdutividade(String talhaoId, {int limit = 5}) async {
    final db = await _getDatabase();
    
    final List<Map<String, dynamic>> historico = await db.query(
      _tabelaProdutividade,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data_colheita DESC',
      limit: limit,
    );
    
    return historico;
  }
  
  // Salvar um registro de talhão
  Future<int> salvarRegistroTalhao(Map<String, dynamic> registro) async {
    final db = await _getDatabase();
    
    if (registro.containsKey('id') && registro['id'] != null) {
      // Atualizar registro existente
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      registro['updated_at'] = timestamp;
      
      return await db.update(
        _tabelaRegistroTalhao,
        registro,
        where: 'id = ?',
        whereArgs: [registro['id']],
      );
    } else {
      // Inserir novo registro
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      registro['created_at'] = timestamp;
      registro['updated_at'] = timestamp;
      
      return await db.insert(_tabelaRegistroTalhao, registro);
    }
  }
  
  // Salvar uma análise de solo
  Future<int> salvarAnaliseSolo(Map<String, dynamic> analise) async {
    final db = await _getDatabase();
    
    if (analise.containsKey('id') && analise['id'] != null) {
      // Atualizar análise existente
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      analise['updated_at'] = timestamp;
      
      return await db.update(
        _tabelaAnaliseSolo,
        analise,
        where: 'id = ?',
        whereArgs: [analise['id']],
      );
    } else {
      // Inserir nova análise
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      analise['created_at'] = timestamp;
      analise['updated_at'] = timestamp;
      
      return await db.insert(_tabelaAnaliseSolo, analise);
    }
  }
  
  // Salvar uma produtividade
  Future<int> salvarProdutividade(Map<String, dynamic> produtividade) async {
    final db = await _getDatabase();
    
    if (produtividade.containsKey('id') && produtividade['id'] != null) {
      // Atualizar produtividade existente
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      produtividade['updated_at'] = timestamp;
      
      return await db.update(
        _tabelaProdutividade,
        produtividade,
        where: 'id = ?',
        whereArgs: [produtividade['id']],
      );
    } else {
      // Inserir nova produtividade
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      produtividade['created_at'] = timestamp;
      produtividade['updated_at'] = timestamp;
      
      return await db.insert(_tabelaProdutividade, produtividade);
    }
  }
  
  // Obter média de produtividade por cultura
  Future<Map<String, double>> getMediaProdutividadePorCultura(String talhaoId) async {
    final db = await _getDatabase();
    
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT cultura_id, AVG(produtividade) as media
      FROM $_tabelaProdutividade
      WHERE talhao_id = ?
      GROUP BY cultura_id
    ''', [talhaoId]);
    
    final Map<String, double> medias = {};
    
    for (var r in result) {
      final culturaId = r['cultura_id'].toString();
      final media = r['media'] as double;
      medias[culturaId] = media;
    }
    
    return medias;
  }
  
  // Obter média de consumo de insumos
  Future<Map<String, Map<String, dynamic>>> getMediaConsumoInsumos(String talhaoId, {int anosAtras = 3}) async {
    final db = await _getDatabase();
    
    final dataLimite = DateTime.now().subtract(Duration(days: 365 * anosAtras));
    final dataLimiteStr = DateFormat('yyyy-MM-dd').format(dataLimite);
    
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT tipo_registro, AVG(quantidade) as media, unidade
      FROM $_tabelaRegistroTalhao
      WHERE talhao_id = ? AND data >= ? AND quantidade IS NOT NULL
      GROUP BY tipo_registro, unidade
    ''', [talhaoId, dataLimiteStr]);
    
    final Map<String, Map<String, dynamic>> medias = {};
    
    for (var r in result) {
      final tipoRegistro = r['tipo_registro'].toString();
      final media = r['media'] as double;
      final unidade = r['unidade'].toString();
      
      medias[tipoRegistro] = {
        'media': media,
        'unidade': unidade,
        'periodo': '$anosAtras anos',
      };
    }
    
    return medias;
  }
  
  // Obter média dos indicadores de solo
  Future<Map<String, Map<String, dynamic>>> getMediaIndicadoresSolo(String talhaoId, {int anosAtras = 3}) async {
    final db = await _getDatabase();
    
    final dataLimite = DateTime.now().subtract(Duration(days: 365 * anosAtras));
    final dataLimiteStr = DateFormat('yyyy-MM-dd').format(dataLimite);
    
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        AVG(ph) as ph_medio,
        AVG(v_porcentagem) as v_porcentagem_medio,
        AVG(fosforo) as fosforo_medio,
        AVG(potassio) as potassio_medio
      FROM $_tabelaAnaliseSolo
      WHERE talhao_id = ? AND data >= ?
    ''', [talhaoId, dataLimiteStr]);
    
    final Map<String, Map<String, dynamic>> medias = {};
    
    if (result.isNotEmpty) {
      final r = result.first;
      
      if (r['ph_medio'] != null) {
        medias['pH'] = {
          'valor': r['ph_medio'] as double,
          'periodo': '$anosAtras anos',
        };
      }
      
      if (r['v_porcentagem_medio'] != null) {
        medias['V%'] = {
          'valor': r['v_porcentagem_medio'] as double,
          'periodo': '$anosAtras anos',
        };
      }
      
      if (r['fosforo_medio'] != null) {
        medias['Fósforo'] = {
          'valor': r['fosforo_medio'] as double,
          'periodo': '$anosAtras anos',
        };
      }
      
      if (r['potassio_medio'] != null) {
        medias['Potássio'] = {
          'valor': r['potassio_medio'] as double,
          'periodo': '$anosAtras anos',
        };
      }
    }
    
    return medias;
  }
  
  // Método auxiliar para obter ID da safra a partir do ano
  Future<int?> _getSafraIdPorAno(int ano) async {
    final db = await _getDatabase();
    
    final List<Map<String, dynamic>> safras = await db.query(
      _tabelaSafras,
      where: 'ano = ?',
      whereArgs: [ano],
      limit: 1,
    );
    
    if (safras.isNotEmpty) {
      return safras.first['id'] as int;
    }
    
    return null;
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:latlong2/latlong.dart';
import '../../models/talhoes/talhao_safra_model.dart';
import '../../database/app_database.dart';
import '../../utils/logger.dart';
import '../../services/cultura_service.dart';

/// Repositório para gerenciar talhões com safras
class TalhaoSafraRepository {
  final AppDatabase _appDatabase = AppDatabase();

  Future<Database> get database async => await _appDatabase.database;

  // Nome das tabelas
  static const String tabelaTalhao = 'talhao_safra';
  static const String tabelaPoligono = 'talhao_poligono';
  static const String tabelaSafraTalhao = 'safra_talhao';

  /// Garante que as tabelas estão inicializadas
  Future<void> _ensureTablesExist() async {
    try {
      Logger.info('🔄 Verificando se as tabelas talhao_safra existem...');
      final db = await database;
      
      // Verificar se as tabelas existem
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name IN (?, ?, ?)',
        whereArgs: ['table', tabelaTalhao, tabelaPoligono, tabelaSafraTalhao],
      );
      
      Logger.info('📊 Tabelas encontradas: ${tables.length}');
      for (final table in tables) {
        Logger.info('  - ${table['name']}');
      }
      
      if (tables.length < 3) {
        Logger.info('🔄 Criando tabelas faltantes...');
        await inicializarTabelas(db);
        Logger.info('✅ Tabelas talhao_safra criadas com sucesso');
      } else {
        Logger.info('✅ Tabelas talhao_safra já existem');
      }
    } catch (e) {
      Logger.error('❌ Erro ao verificar/criar tabelas talhao_safra: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Inicializa as tabelas no banco de dados
  Future<void> inicializarTabelas(Database db) async {
    Logger.info('🔧 Inicializando tabelas talhao_safra...');
    
    // Tabela de talhões
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaTalhao (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        idFazenda TEXT NOT NULL,
        area REAL,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0
      )
    ''');

    // Tabela de polígonos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaPoligono (
        id TEXT PRIMARY KEY,
        idTalhao TEXT NOT NULL,
        pontos TEXT NOT NULL,
        FOREIGN KEY (idTalhao) REFERENCES $tabelaTalhao (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de safras por talhão
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaSafraTalhao (
        id TEXT PRIMARY KEY,
        idTalhao TEXT NOT NULL,
        idSafra TEXT NOT NULL,
        idCultura TEXT NOT NULL,
        culturaNome TEXT NOT NULL,
        culturaCor INTEGER NOT NULL,
        imagemCultura TEXT,
        area REAL NOT NULL,
        dataCadastro TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        FOREIGN KEY (idTalhao) REFERENCES $tabelaTalhao (id) ON DELETE CASCADE
      )
    ''');
    
    Logger.info('✅ Tabelas talhao_safra criadas com sucesso');
  }

  /// Adiciona um novo talhão com safra
  Future<String> adicionarTalhao(TalhaoSafraModel talhao) async {
    try {
      Logger.info('🔄 Iniciando adição de talhão: ${talhao.nome}');
      Logger.info('📊 Dados do talhão:');
      Logger.info('  - ID: ${talhao.id}');
      Logger.info('  - Nome: ${talhao.nome}');
      Logger.info('  - Fazenda: ${talhao.idFazenda}');
      Logger.info('  - Área: ${talhao.area} ha');
      Logger.info('  - Polígonos: ${talhao.poligonos.length}');
      Logger.info('  - Safras: ${talhao.safras.length}');
      
      await _ensureTablesExist();
      final db = await database;
      
      Logger.info('✅ Banco de dados conectado');
      
      await db.transaction((txn) async {
        Logger.info('🔄 Iniciando transação...');
        
        // Inserir o talhão
        Logger.info('🔄 Inserindo talhão na tabela $tabelaTalhao...');
        await txn.insert(
          tabelaTalhao,
          {
            'id': talhao.id,
            'nome': talhao.nome,
            'idFazenda': talhao.idFazenda,
            'area': talhao.area,
            'dataCriacao': talhao.dataCriacao.toIso8601String(),
            'dataAtualizacao': talhao.dataAtualizacao.toIso8601String(),
            'sincronizado': talhao.sincronizado ? 1 : 0,
          },
        );
        Logger.info('✅ Talhão inserido com sucesso');
        
        // Inserir os polígonos
        Logger.info('🔄 Inserindo ${talhao.poligonos.length} polígonos...');
        for (var i = 0; i < talhao.poligonos.length; i++) {
          final poligono = talhao.poligonos[i];
          Logger.info('🔄 Inserindo polígono $i: ${poligono.id}');
          Logger.info('📊 Pontos do polígono: ${poligono.pontos.length}');
          
          // Converter pontos para string de forma mais robusta
          final pontosString = poligono.pontos.map((p) => '${p.latitude},${p.longitude}').join(';');
          Logger.info('📊 String de pontos: $pontosString');
          
          await txn.insert(
            tabelaPoligono,
            {
              'id': '${talhao.id}_$i',
              'idTalhao': talhao.id,
              'pontos': pontosString,
            },
          );
          Logger.info('✅ Polígono $i inserido com sucesso');
        }
        
        // Inserir as safras
        Logger.info('🔄 Inserindo ${talhao.safras.length} safras...');
        for (var safra in talhao.safras) {
          Logger.info('🔄 Inserindo safra: ${safra.id}');
          Logger.info('🔍 DEBUG CULTURA - Salvando safra:');
          Logger.info('  - ID: ${safra.id}');
          Logger.info('  - Cultura ID: ${safra.idCultura}');
          Logger.info('  - Cultura Nome: ${safra.culturaNome}');
          Logger.info('  - Cultura Cor (value): ${safra.culturaCor.value}');
          Logger.info('  - Cultura Cor (hex): #${safra.culturaCor.value.toRadixString(16).substring(2)}');
          
          await txn.insert(
            tabelaSafraTalhao,
            {
              'id': safra.id,
              'idTalhao': talhao.id,
              'idSafra': safra.idSafra,
              'idCultura': safra.idCultura,
              'culturaNome': safra.culturaNome,
              'culturaCor': safra.culturaCor.value,
              'imagemCultura': safra.imagemCultura,
              'area': safra.area,
              'dataCadastro': safra.dataCadastro.toIso8601String(),
              'dataAtualizacao': safra.dataAtualizacao.toIso8601String(),
              'sincronizado': safra.sincronizado ? 1 : 0,
            },
          );
          Logger.info('✅ Safra inserida com sucesso');
        }
        
        Logger.info('✅ Transação concluída com sucesso');
      });
      
      Logger.info('✅ Talhão adicionado com sucesso: ${talhao.id}');
      return talhao.id;
      
    } catch (e) {
      Logger.error('❌ Erro ao adicionar talhão: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Atualiza um talhão existente
  Future<void> atualizarTalhao(TalhaoSafraModel talhao) async {
    await _ensureTablesExist();
    final db = await database;
    
    Logger.info('🔄 Atualizando talhão: ${talhao.name}');
    Logger.info('📊 Dados do talhão para atualização:');
    Logger.info('  - ID: ${talhao.id}');
    Logger.info('  - Nome: ${talhao.name}');
    Logger.info('  - Área: ${talhao.area} ha');
    Logger.info('  - Safras: ${talhao.safras.length}');
    
    await db.transaction((txn) async {
      // Atualizar o talhão
      await txn.update(
        tabelaTalhao,
        {
          'nome': talhao.name,
          'idFazenda': talhao.idFazenda,
          'area': talhao.area,
          'dataAtualizacao': DateTime.now().toIso8601String(),
          'sincronizado': 0, // Marca como não sincronizado após atualização
        },
        where: 'id = ?',
        whereArgs: [talhao.id],
      );
      Logger.info('✅ Talhão atualizado na tabela principal');
      
      // CORREÇÃO: Atualizar safras com as culturas corretas
      Logger.info('🔄 Atualizando ${talhao.safras.length} safras...');
      for (var safra in talhao.safras) {
        Logger.info('🔍 DEBUG CULTURA - Atualizando safra:');
        Logger.info('  - ID: ${safra.id}');
        Logger.info('  - Cultura ID: ${safra.idCultura}');
        Logger.info('  - Cultura Nome: ${safra.culturaNome}');
        Logger.info('  - Cultura Cor: ${safra.culturaCor.value}');
        
        await txn.update(
          tabelaSafraTalhao,
          {
            'idSafra': safra.idSafra,
            'idCultura': safra.idCultura,
            'culturaNome': safra.culturaNome,
            'culturaCor': safra.culturaCor.value,
            'imagemCultura': safra.imagemCultura,
            'area': safra.area,
            'dataAtualizacao': DateTime.now().toIso8601String(),
            'sincronizado': 0, // Marca como não sincronizado após atualização
          },
          where: 'id = ?',
          whereArgs: [safra.id],
        );
        Logger.info('✅ Safra atualizada: ${safra.culturaNome}');
      }
      
      // Remover polígonos antigos
      await txn.delete(
        tabelaPoligono,
        where: 'idTalhao = ?',
        whereArgs: [talhao.id],
      );
      
      // Inserir os novos polígonos
      for (var i = 0; i < talhao.poligonos.length; i++) {
        final poligono = talhao.poligonos[i];
        await txn.insert(
          tabelaPoligono,
          {
            'id': '${talhao.id}_$i',
            'idTalhao': talhao.id,
            'pontos': poligono.toMap()['pontos'],
          },
        );
      }
    });
    
    Logger.info('✅ Talhão atualizado com sucesso: ${talhao.name}');
  }

  /// Adiciona uma safra a um talhão existente
  Future<String> adicionarSafraTalhao(SafraTalhaoModel safra) async {
    await _ensureTablesExist();
    final db = await database;
    
    await db.insert(
      tabelaSafraTalhao,
      {
        'id': safra.id,
        'idTalhao': safra.idTalhao,
        'idSafra': safra.idSafra,
        'idCultura': safra.idCultura,
        'culturaNome': safra.culturaNome,
        'culturaCor': safra.culturaCor.value,
        'imagemCultura': safra.imagemCultura,
        'area': safra.area,
        'dataCadastro': safra.dataCadastro.toIso8601String(),
        'dataAtualizacao': safra.dataAtualizacao.toIso8601String(),
        'sincronizado': safra.sincronizado ? 1 : 0,
      },
    );
    
    return safra.id;
  }

  /// Atualiza uma safra de talhão existente
  Future<void> atualizarSafraTalhao(SafraTalhaoModel safra) async {
    await _ensureTablesExist();
    final db = await database;
    
    await db.update(
      tabelaSafraTalhao,
      {
        'idSafra': safra.idSafra,
        'idCultura': safra.idCultura,
        'culturaNome': safra.culturaNome,
        'culturaCor': safra.culturaCor.value,
        'imagemCultura': safra.imagemCultura,
        'area': safra.area,
        'dataAtualizacao': DateTime.now().toIso8601String(),
        'sincronizado': 0, // Marca como não sincronizado após atualização
      },
      where: 'id = ?',
      whereArgs: [safra.id],
    );
  }

  /// Remove um talhão e todas as suas safras
  Future<void> removerTalhao(String id) async {
    await _ensureTablesExist();
    final db = await database;
    
    Logger.info('🗑️ Iniciando remoção do talhão: $id');
    
    await db.transaction((txn) async {
      // Remover safras
      final safrasRemovidas = await txn.delete(
        tabelaSafraTalhao,
        where: 'idTalhao = ?',
        whereArgs: [id],
      );
      Logger.info('📊 Safras removidas: $safrasRemovidas');
      
      // Remover polígonos
      final poligonosRemovidos = await txn.delete(
        tabelaPoligono,
        where: 'idTalhao = ?',
        whereArgs: [id],
      );
      Logger.info('📊 Polígonos removidos: $poligonosRemovidos');
      
      // Remover talhão
      final talhaoRemovido = await txn.delete(
        tabelaTalhao,
        where: 'id = ?',
        whereArgs: [id],
      );
      Logger.info('📊 Talhão removido: $talhaoRemovido');
    });
    
    Logger.info('✅ Talhão $id removido com sucesso do banco de dados');
    
    // VERIFICAR se realmente foi removido
    final verificacao = await db.query(
      tabelaTalhao,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (verificacao.isEmpty) {
      Logger.info('✅ CONFIRMADO: Talhão não existe mais no banco');
    } else {
      Logger.error('❌ ERRO: Talhão ainda existe no banco após deleção!');
    }
  }

  /// Remove uma safra de talhão
  Future<void> removerSafraTalhao(String id) async {
    await _ensureTablesExist();
    final db = await database;
    
    await db.delete(
      tabelaSafraTalhao,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca todos os talhões da fazenda atual
  Future<List<TalhaoSafraModel>> buscarTalhoesPorFazenda(String idFazenda) async {
    // Não usamos mais o _perfilService para obter a fazenda atual
    // O ID da fazenda agora é passado como parâmetro
    if (idFazenda.isEmpty) return [];
    
    return buscarTalhoesPorIdFazenda(idFazenda);
  }

  /// Lista todos os talhões (para integração com módulo de monitoramento)
  /// Lista todos os talhões (alias para getAllTalhoes)
  Future<List<TalhaoSafraModel>> getAllTalhoes() async {
    return listarTodosTalhoes();
  }

  /// Salva um talhão (alias para adicionarTalhao)
  Future<void> salvarTalhao(TalhaoSafraModel talhao) async {
    await adicionarTalhao(talhao);
  }

  /// Exclui um talhão (alias para removerTalhao)
  Future<void> excluirTalhao(String id) async {
    return removerTalhao(id);
  }

  Future<List<TalhaoSafraModel>> listarTodosTalhoes() async {
    await _ensureTablesExist();
    final db = await database;
    
    Logger.info('🔄 Listando todos os talhões...');
    
    // Buscar todos os talhões
    final talhoes = await db.query(tabelaTalhao);
    
    Logger.info('📊 ${talhoes.length} talhões encontrados no banco');
    
    if (talhoes.isEmpty) {
      Logger.info('ℹ️ Nenhum talhão encontrado');
      return [];
    }
    
    // Carregar dados completos de cada talhão
    final talhoesCompletos = await Future.wait(
      talhoes.map((t) => _carregarTalhaoCompleto(t)).toList()
    );
    
    Logger.info('✅ ${talhoesCompletos.length} talhões carregados com sucesso');
    
    return talhoesCompletos;
  }

  /// Método para forçar atualização dos talhões (corrige problemas de cultura)
  Future<List<TalhaoSafraModel>> forcarAtualizacaoTalhoes() async {
    Logger.info('🔄 Forçando atualização dos talhões para corrigir problemas de cultura...');
    
    await _ensureTablesExist();
    final db = await database;
    
    // Limpar cache se existir
    try {
      await db.execute('PRAGMA cache_size = 0');
      await db.execute('PRAGMA cache_size = 1000');
    } catch (e) {
      Logger.warning('⚠️ Erro ao limpar cache: $e');
    }
    
    // Buscar todos os talhões com informações detalhadas
    final talhoes = await db.query(
      tabelaTalhao,
      orderBy: 'dataAtualizacao DESC',
    );
    
    Logger.info('📊 ${talhoes.length} talhões encontrados para atualização');
    
    if (talhoes.isEmpty) {
      return [];
    }
    
    // Carregar dados completos com logs detalhados
    final talhoesCompletos = <TalhaoSafraModel>[];
    
    for (final talhaoMap in talhoes) {
      try {
        Logger.info('🔄 Carregando talhão: ${talhaoMap['nome']} (ID: ${talhaoMap['id']})');
        
        final talhaoCompleto = await _carregarTalhaoCompleto(talhaoMap);
        
        // Verificar se a cultura está correta
        if (talhaoCompleto.safras.isNotEmpty) {
          final primeiraSafra = talhaoCompleto.safras.first;
          Logger.info('🔍 VERIFICAÇÃO CULTURA - Talhão ${talhaoCompleto.nome}:');
          Logger.info('  - Cultura ID: "${primeiraSafra.idCultura}"');
          Logger.info('  - Cultura Nome: "${primeiraSafra.culturaNome}"');
          Logger.info('  - Cultura Cor: ${primeiraSafra.culturaCor.value}');
          
          // Se a cultura está vazia ou incorreta, tentar corrigir
          if (primeiraSafra.idCultura.isEmpty || primeiraSafra.culturaNome.isEmpty) {
            Logger.warning('⚠️ Cultura incorreta detectada, marcando para correção');
            // Aqui você pode implementar lógica de correção se necessário
          }
        }
        
        talhoesCompletos.add(talhaoCompleto);
      } catch (e) {
        Logger.error('❌ Erro ao carregar talhão ${talhaoMap['id']}: $e');
      }
    }
    
    Logger.info('✅ ${talhoesCompletos.length} talhões atualizados com sucesso');
    return talhoesCompletos;
  }

  /// Método para corrigir problemas de cultura nos talhões existentes
  Future<void> corrigirCulturasTalhoes() async {
    Logger.info('🔧 Iniciando correção de culturas nos talhões...');
    
    await _ensureTablesExist();
    final db = await database;
    
    // Buscar todas as safras com problemas de cultura
    final safrasProblematicas = await db.query(
      tabelaSafraTalhao,
      where: 'idCultura IS NULL OR idCultura = "" OR culturaNome IS NULL OR culturaNome = ""',
    );
    
    Logger.info('📊 ${safrasProblematicas.length} safras com problemas de cultura encontradas');
    
    if (safrasProblematicas.isEmpty) {
      Logger.info('✅ Nenhuma safra com problemas de cultura encontrada');
      return;
    }
    
    // Buscar culturas disponíveis para correção
    try {
      // Tentar obter culturas do módulo de culturas
      final culturaService = CulturaService();
      final culturas = await culturaService.loadCulturas();
      
      if (culturas.isEmpty) {
        Logger.warning('⚠️ Nenhuma cultura disponível para correção');
        return;
      }
      
      Logger.info('📋 ${culturas.length} culturas disponíveis para correção');
      
      // Corrigir cada safra problemática
      for (final safra in safrasProblematicas) {
        try {
          // Usar a primeira cultura disponível como padrão
          final culturaPadrao = culturas.first;
          
          Logger.info('🔧 Corrigindo safra ${safra['id']} com cultura padrão: ${culturaPadrao.name}');
          
          await db.update(
            tabelaSafraTalhao,
            {
              'idCultura': culturaPadrao.id,
              'culturaNome': culturaPadrao.name,
              'culturaCor': culturaPadrao.color.value,
              'dataAtualizacao': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [safra['id']],
          );
          
          Logger.info('✅ Safra ${safra['id']} corrigida com sucesso');
        } catch (e) {
          Logger.error('❌ Erro ao corrigir safra ${safra['id']}: $e');
        }
      }
      
      Logger.info('✅ Correção de culturas concluída');
    } catch (e) {
      Logger.error('❌ Erro ao executar correção de culturas: $e');
    }
  }

  /// Busca talhões por ID da fazenda
  Future<List<TalhaoSafraModel>> buscarTalhoesPorIdFazenda(String idFazenda) async {
    await _ensureTablesExist();
    final db = await database;
    
    // Buscar talhões
    final talhoes = await db.query(
      tabelaTalhao,
      where: 'idFazenda = ?',
      whereArgs: [idFazenda],
    );
    
    return Future.wait(talhoes.map((t) => _carregarTalhaoCompleto(t)).toList());
  }

  /// Busca talhões por safra
  Future<List<TalhaoSafraModel>> buscarTalhoesPorSafra(String idSafra) async {
    await _ensureTablesExist();
    final db = await database;
    
    // Buscar IDs de talhões que têm esta safra
    final safrasTalhoes = await db.query(
      tabelaSafraTalhao,
      columns: ['idTalhao'],
      where: 'idSafra = ?',
      whereArgs: [idSafra],
      distinct: true,
    );
    
    if (safrasTalhoes.isEmpty) return [];
    
    final idsTalhoes = safrasTalhoes.map((s) => s['idTalhao'] as String).toList();
    
    // Buscar talhões
    final talhoes = await db.query(
      tabelaTalhao,
      where: 'id IN (${List.filled(idsTalhoes.length, '?').join(',')})',
      whereArgs: idsTalhoes,
    );
    
    return Future.wait(talhoes.map((t) => _carregarTalhaoCompleto(t)).toList());
  }

  /// Busca um talhão pelo ID
  Future<TalhaoSafraModel?> buscarTalhaoPorId(String id) async {
    await _ensureTablesExist();
    final db = await database;
    
    final talhoes = await db.query(
      tabelaTalhao,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (talhoes.isEmpty) return null;
    
    return _carregarTalhaoCompleto(talhoes.first);
  }

  /// Carrega um talhão completo com polígonos e safras
  Future<TalhaoSafraModel> _carregarTalhaoCompleto(Map<String, dynamic> talhaoMap) async {
    final db = await database;
    
    Logger.info('🔄 Carregando talhão completo: ${talhaoMap['id']}');
    
    // Buscar polígonos
    final poligonos = await db.query(
      tabelaPoligono,
      where: 'idTalhao = ?',
      whereArgs: [talhaoMap['id']],
    );
    
    Logger.info('📊 ${poligonos.length} polígonos encontrados para o talhão');
    
    final poligonosModels = poligonos.map((p) {
      Logger.info('🔄 Processando polígono: ${p['pontos']}');
      
      // Verificar se os pontos são válidos
      if (p['pontos'] == null || p['pontos'].toString().isEmpty) {
        Logger.warning('⚠️ Polígono sem pontos válidos');
        return null;
      }
      
      try {
        // Converter pontos manualmente para garantir compatibilidade
        final pontosString = p['pontos'] as String;
        final pontosArray = pontosString.split(';');
        final pontos = <LatLng>[];
        
        Logger.info('📊 Processando ${pontosArray.length} pontos da string');
        
        for (var ponto in pontosArray) {
          if (ponto.trim().isEmpty) continue;
          
          final coords = ponto.split(',');
          if (coords.length >= 2) {
            final lat = double.tryParse(coords[0].trim());
            final lng = double.tryParse(coords[1].trim());
            
            if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
              pontos.add(LatLng(lat, lng));
              Logger.info('✅ Ponto válido: $lat, $lng');
            } else {
              Logger.warning('⚠️ Ponto inválido: $ponto');
            }
          } else {
            Logger.warning('⚠️ Formato de ponto inválido: $ponto');
          }
        }
        
        Logger.info('📊 ${pontos.length} pontos válidos convertidos');
        
        if (pontos.length >= 3) {
          // Criar polígono com pontos convertidos manualmente
          final poligonoModel = PoligonoModel(
            id: (p['id'] as String?) ?? '',
            talhaoId: (p['idTalhao'] as String?) ?? '',
            pontos: pontos,
            area: 0, // Será calculado depois
            perimetro: 0, // Será calculado depois
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
            ativo: true,
          );
          
          Logger.info('✅ Polígono válido criado com ${pontos.length} pontos');
          return poligonoModel;
        } else {
          Logger.warning('⚠️ Polígono com menos de 3 pontos válidos: ${pontos.length}');
          return null;
        }
      } catch (e) {
        Logger.error('❌ Erro ao processar polígono: $e');
        return null;
      }
    }).where((p) => p != null).cast<PoligonoModel>().toList();
    
    // Buscar safras
    final safras = await db.query(
      tabelaSafraTalhao,
      where: 'idTalhao = ?',
      whereArgs: [talhaoMap['id']],
    );
    
    Logger.info('📊 ${safras.length} safras encontradas para o talhão');
    
    final safrasModels = safras.map((s) {
      // Log detalhado dos dados de cultura do banco
      Logger.info('🔍 DEBUG CULTURA - Dados do banco para safra ${s['id']}:');
      Logger.info('  - idCultura do banco: "${s['idCultura']}"');
      Logger.info('  - culturaNome do banco: "${s['culturaNome']}"');
      Logger.info('  - culturaCor do banco: "${s['culturaCor']}" (tipo: ${s['culturaCor'].runtimeType})');
      
      final safraModel = SafraTalhaoModel.fromMap({
        'id': s['id'],
        'idTalhao': s['idTalhao'],
        'idSafra': s['idSafra'],
        'idCultura': s['idCultura'],
        'culturaNome': s['culturaNome'],
        'culturaCor': s['culturaCor'],
        'imagemCultura': s['imagemCultura'],
        'area': s['area'],
        'dataCadastro': s['dataCadastro'],
        'dataAtualizacao': s['dataAtualizacao'],
        'sincronizado': s['sincronizado'],
      });
      
      // Log do modelo criado
      Logger.info('🔍 DEBUG CULTURA - Modelo criado:');
      Logger.info('  - idCultura: "${safraModel.idCultura}"');
      Logger.info('  - culturaNome: "${safraModel.culturaNome}"');
      Logger.info('  - culturaCor (value): ${safraModel.culturaCor.value}');
      Logger.info('  - culturaCor (hex): #${safraModel.culturaCor.value.toRadixString(16).substring(2)}');
      
      return safraModel;
    }).toList();
    
    // Log para debug da área
    final areaOriginal = talhaoMap['area'];
    final areaConvertida = talhaoMap['area'] != null ? (talhaoMap['area'] is double ? talhaoMap['area'] : double.tryParse(talhaoMap['area'].toString())) : null;
    
    Logger.info('🔍 [REPO] Talhão ${talhaoMap['nome']}: área original = $areaOriginal (tipo: ${areaOriginal.runtimeType})');
    Logger.info('🔍 [REPO] Talhão ${talhaoMap['nome']}: área convertida = $areaConvertida (tipo: ${areaConvertida.runtimeType})');
    
    // Criar o modelo completo
    final talhaoCompleto = TalhaoSafraModel(
      id: talhaoMap['id'] as String,
      name: talhaoMap['nome'] as String,
      idFazenda: talhaoMap['idFazenda'] as String,
      poligonos: poligonosModels,
      safras: safrasModels,
      dataCriacao: DateTime.parse(talhaoMap['dataCriacao'] as String),
      dataAtualizacao: DateTime.parse(talhaoMap['dataAtualizacao'] as String),
      sincronizado: talhaoMap['sincronizado'] == 1,
      area: areaConvertida,
    );
    
    Logger.info('✅ Talhão completo carregado: ${talhaoCompleto.nome} com ${talhaoCompleto.poligonos.length} polígonos');
    
    return talhaoCompleto;
  }
  
  /// Método de teste para verificar se as tabelas estão funcionando
  Future<void> testarTabelas() async {
    try {
      Logger.info('🧪 Iniciando teste das tabelas de talhões...');
      
      await _ensureTablesExist();
      final db = await database;
      
      // Verificar se as tabelas existem
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name IN (?, ?, ?)',
        whereArgs: ['table', tabelaTalhao, tabelaPoligono, tabelaSafraTalhao],
      );
      
      Logger.info('📊 Tabelas encontradas: ${tables.length}');
      for (final table in tables) {
        Logger.info('  - ${table['name']}');
      }
      
      // Verificar se há dados nas tabelas
      final talhoesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tabelaTalhao')
      ) ?? 0;
      
      final poligonosCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tabelaPoligono')
      ) ?? 0;
      
      final safrasCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tabelaSafraTalhao')
      ) ?? 0;
      
      Logger.info('📊 Contagem de dados:');
      Logger.info('  - Talhões: $talhoesCount');
      Logger.info('  - Polígonos: $poligonosCount');
      Logger.info('  - Safras: $safrasCount');
      
      // Mostrar detalhes dos talhões
      if (talhoesCount > 0) {
        final talhoes = await db.query(tabelaTalhao);
        Logger.info('📋 Detalhes dos talhões:');
        for (var talhao in talhoes) {
          Logger.info('  - ${talhao['nome']} (ID: ${talhao['id']})');
        }
      }
      
      // Mostrar detalhes dos polígonos
      if (poligonosCount > 0) {
        final poligonos = await db.query(tabelaPoligono);
        Logger.info('📋 Detalhes dos polígonos:');
        for (var poligono in poligonos) {
          final pontos = poligono['pontos'] as String? ?? '';
          Logger.info('  - Talhão: ${poligono['idTalhao']}, Pontos: ${pontos.length} chars');
        }
      }
      
      // Testar carregamento completo
      final talhoesCompletos = await listarTodosTalhoes();
      Logger.info('📊 Talhões completos carregados: ${talhoesCompletos.length}');
      
      for (var talhao in talhoesCompletos) {
        Logger.info('📋 Talhão: ${talhao.nome}');
        Logger.info('  - Polígonos: ${talhao.poligonos.length}');
        Logger.info('  - Safras: ${talhao.safras.length}');
        
        for (var poligono in talhao.poligonos) {
          Logger.info('    - Polígono: ${poligono.pontos.length} pontos');
        }
      }
      
      Logger.info('✅ Teste das tabelas concluído');
      
    } catch (e) {
      Logger.error('❌ Erro no teste das tabelas: $e');
      rethrow;
    }
  }

  /// Verifica se há talhões salvos no banco
  Future<bool> hasTalhoesSalvos() async {
    try {
      await _ensureTablesExist();
      final db = await database;
      
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tabelaTalhao')
      ) ?? 0;
      
      Logger.info('📊 Verificação de talhões salvos: $count talhões encontrados');
      return count > 0;
    } catch (e) {
      Logger.error('❌ Erro ao verificar talhões salvos: $e');
      return false;
    }
  }

}

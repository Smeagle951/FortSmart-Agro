import 'package:sqflite/sqflite.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';
import 'package:fortsmart_agro/modules/planting/repositories/plantio_repository.dart';
import 'package:fortsmart_agro/database/repositories/historico_plantio_repository.dart';
import 'package:fortsmart_agro/database/models/historico_plantio_model.dart';
import 'package:fortsmart_agro/services/talhao_service.dart';

/// Serviço de integração entre todos os módulos de plantio
/// Este é o "motor" que unifica dados de plantio, histórico e evolução fenológica
class PlantioIntegrationService {
  static final PlantioIntegrationService _instance = PlantioIntegrationService._internal();
  
  factory PlantioIntegrationService() {
    return _instance;
  }
  
  PlantioIntegrationService._internal();
  
  final PlantioRepository _plantioRepository = PlantioRepository();
  final HistoricoPlantioRepository _historicoRepository = HistoricoPlantioRepository();
  final TalhaoService _talhaoService = TalhaoService();
  
  /// Busca o nome do talhão pelo ID
  Future<String> _buscarNomeTalhao(String talhaoId) async {
    try {
      final talhao = await _talhaoService.obterPorId(talhaoId);
      return talhao?.name ?? 'Talhão $talhaoId';
    } catch (e) {
      print('⚠️ Erro ao buscar nome do talhão $talhaoId: $e');
      return 'Talhão $talhaoId';
    }
  }

  /// Busca todos os plantios com dados integrados
  Future<List<PlantioIntegrado>> buscarPlantiosIntegrados() async {
    try {
      print('🔄 INTEGRAÇÃO: Buscando plantios integrados...');
      
      // 1. Buscar plantios da tabela principal
      final plantios = await _plantioRepository.listar();
      print('📋 INTEGRAÇÃO: ${plantios.length} plantios encontrados na tabela principal');
      
      // 2. Buscar dados do histórico
      final historicos = await _historicoRepository.listarTodos();
      print('📋 INTEGRAÇÃO: ${historicos.length} registros no histórico');
      
      // 3. Extrair plantios do histórico
      final plantiosHistorico = await _extrairPlantiosDoHistorico(historicos);
      print('📋 INTEGRAÇÃO: ${plantiosHistorico.length} plantios extraídos do histórico');
      
      // 4. Buscar plantios do submódulo "Novo Plantio" (tabela alternativa)
      final plantiosSubmodulo = await _buscarPlantiosSubmodulo();
      print('📋 INTEGRAÇÃO: ${plantiosSubmodulo.length} plantios do submódulo');
      
      // 5. Integrar todos os dados
      final plantiosIntegrados = <PlantioIntegrado>[];
      
      // Processar plantios da tabela principal
      for (final plantio in plantios) {
        final talhaoNome = await _buscarNomeTalhao(plantio.talhaoId);
        final integrado = PlantioIntegrado.fromPlantioModel(plantio, talhaoNome);
        
        // Buscar histórico relacionado
        final historicoRelacionado = historicos.where((h) => 
          h.talhaoId == plantio.talhaoId && h.culturaId == plantio.culturaId
        ).toList();
        
        integrado.historicos = historicoRelacionado;
        plantiosIntegrados.add(integrado);
      }
      
      // Processar plantios do histórico que não estão na tabela principal
      for (final plantioHist in plantiosHistorico) {
        final jaExiste = plantiosIntegrados.any((p) => 
          p.talhaoId == plantioHist['talhao_id'] && 
          p.culturaId == plantioHist['cultura_id']
        );
        
        if (!jaExiste) {
          // ✅ PRIORIDADE: nome_talhao do registro > buscar do banco
          String talhaoNome;
          if (plantioHist.containsKey('talhao_nome') && 
              plantioHist['talhao_nome'] != null && 
              plantioHist['talhao_nome'].toString().isNotEmpty) {
            talhaoNome = plantioHist['talhao_nome'].toString();
            print('✅ Nome do talhão do histórico: $talhaoNome');
          } else {
            talhaoNome = await _buscarNomeTalhao(plantioHist['talhao_id']);
            print('📋 Nome do talhão do banco: $talhaoNome');
          }
          
          final integrado = PlantioIntegrado.fromHistoricoData(plantioHist, talhaoNome);
          
          // Buscar histórico relacionado
          final historicoRelacionado = historicos.where((h) => 
            h.talhaoId == plantioHist['talhao_id'] && h.culturaId == plantioHist['cultura_id']
          ).toList();
          
          integrado.historicos = historicoRelacionado;
          plantiosIntegrados.add(integrado);
        }
      }
      
      // Processar plantios do submódulo que não estão nas outras fontes
      for (final plantioSub in plantiosSubmodulo) {
        final jaExiste = plantiosIntegrados.any((p) => 
          p.talhaoId == plantioSub['talhao_id'] && 
          p.culturaId == plantioSub['cultura']
        );
        
        if (!jaExiste) {
          final talhaoNome = await _buscarNomeTalhao(plantioSub['talhao_id']);
          final integrado = PlantioIntegrado.fromSubmoduloData(plantioSub, talhaoNome);
          
          // Buscar histórico relacionado
          final historicoRelacionado = historicos.where((h) => 
            h.talhaoId == plantioSub['talhao_id'] && h.culturaId == plantioSub['cultura']
          ).toList();
          
          integrado.historicos = historicoRelacionado;
          plantiosIntegrados.add(integrado);
        }
      }
      
      print('✅ INTEGRAÇÃO: ${plantiosIntegrados.length} plantios integrados criados');
      
      // Ordenar por data de plantio (mais recente primeiro)
      plantiosIntegrados.sort((a, b) => b.dataPlantio.compareTo(a.dataPlantio));
      
      return plantiosIntegrados;
      
    } catch (e, stackTrace) {
      print('❌ INTEGRAÇÃO: Erro ao buscar plantios integrados: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
  
  /// Normaliza um plantio de qualquer tabela para um formato padrão
  Map<String, dynamic> _normalizarPlantio(Map<String, dynamic> plantio, String tabelaOrigem) {
    // Campos padronizados
    final String id = plantio['id']?.toString() ?? '';
    final String talhaoId = (plantio['talhao_id'] ?? plantio['talhaold'] ?? plantio['plotId'])?.toString() ?? '';
    final String cultura = (plantio['cultura_id'] ?? plantio['cultura'] ?? plantio['culturald'] ?? plantio['cropId'])?.toString() ?? '';
    final String variedade = (plantio['variedade_id'] ?? plantio['variedadeld'] ?? plantio['varietyId'] ?? plantio['variedade'])?.toString() ?? '';
    final String dataPlantio = (plantio['data_plantio'] ?? plantio['dataPlantio'] ?? plantio['plantingDate'] ?? DateTime.now().toIso8601String()).toString();
    final double populacao = ((plantio['populacao'] ?? plantio['densidade'] ?? plantio['targetPopulation'] ?? 0) as num?)?.toDouble() ?? 0.0;
    final double espacamento = ((plantio['espacamento'] ?? plantio['rowSpacing'] ?? 0) as num?)?.toDouble() ?? 0.0;
    
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura': cultura,
      'variedade': variedade,
      'data_plantio': dataPlantio,
      'populacao': populacao,
      'espacamento': espacamento,
      'fonte_tabela': tabelaOrigem, // Marcar de qual tabela veio
      'dados_originais': plantio, // Manter dados originais para referência
    };
  }

  /// Busca plantios do submódulo "Novo Plantio" (tabela alternativa)
  Future<List<Map<String, dynamic>>> _buscarPlantiosSubmodulo() async {
    try {
      final db = await AppDatabase().database;
      
      // Primeiro, listar TODAS as tabelas para debug
      final todasTabelas = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('🔍 INTEGRAÇÃO: Todas as tabelas no banco:');
      for (final tabela in todasTabelas) {
        final nome = tabela['name'] as String;
        if (nome.toLowerCase().contains('plantio') || nome.toLowerCase().contains('planting')) {
          try {
            final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $nome')) ?? 0;
            print('  - $nome: $count registros');
          } catch (e) {
            print('  - $nome: erro ao contar ($e)');
          }
        }
      }
      
      // Buscar de TODAS as tabelas de plantio e combinar os resultados
      final todosPlantioscombinados = <Map<String, dynamic>>[];
      final tabelasPossiveis = ['plantio', 'plantios', 'novo_plantio', 'plantings'];
      
      for (final tabela in tabelasPossiveis) {
        try {
          final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$tabela'");
          if (result.isNotEmpty) {
            print('📋 INTEGRAÇÃO: Encontrada tabela $tabela');
            
            // Buscar apenas plantios não deletados
            List<Map<String, dynamic>> plantios = [];
            try {
              // Primeiro tentar com deleted_at
              plantios = await db.query(
                tabela,
                where: 'deleted_at IS NULL',
              );
            } catch (e) {
              // Se não houver coluna deleted_at, buscar todos
              print('  ⚠️  Tabela $tabela não tem coluna deleted_at, buscando todos');
              plantios = await db.query(tabela);
            }
            
            print('📋 INTEGRAÇÃO: ${plantios.length} registros na tabela $tabela');
            
            if (plantios.isNotEmpty) {
              // Normalizar os nomes das colunas para um padrão único
              final plantiosNormalizados = plantios.map((plantio) {
                return _normalizarPlantio(plantio, tabela);
              }).toList();
              
              todosPlantioscombinados.addAll(plantiosNormalizados);
              
              print('🔍 INTEGRAÇÃO: Amostra dos dados da tabela $tabela:');
              for (int i = 0; i < plantios.length && i < 2; i++) {
                final plantio = plantios[i];
                final talhaoId = plantio['talhao_id'] ?? plantio['talhaold'] ?? plantio['plotId'] ?? 'N/A';
                final cultura = plantio['cultura_id'] ?? plantio['cultura'] ?? plantio['culturald'] ?? plantio['cropId'] ?? 'N/A';
                print('  ${i + 1}: talhao=$talhaoId, cultura=$cultura');
              }
            }
          }
        } catch (e) {
          print('❌ INTEGRAÇÃO: Erro ao acessar tabela $tabela: $e');
        }
      }
      
      print('✅ INTEGRAÇÃO: Total de ${todosPlantioscombinados.length} plantios combinados de todas as tabelas');
      return todosPlantioscombinados;
      
    } catch (e) {
      print('❌ INTEGRAÇÃO: Erro ao buscar plantios do submódulo: $e');
      return [];
    }
  }
  
  /// Busca plantios por talhão e cultura para evolução fenológica
  Future<List<PlantioIntegrado>> buscarPlantiosParaEvolucaoFenologica(String? talhaoId, String? culturaId) async {
    try {
      print('🔄 EVOLUÇÃO: Buscando plantios para evolução fenológica...');
      print('🔍 EVOLUÇÃO: talhaoId=$talhaoId, culturaId=$culturaId');
      
      final todosPlantios = await buscarPlantiosIntegrados();
      
      if (talhaoId == null || culturaId == null) {
        print('📋 EVOLUÇÃO: Retornando todos os ${todosPlantios.length} plantios (sem filtro)');
        return todosPlantios;
      }
      
      final plantiosFiltrados = todosPlantios.where((plantio) {
        final matchTalhao = plantio.talhaoId == talhaoId;
        final matchCultura = plantio.culturaId == culturaId;
        return matchTalhao && matchCultura;
      }).toList();
      
      print('📋 EVOLUÇÃO: ${plantiosFiltrados.length} plantios encontrados para talhão $talhaoId e cultura $culturaId');
      
      return plantiosFiltrados;
      
    } catch (e) {
      print('❌ EVOLUÇÃO: Erro ao buscar plantios para evolução fenológica: $e');
      return [];
    }
  }
  
  /// Salva um plantio de forma integrada (tabela principal + histórico)
  Future<bool> salvarPlantioIntegrado(PlantioModel plantio) async {
    try {
      print('🔄 INTEGRAÇÃO: Salvando plantio integrado...');
      
      // 1. Salvar na tabela principal
      final resultado = await _plantioRepository.inserir(plantio);
      if (resultado == -1) {
        print('❌ INTEGRAÇÃO: Falha ao salvar na tabela principal');
        return false;
      }
      
      // 2. Salvar no histórico
      final historico = HistoricoPlantioModel(
        calculoId: plantio.id,
        talhaoId: plantio.talhaoId,
        safraId: plantio.safraId ?? '',
        culturaId: plantio.culturaId,
        tipo: 'novo_plantio',
        data: DateTime.now(),
        resumo: _gerarResumoPlantio(plantio),
      );
      
      await _historicoRepository.salvar(historico);
      
      print('✅ INTEGRAÇÃO: Plantio salvo com sucesso (principal + histórico)');
      return true;
      
    } catch (e) {
      print('❌ INTEGRAÇÃO: Erro ao salvar plantio integrado: $e');
      return false;
    }
  }
  
  /// Extrai plantios dos registros de histórico
  Future<List<Map<String, dynamic>>> _extrairPlantiosDoHistorico(List<HistoricoPlantioModel> historicos) async {
    final plantiosExtraidos = <Map<String, dynamic>>[];
    
    print('🔍 HISTÓRICO: Processando ${historicos.length} registros...');
    
    for (final historico in historicos) {
      print('  📝 Tipo: "${historico.tipo}", Talhão: ${historico.talhaoId}, Cultura: ${historico.culturaId}');
      
      // Aceitar TODOS os tipos de registros de plantio
      if (historico.tipo.toLowerCase().contains('plantio')) {
        try {
          // Tentar extrair dados do resumo
          final dadosPlantio = _parseResumoPlantio(historico.resumo);
          
          if (dadosPlantio != null && dadosPlantio.isNotEmpty) {
            dadosPlantio['id'] = historico.calculoId ?? historico.id.toString();
            dadosPlantio['talhao_id'] = historico.talhaoId;
            dadosPlantio['talhao_nome'] = historico.talhaoNome; // ✅ Adicionar nome do talhão
            dadosPlantio['cultura_id'] = historico.culturaId;
            dadosPlantio['data_plantio'] = historico.data.toIso8601String();
            dadosPlantio['created_at'] = historico.createdAt?.toIso8601String();
            dadosPlantio['fonte'] = 'historico';
            
            plantiosExtraidos.add(dadosPlantio);
            print('✅ HISTÓRICO: Plantio extraído - Tipo: ${historico.tipo}, Talhão: ${historico.talhaoNome ?? historico.talhaoId}, Cultura: ${historico.culturaId}');
          } else {
            print('⚠️ HISTÓRICO: Parse do resumo retornou vazio para registro ${historico.id}');
            print('   Resumo: ${historico.resumo.substring(0, historico.resumo.length > 100 ? 100 : historico.resumo.length)}...');
          }
        } catch (e) {
          print('⚠️ HISTÓRICO: Erro ao processar registro ${historico.id}: $e');
        }
      } else {
        print('  ⏭️  Tipo "${historico.tipo}" não contém "plantio" - ignorando');
      }
    }
    
    print('✅ HISTÓRICO: ${plantiosExtraidos.length} plantios extraídos de ${historicos.length} registros');
    return plantiosExtraidos;
  }
  
  /// Faz parse do resumo do plantio do histórico
  Map<String, dynamic>? _parseResumoPlantio(String resumo) {
    try {
      print('🔍 PARSE: Tentando fazer parse do resumo...');
      print('   Resumo original: ${resumo.substring(0, resumo.length > 200 ? 200 : resumo.length)}');
      
      final dados = <String, dynamic>{};
      
      // Formato Map.toString(): {cultura: Soja, variedade: NEO 810, ...}
      if (resumo.startsWith('{') && resumo.endsWith('}')) {
        print('   Formato detectado: Map toString()');
        
        // Remover chaves
        var conteudo = resumo.substring(1, resumo.length - 1);
        
        // Split por vírgula, mas cuidado com valores que contêm vírgula
        final pares = <String>[];
        var buffer = '';
        var dentroDeString = false;
        
        for (int i = 0; i < conteudo.length; i++) {
          final char = conteudo[i];
          
          if (char == ',' && !dentroDeString) {
            pares.add(buffer.trim());
            buffer = '';
          } else {
            buffer += char;
          }
        }
        if (buffer.isNotEmpty) {
          pares.add(buffer.trim());
        }
        
        print('   ${pares.length} pares encontrados');
        
        for (final par in pares) {
          final partes = par.split(':');
          if (partes.length >= 2) {
            var chave = partes[0].trim().toLowerCase();
            var valor = partes.sublist(1).join(':').trim();
            
            print('     $chave = $valor');
            
            // Normalizar chaves
            switch (chave) {
              case 'cultura':
                dados['cultura'] = valor;
                break;
              case 'variedade':
                dados['variedade'] = valor;
                break;
              case 'data_plantio':
                dados['data_plantio'] = valor;
                break;
              case 'espacamento_cm':
              case 'espaçamento':
                final espacamentoStr = valor.replaceAll(RegExp(r'[^\d.]'), '');
                dados['espacamento'] = double.tryParse(espacamentoStr) ?? 45.0;
                break;
              case 'populacao_por_m':
              case 'população':
                final populacaoStr = valor.replaceAll(RegExp(r'[^\d.]'), '');
                final popPorM = double.tryParse(populacaoStr) ?? 0;
                // Converter para plantas/ha
                dados['populacao'] = (popPorM * 10000).toInt();
                break;
              case 'observacao':
              case 'observações':
                dados['observacoes'] = valor;
                break;
            }
          }
        }
      }
      
      // ❌ REMOVIDO: Não usar valores padrão fictícios para população/espaçamento!
      // ✅ População e espaçamento devem vir APENAS do Estande de Plantas
      dados['populacao'] ??= 0; // 0 indica "não medido ainda"
      dados['espacamento'] ??= 0.0; // 0 indica "não medido ainda"
      dados['profundidade'] ??= 0.0; // 0 indica "não medido ainda"
      dados['variedade'] ??= 'Não definida';
      
      print('   ✅ Parse concluído: ${dados.keys.length} campos extraídos');
      print('   Dados: $dados');
      
      return dados.isNotEmpty ? dados : null;
      
    } catch (e) {
      print('❌ Erro ao fazer parse do resumo: $e');
      return null;
    }
  }

  /// Gera resumo do plantio para o histórico
  String _gerarResumoPlantio(PlantioModel plantio) {
    final resumo = {
      'Talhão': plantio.talhaoId,
      'Cultura': plantio.culturaId,
      'Variedade': plantio.variedadeId ?? 'Não definida',
      'Data do Plantio': plantio.dataPlantio.toIso8601String().split('T')[0],
      'População': '${plantio.populacao} plantas/ha',
      'Espaçamento': '${plantio.espacamento} cm',
      'Profundidade': '${plantio.profundidade} cm',
      'Observações': plantio.observacoes ?? 'Nenhuma',
    };
    
    return resumo.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

/// Classe para representar um plantio com dados integrados
class PlantioIntegrado {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String? variedadeId;
  final DateTime dataPlantio;
  final int populacao;
  final double espacamento;
  final double profundidade;
  final String? observacoes;
  final String fonte; // 'principal', 'submodulo', 'historico'
  
  List<HistoricoPlantioModel> historicos = [];
  
  PlantioIntegrado({
    required this.id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    this.variedadeId,
    required this.dataPlantio,
    required this.populacao,
    required this.espacamento,
    required this.profundidade,
    this.observacoes,
    required this.fonte,
  });
  
  /// Cria a partir de PlantioModel (tabela principal)
  factory PlantioIntegrado.fromPlantioModel(PlantioModel plantio, String talhaoNome) {
    return PlantioIntegrado(
      id: plantio.id,
      talhaoId: plantio.talhaoId,
      talhaoNome: talhaoNome,
      culturaId: plantio.culturaId,
      variedadeId: plantio.variedadeId,
      dataPlantio: plantio.dataPlantio,
      populacao: plantio.populacao,
      espacamento: plantio.espacamento,
      profundidade: plantio.profundidade,
      observacoes: plantio.observacoes,
      fonte: 'principal',
    );
  }
  
  /// Cria a partir de dados do submódulo
  factory PlantioIntegrado.fromSubmoduloData(Map<String, dynamic> data, String talhaoNome) {
    return PlantioIntegrado(
      id: data['id']?.toString() ?? '',
      talhaoId: data['talhao_id']?.toString() ?? '',
      talhaoNome: talhaoNome,
      culturaId: data['cultura']?.toString() ?? '',
      variedadeId: data['variedade']?.toString(),
      dataPlantio: data['data_plantio'] != null 
          ? DateTime.tryParse(data['data_plantio'].toString()) ?? DateTime.now()
          : DateTime.now(),
      populacao: ((data['populacao_por_m'] as num?)?.toDouble() ?? 0.0).toInt(),
      espacamento: (data['espacamento_cm'] as num?)?.toDouble() ?? 0.0,
      profundidade: 3.0, // Valor padrão
      observacoes: data['observacao']?.toString(),
      fonte: 'submodulo',
    );
  }
  
  /// Cria a partir de dados extraídos do histórico
  factory PlantioIntegrado.fromHistoricoData(Map<String, dynamic> data, String talhaoNome) {
    // ✅ Buscar dados reais dos campos de historico_plantio
    final populacaoPlanejada = (data['populacao_planejada'] as num?)?.toInt() 
        ?? (data['populacao'] as num?)?.toInt() 
        ?? 0;
    
    final espacamentoLinhas = (data['espacamento_linhas'] as num?)?.toDouble() 
        ?? (data['espacamento'] as num?)?.toDouble() 
        ?? 0.0;
    
    return PlantioIntegrado(
      id: data['id']?.toString() ?? '',
      talhaoId: data['talhao_id']?.toString() ?? '',
      talhaoNome: talhaoNome,
      culturaId: data['cultura_id']?.toString() ?? '',
      variedadeId: data['variedade']?.toString(),
      dataPlantio: data['data_plantio'] != null 
          ? DateTime.tryParse(data['data_plantio'].toString()) ?? DateTime.now()
          : DateTime.now(),
      populacao: populacaoPlanejada,
      espacamento: espacamentoLinhas,
      profundidade: (data['profundidade'] as num?)?.toDouble() ?? 0.0,
      observacoes: data['observacoes']?.toString(),
      fonte: 'historico',
    );
  }
  
  /// Converte para PlantioModel para compatibilidade
  PlantioModel toPlantioModel() {
    return PlantioModel(
      id: id,
      talhaoId: talhaoId,
      culturaId: culturaId,
      variedadeId: variedadeId,
      dataPlantio: dataPlantio,
      populacao: populacao,
      espacamento: espacamento,
      profundidade: profundidade,
      maquinasIds: [],
      observacoes: observacoes,
    );
  }
}

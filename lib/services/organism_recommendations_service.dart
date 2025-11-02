import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import 'organism_v3_integration_service.dart';

/// Serviço para gerar recomendações de aplicação baseadas nos JSONs de organismos (v3.0)
/// ✅ PRIORIZA arquivo customizado da fazenda
class OrganismRecommendationsService {
  final OrganismV3IntegrationService _v3Service = OrganismV3IntegrationService();
  
  /// Carrega dados de controle de um organismo específico do JSON (v3.0)
  /// ✅ PRIORIDADE: organism_catalog_custom.json → organismos_*.json → dados v3.0
  Future<Map<String, dynamic>?> carregarDadosControle(
    String culturaNome,
    String organismoNome,
  ) async {
    try {
      // ✅ MAPEAMENTO DE NOMES: Corrigir nomes que diferem entre JSONs e banco
      final nomeMapeado = _mapearNomeOrganismo(organismoNome, culturaNome);
      if (nomeMapeado != organismoNome) {
        Logger.info('🔄 Nome mapeado: "$organismoNome" → "$nomeMapeado" (cultura: $culturaNome)');
      }
      
      // 1️⃣ PRIMEIRA PRIORIDADE: Arquivo customizado da fazenda
      final customData = await _carregarDadosCustomizados(culturaNome, nomeMapeado);
      if (customData != null) {
        Logger.info('✅ Usando dados CUSTOMIZADOS da fazenda para: $nomeMapeado');
        return customData;
      }
      
      // 2️⃣ SEGUNDA PRIORIDADE: Dados v3.0
      final dadosV3 = await _v3Service.getOrganismDataForReport(
        organismoNome: nomeMapeado,
        cultura: culturaNome,
      );
      
      if (dadosV3['versao'] == '3.0') {
        Logger.info('✅ Dados v3.0 carregados para: ${dadosV3['nome']}');
        return dadosV3;
      }
      
      // 3️⃣ FALLBACK: JSONs padrão do projeto
      Logger.info('📄 Carregando dados padrão do projeto');
      final culturaMap = {
        'soja': 'soja',
        'milho': 'milho',
        'algodao': 'algodao',
        'feijao': 'feijao',
        'trigo': 'trigo',
        'arroz': 'arroz',
        'aveia': 'aveia',
        'girassol': 'girassol',
        'sorgo': 'sorgo',
        'cana_acucar': 'cana_acucar',
        'gergelim': 'gergelim',
        'tomate': 'tomate',
        'batata': 'batata',
      };
      
      final culturaNormalizada = culturaMap[culturaNome.toLowerCase()] ?? culturaNome.toLowerCase();
      final filePath = 'assets/data/organismos_$culturaNormalizada.json';
      
      Logger.info('📂 Carregando dados v2.0: $filePath para $organismoNome');
      
      final jsonString = await rootBundle.loadString(filePath);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final organismos = data['organismos'] as List<dynamic>? ?? [];
      
      // Buscar organismo por nome (case insensitive)
      final organismoEncontrado = organismos.firstWhere(
        (org) {
          final nome = (org['nome'] as String? ?? '').toLowerCase();
          final nomeCientifico = (org['nome_cientifico'] as String? ?? '').toLowerCase();
          final nomeBusca = nomeMapeado.toLowerCase(); // ✅ USAR NOME MAPEADO
          
          return nome.contains(nomeBusca) || 
                 nomeBusca.contains(nome) ||
                 nomeCientifico.contains(nomeBusca) ||
                 nomeBusca.contains(nomeCientifico);
        },
        orElse: () => null,
      );
      
      if (organismoEncontrado == null) {
        Logger.warning('⚠️ Organismo não encontrado: $nomeMapeado (original: $organismoNome) em $culturaNome');
        return null;
      }
      
      Logger.info('✅ Dados de controle carregados para: ${organismoEncontrado['nome']}');
      return organismoEncontrado as Map<String, dynamic>;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de controle: $e');
      return null;
    }
  }
  
  /// 🔄 MAPEAR NOMES DE ORGANISMOS ENTRE BANCO E JSONs
  String _mapearNomeOrganismo(String nomeOriginal, String cultura) {
    // Mapeamento de nomes conhecidos que diferem
    final mapeamentos = <String, Map<String, String>>{
      'soja': {
        'Lagarta-do-cartucho': 'Lagarta Spodoptera',
        'Lagarta do cartucho': 'Lagarta Spodoptera',
        'Spodoptera': 'Lagarta Spodoptera',
        // Percevejos
        'Percevejo-barriga-verde': 'Percevejo-marrom', // Fallback para percevejo genérico
        'Percevejo barriga verde': 'Percevejo-marrom',
        // Mancha-de-cercospora não existe em soja, retornar nome original
      },
      'milho': {
        'Lagarta-da-soja': 'Lagarta-do-cartucho', // Inverso para milho
        'Lagarta da soja': 'Lagarta-do-cartucho',
      },
    };
    
    final mapeamentoCultura = mapeamentos[cultura.toLowerCase()];
    if (mapeamentoCultura != null) {
      final nomeMapeado = mapeamentoCultura[nomeOriginal];
      if (nomeMapeado != null) {
        return nomeMapeado;
      }
    }
    
    // Retornar nome original se não encontrar mapeamento
    return nomeOriginal;
  }
  
  /// Gera recomendações de produtos baseadas nos JSONs
  List<String> gerarProdutosRecomendados(
    Map<String, dynamic> dadosControle,
    String nivelRisco,
  ) {
    final recomendacoes = <String>[];
    
    // ✅ BUSCAR MANEJO DO CAMINHO CORRETO (manejo.quimico ao invés de manejo_quimico)
    final manejo = dadosControle['manejo'] as Map<String, dynamic>?;
    
    // 1. MANEJO QUÍMICO
    final manejoQuimico = manejo?['quimico'] as List<dynamic>? ?? 
                         dadosControle['manejo_quimico'] as List<dynamic>? ?? [];
    if (manejoQuimico.isNotEmpty) {
      recomendacoes.add('💊 PRODUTOS QUÍMICOS RECOMENDADOS:');
      for (var i = 0; i < manejoQuimico.length; i++) {
        final produto = manejoQuimico[i].toString();
        recomendacoes.add('   ${i + 1}. $produto');
      }
      recomendacoes.add('');
    }
    
    // 2. DOSES DETALHADAS
    final dosesDefensivos = dadosControle['doses_defensivos'] as Map<String, dynamic>?;
    if (dosesDefensivos != null && dosesDefensivos.isNotEmpty) {
      recomendacoes.add('📋 DOSAGENS ESPECÍFICAS:');
      
      dosesDefensivos.forEach((produto, detalhes) {
        final det = detalhes as Map<String, dynamic>;
        final nomeProduto = produto.replaceAll('_', ' ').toUpperCase();
        recomendacoes.add('   • $nomeProduto:');
        if (det['dose'] != null) recomendacoes.add('     - Dose: ${det['dose']}');
        if (det['volume_calda'] != null) recomendacoes.add('     - Volume de calda: ${det['volume_calda']}');
        if (det['intervalo_seguranca'] != null) recomendacoes.add('     - Carência: ${det['intervalo_seguranca']} dias');
        
        // Ajustar dose conforme nível de risco
        if (nivelRisco.toLowerCase() == 'crítico' || nivelRisco.toLowerCase() == 'critico') {
          recomendacoes.add('     - ⚠️ Usar DOSE MÁXIMA (nível crítico)');
        } else if (nivelRisco.toLowerCase() == 'alto') {
          recomendacoes.add('     - Usar dose média-alta');
        }
        
        if (det['adjuvante'] != null) recomendacoes.add('     - Adjuvante: ${det['adjuvante']}');
      });
      recomendacoes.add('');
    }
    
    // 3. MANEJO BIOLÓGICO
    final manejoBiologico = manejo?['biologico'] as List<dynamic>? ?? 
                           dadosControle['manejo_biologico'] as List<dynamic>? ?? [];
    if (manejoBiologico.isNotEmpty) {
      recomendacoes.add('🦋 CONTROLE BIOLÓGICO (Complementar):');
      for (var i = 0; i < manejoBiologico.length; i++) {
        final bio = manejoBiologico[i].toString();
        recomendacoes.add('   ${i + 1}. $bio');
      }
      recomendacoes.add('');
    }
    
    // 4. MANEJO CULTURAL
    final manejoCultural = manejo?['cultural'] as List<dynamic>? ?? 
                          dadosControle['manejo_cultural'] as List<dynamic>? ?? [];
    if (manejoCultural.isNotEmpty) {
      recomendacoes.add('🌾 PRÁTICAS CULTURAIS:');
      for (var i = 0; i < manejoCultural.length; i++) {
        final cultural = manejoCultural[i].toString();
        recomendacoes.add('   ${i + 1}. $cultural');
      }
      recomendacoes.add('');
    }
    
    // 5. NÍVEL DE AÇÃO
    final nivelAcao = dadosControle['nivel_acao'] as String?;
    if (nivelAcao != null && nivelAcao.isNotEmpty) {
      recomendacoes.add('⚠️ Nível de Ação: $nivelAcao');
    }
    
    // 6. NÍVEIS DE INFESTAÇÃO
    final niveisInfestacao = dadosControle['niveis_infestacao'] as Map<String, dynamic>?;
    if (niveisInfestacao != null && niveisInfestacao.isNotEmpty) {
      recomendacoes.add('');
      recomendacoes.add('📊 Classificação de Infestação:');
      niveisInfestacao.forEach((nivel, descricao) {
        recomendacoes.add('   • ${nivel.toUpperCase()}: $descricao');
      });
    }
    
    if (recomendacoes.isEmpty) {
      recomendacoes.add('⚠️ Dados de controle não disponíveis para este organismo');
      recomendacoes.add('Consultar agrônomo para recomendação específica');
    }
    
    return recomendacoes;
  }
  
  /// Gera recomendações de dosagem e aplicação
  List<String> gerarDosagemAplicacao(
    Map<String, dynamic>? dadosControle,
    String nivelRisco,
  ) {
    final dosagens = <String>[];
    
    // Se temos dados do JSON, usar informações específicas
    if (dadosControle != null) {
      final dosesDefensivos = dadosControle['doses_defensivos'] as Map<String, dynamic>?;
      if (dosesDefensivos != null && dosesDefensivos.isNotEmpty) {
        final primeiraDose = dosesDefensivos.values.first as Map<String, dynamic>?;
        if (primeiraDose != null) {
          dosagens.add('💧 Volume de calda: ${primeiraDose['volume_calda'] ?? '150-200 L/ha (terrestre) / 10-15 L/ha (aérea)'}');
          dosagens.add('🔬 pH da calda: 5,5-6,5 para melhor eficácia');
          dosagens.add('⏱️ Intervalo de segurança: ${primeiraDose['intervalo_seguranca'] ?? 'Consultar bula'}');
          
          if (primeiraDose['condicoes_climaticas'] != null) {
            dosagens.add('🌤️ Condições climáticas: ${primeiraDose['condicoes_climaticas']}');
          }
          
          if (primeiraDose['equipamento'] != null) {
            dosagens.add('🚜 Equipamento: ${primeiraDose['equipamento']}');
          }
        }
      }
    }
    
    // Recomendações gerais se não houver dados específicos
    if (dosagens.isEmpty) {
      dosagens.add('💧 Volume de calda: 150-200 L/ha para aplicação terrestre');
      dosagens.add('💧 Volume de calda: 10-15 L/ha para aplicação aérea');
      dosagens.add('🔬 pH da calda: 5,5-6,5 para melhor eficácia');
    }
    
    // Ajustes conforme nível de risco
    if (nivelRisco.toLowerCase() == 'crítico' || nivelRisco.toLowerCase() == 'critico') {
      dosagens.add('');
      dosagens.add('⚠️ NÍVEL CRÍTICO DETECTADO:');
      dosagens.add('   • Utilizar dose máxima recomendada');
      dosagens.add('   • Adicionar adjuvante: Óleo mineral 0,5% ou espalhante adesivo');
      dosagens.add('   • Considerar mistura de produtos (consultar compatibilidade)');
    } else if (nivelRisco.toLowerCase() == 'alto') {
      dosagens.add('');
      dosagens.add('📈 Nível Alto:');
      dosagens.add('   • Utilizar dose média-alta da recomendação');
      dosagens.add('   • Considerar adjuvante para melhor eficácia');
    } else {
      dosagens.add('');
      dosagens.add('✅ Utilizar dose padrão recomendada');
    }
    
    dosagens.add('');
    dosagens.add('⚠️ Importante: Respeitar período de carência e intervalo de segurança');
    
    return dosagens;
  }
  
  /// Gera recomendações de momento de aplicação baseadas nos JSONs
  List<String> gerarMomentoAplicacao(
    Map<String, dynamic>? dadosControle,
    Map<String, dynamic>? condicoes,
    Map<String, dynamic>? dadosCompletos,
  ) {
    final momentos = <String>[];
    
    // 1. ÉPOCA DE APLICAÇÃO DO JSON
    if (dadosControle != null) {
      final dosesDefensivos = dadosControle['doses_defensivos'] as Map<String, dynamic>?;
      if (dosesDefensivos != null && dosesDefensivos.isNotEmpty) {
        final primeiraDose = dosesDefensivos.values.first as Map<String, dynamic>?;
        if (primeiraDose != null && primeiraDose['epoca_aplicacao'] != null) {
          momentos.add('📅 Época de Aplicação Recomendada:');
          momentos.add('   ${primeiraDose['epoca_aplicacao']}');
          momentos.add('');
        }
      }
      
      // FASES FENOLÓGICAS DETALHADAS
      final fasesFenologicas = dadosControle['fases_fenologicas_detalhadas'] as Map<String, dynamic>?;
      if (fasesFenologicas != null && fasesFenologicas.isNotEmpty) {
        final fenologia = dadosCompletos?['fenologia'] as Map<String, dynamic>?;
        final estagioAtual = fenologia?['estagio'] as String?;
        
        if (estagioAtual != null && fasesFenologicas.containsKey(estagioAtual)) {
          momentos.add('🌱 Estágio Fenológico Atual: $estagioAtual');
          momentos.add('   ${fasesFenologicas[estagioAtual]}');
          momentos.add('');
        }
      }
    }
    
    // 2. CONDIÇÕES CLIMÁTICAS ATUAIS
    final temp = condicoes?['temperatura'] ?? 25.0;
    final umidade = condicoes?['umidade'] ?? 60.0;
    
    momentos.add('🌡️ Condições Atuais:');
    momentos.add('   • Temperatura: ${temp}°C ${temp > 25 && temp <= 30 ? '(adequada)' : temp > 30 ? '(⚠️ alta - evitar horários quentes)' : '(boa)'}');
    momentos.add('   • Umidade relativa: ${umidade}% ${umidade >= 60 ? '(adequada)' : '(⚠️ baixa)'}');
    momentos.add('');
    
    // 3. HORÁRIO IDEAL
    if (temp > 30) {
      momentos.add('⏰ Horário Recomendado:');
      momentos.add('   • Aplicar no início da manhã (6h-9h) ou final da tarde (após 17h)');
      momentos.add('   • ⚠️ Evitar período de 10h às 16h (temperatura elevada)');
    } else {
      momentos.add('⏰ Horário Recomendado:');
      momentos.add('   • Aplicar preferencialmente pela manhã (6h-10h)');
    }
    
    momentos.add('');
    momentos.add('🌬️ Outras Condições:');
    momentos.add('   • Vento: < 10 km/h para evitar deriva');
    momentos.add('   • Não aplicar com previsão de chuva nas próximas 4-6 horas');
    momentos.add('   • Evitar orvalho excessivo nas folhas');
    
    return momentos;
  }
  
  /// Gera recomendações para múltiplos organismos
  Future<Map<String, List<String>>> gerarRecomendacoesMultiplas(
    String culturaNome,
    List<String> organismos,
    String nivelRisco,
  ) async {
    final recomendacoesPorOrganismo = <String, List<String>>{};
    
    for (final organismo in organismos.toSet()) {
      final dadosControle = await carregarDadosControle(culturaNome, organismo);
      if (dadosControle != null) {
        recomendacoesPorOrganismo[organismo] = gerarProdutosRecomendados(
          dadosControle,
          nivelRisco,
        );
      }
    }
    
      return recomendacoesPorOrganismo;
  }
  
  /// 🔧 CARREGA DADOS DO ARQUIVO CUSTOMIZADO (PRIORIDADE)
  Future<Map<String, dynamic>?> _carregarDadosCustomizados(
    String culturaNome,
    String organismoNome,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final customFile = File('${directory.path}/organism_catalog_custom.json');
      
      if (!await customFile.exists()) {
        return null;
      }
      
      final jsonString = await customFile.readAsString();
      final catalogData = json.decode(jsonString) as Map<String, dynamic>;
      
      final cultures = catalogData['cultures'] as Map<String, dynamic>?;
      if (cultures == null) return null;
      
      final cultureKey = culturaNome.toLowerCase();
      final cultureData = cultures[cultureKey] as Map<String, dynamic>?;
      if (cultureData == null) return null;
      
      final organisms = cultureData['organisms'] as Map<String, dynamic>?;
      if (organisms == null) return null;
      
      // Buscar em pragas, doenças e daninhas
      final allOrganisms = [
        ...(organisms['pests'] as List<dynamic>? ?? []),
        ...(organisms['diseases'] as List<dynamic>? ?? []),
        ...(organisms['weeds'] as List<dynamic>? ?? []),
      ];
      
      for (final org in allOrganisms) {
        final orgMap = org as Map<String, dynamic>;
        final nome = (orgMap['nome'] ?? orgMap['name'] ?? '').toString().toLowerCase();
        final nomeBusca = organismoNome.toLowerCase();
        
        if (nome.contains(nomeBusca) || nomeBusca.contains(nome)) {
          Logger.info('✅ Organismo customizado encontrado: ${orgMap['nome'] ?? orgMap['name']}');
          return orgMap;
        }
      }
      
      return null;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados customizados: $e');
      return null;
    }
  }
}


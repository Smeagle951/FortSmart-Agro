import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/enhanced_ai_organism_data.dart';
import '../../../services/organism_catalog_loader_service.dart';
import '../../../models/organism_catalog.dart';
import '../../../utils/logger.dart';

/// Serviço para migrar dados do catálogo de organismos para o módulo de IA
class AICatalogMigrationService {
  final OrganismCatalogLoaderService _catalogLoader = OrganismCatalogLoaderService();
  
  /// Migra todos os organismos do catálogo para o formato expandido da IA
  Future<List<EnhancedAIOrganismData>> migrateAllOrganisms() async {
    try {
      Logger.info('🔄 Iniciando migração de dados do catálogo para IA...');
      
      final catalogOrganisms = await _catalogLoader.loadAllOrganisms();
      final List<EnhancedAIOrganismData> enhancedOrganisms = [];
      
      for (final catalogOrganism in catalogOrganisms) {
        try {
          final enhanced = await _convertCatalogToEnhancedAI(catalogOrganism);
          enhancedOrganisms.add(enhanced);
        } catch (e) {
          Logger.warning('⚠️ Erro ao converter organismo ${catalogOrganism.name}: $e');
        }
      }
      
      Logger.info('✅ Migração concluída: ${enhancedOrganisms.length} organismos migrados');
      return enhancedOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro na migração: $e');
      return [];
    }
  }
  
  /// Migra organismos de uma cultura específica
  Future<List<EnhancedAIOrganismData>> migrateCultureOrganisms(String cultureName) async {
    try {
      Logger.info('🔄 Migrando organismos da cultura: $cultureName');
      
      final catalogOrganisms = await _catalogLoader.loadCultureOrganisms(cultureName);
      final List<EnhancedAIOrganismData> enhancedOrganisms = [];
      
      for (final catalogOrganism in catalogOrganisms) {
        try {
          final enhanced = await _convertCatalogToEnhancedAI(catalogOrganism);
          enhancedOrganisms.add(enhanced);
        } catch (e) {
          Logger.warning('⚠️ Erro ao converter organismo ${catalogOrganism.name}: $e');
        }
      }
      
      Logger.info('✅ Migração da cultura $cultureName: ${enhancedOrganisms.length} organismos');
      return enhancedOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro na migração da cultura $cultureName: $e');
      return [];
    }
  }
  
  /// Converte um organismo do catálogo para formato expandido da IA
  Future<EnhancedAIOrganismData> _convertCatalogToEnhancedAI(OrganismCatalog catalog) async {
    try {
      // Carrega dados detalhados do arquivo JSON da cultura
      final detailedData = await _loadDetailedOrganismData(catalog);
      
      return EnhancedAIOrganismData(
        id: catalog.id.hashCode,
        name: catalog.name,
        scientificName: catalog.scientificName,
        type: _convertOccurrenceType(catalog.type),
        crops: [catalog.cropName],
        symptoms: detailedData['sintomas'] ?? [],
        managementStrategies: _combineManagementStrategies(detailedData),
        description: _buildDescription(catalog, detailedData),
        imageUrl: catalog.imageUrl ?? '',
        characteristics: _buildCharacteristics(catalog, detailedData),
        severity: _calculateSeverity(catalog),
        keywords: _extractKeywords(catalog, detailedData),
        createdAt: catalog.createdAt,
        updatedAt: catalog.updatedAt ?? catalog.createdAt,
        fases: _parseFases(detailedData['fases'] ?? []),
        severidadeDetalhada: _parseSeveridadeDetalhada(detailedData['severidade'] ?? {}),
        condicoesFavoraveis: _parseCondicoesFavoraveis(detailedData['condicoes_favoraveis'] ?? {}),
        limiaresAcao: LimiaresAcao(
          baixo: catalog.lowLimit,
          medio: catalog.mediumLimit,
          alto: catalog.highLimit,
          unidade: catalog.unit,
        ),
        danoEconomico: DanoEconomico(
          descricao: detailedData['dano_economico'] ?? '',
          perdaMaxima: _extractMaxLoss(detailedData['dano_economico'] ?? ''),
        ),
        fenologia: List<String>.from(detailedData['fenologia'] ?? []),
        partesAfetadas: List<String>.from(detailedData['partes_afetadas'] ?? []),
        manejoIntegrado: _parseManejoIntegrado(detailedData),
        observacoes: [detailedData['observacoes'] ?? ''].where((o) => o.toString().isNotEmpty).map((o) => o.toString()).toList(),
        icone: detailedData['icone'] ?? '🐛',
        ativo: catalog.isActive,
        categoria: _convertOccurrenceTypeToCategory(catalog.type),
        culturaId: catalog.cropId,
        nivelAcao: detailedData['nivel_acao'] ?? '',
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao converter organismo ${catalog.name}: $e');
      rethrow;
    }
  }
  
  /// Carrega dados detalhados do arquivo JSON
  Future<Map<String, dynamic>> _loadDetailedOrganismData(OrganismCatalog catalog) async {
    try {
      final cultureName = catalog.cropId.toLowerCase();
      final jsonString = await rootBundle.loadString('lib/data/organismos_$cultureName.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Busca o organismo específico nos dados
      final organisms = jsonData['organismos'] as List<dynamic>? ?? [];
      for (final organism in organisms) {
        if (organism['nome'] == catalog.name || organism['id'] == catalog.id) {
          return organism as Map<String, dynamic>;
        }
      }
      
      return {};
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar dados detalhados para ${catalog.name}: $e');
      return {};
    }
  }
  
  /// Converte OccurrenceType para string
  String _convertOccurrenceType(dynamic type) {
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('disease')) return 'disease';
    if (typeString.contains('weed')) return 'weed';
    return 'pest';
  }
  
  /// Converte OccurrenceType para categoria
  String _convertOccurrenceTypeToCategory(dynamic type) {
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('disease')) return 'Doença';
    if (typeString.contains('weed')) return 'Planta Daninha';
    return 'Praga';
  }
  
  /// Combina estratégias de manejo
  List<String> _combineManagementStrategies(Map<String, dynamic> data) {
    final strategies = <String>[];
    
    if (data['manejo_quimico'] != null) {
      strategies.addAll(List<String>.from(data['manejo_quimico']));
    }
    if (data['manejo_biologico'] != null) {
      strategies.addAll(List<String>.from(data['manejo_biologico']));
    }
    if (data['manejo_cultural'] != null) {
      strategies.addAll(List<String>.from(data['manejo_cultural']));
    }
    
    return strategies;
  }
  
  /// Constrói descrição combinada
  String _buildDescription(OrganismCatalog catalog, Map<String, dynamic> data) {
    final parts = <String>[];
    
    if (catalog.description?.isNotEmpty == true) {
      parts.add(catalog.description!);
    }
    
    if (data['dano_economico']?.isNotEmpty == true) {
      parts.add('Danos Econômicos: ${data['dano_economico']}');
    }
    
    if (data['observacoes']?.isNotEmpty == true) {
      parts.add('Observações: ${data['observacoes']}');
    }
    
    return parts.join('\n\n');
  }
  
  /// Constrói características
  Map<String, dynamic> _buildCharacteristics(OrganismCatalog catalog, Map<String, dynamic> data) {
    return {
      'unit': catalog.unit,
      'lowLimit': catalog.lowLimit,
      'mediumLimit': catalog.mediumLimit,
      'highLimit': catalog.highLimit,
      'categoria': _convertOccurrenceTypeToCategory(catalog.type),
      'cultura': catalog.cropName,
      'nivelAcao': data['nivel_acao'] ?? '',
      'icone': data['icone'] ?? '🐛',
    };
  }
  
  /// Calcula severidade baseada nos limiares
  double _calculateSeverity(OrganismCatalog catalog) {
    if (catalog.highLimit <= 0) return 0.5;
    return (catalog.mediumLimit / catalog.highLimit).clamp(0.0, 1.0);
  }
  
  /// Extrai palavras-chave
  List<String> _extractKeywords(OrganismCatalog catalog, Map<String, dynamic> data) {
    final keywords = <String>[];
    
    keywords.addAll(catalog.name.split(' '));
    keywords.addAll(catalog.scientificName.split(' '));
    keywords.add(catalog.cropName);
    keywords.add(_convertOccurrenceTypeToCategory(catalog.type));
    
    if (data['sintomas'] != null) {
      for (final sintoma in data['sintomas']) {
        keywords.addAll(sintoma.toString().split(' '));
      }
    }
    
    return keywords.where((k) => k.length > 2).toSet().toList();
  }
  
  /// Extrai perda máxima de produtividade
  String _extractMaxLoss(String danoEconomico) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)%');
    final match = regex.firstMatch(danoEconomico);
    return match?.group(1) ?? '40';
  }
  
  /// Converte fases de desenvolvimento
  List<FaseDesenvolvimento> _parseFases(List<dynamic> fasesData) {
    return fasesData.map((fase) => FaseDesenvolvimento.fromMap(fase)).toList();
  }
  
  /// Converte severidade detalhada
  Map<String, SeveridadeDetalhada> _parseSeveridadeDetalhada(Map<String, dynamic> severidadeData) {
    final result = <String, SeveridadeDetalhada>{};
    
    for (final entry in severidadeData.entries) {
      result[entry.key] = SeveridadeDetalhada.fromMap(entry.value);
    }
    
    return result;
  }
  
  /// Converte condições favoráveis
  CondicoesFavoraveis _parseCondicoesFavoraveis(Map<String, dynamic> condicoesData) {
    return CondicoesFavoraveis.fromMap(condicoesData);
  }
  
  /// Converte manejo integrado
  ManejoIntegrado _parseManejoIntegrado(Map<String, dynamic> data) {
    return ManejoIntegrado(
      quimico: List<String>.from(data['manejo_quimico'] ?? []),
      biologico: List<String>.from(data['manejo_biologico'] ?? []),
      cultural: List<String>.from(data['manejo_cultural'] ?? []),
    );
  }
  
  /// Cria dados melhorados para culturas específicas
  Future<List<EnhancedAIOrganismData>> createEnhancedCropData(String cropName) async {
    try {
      Logger.info('🌱 Criando dados melhorados para: $cropName');
      
      final baseOrganisms = await migrateCultureOrganisms(cropName);
      final enhancedOrganisms = <EnhancedAIOrganismData>[];
      
      for (final organism in baseOrganisms) {
        final enhanced = _enhanceOrganismForCrop(organism, cropName);
        enhancedOrganisms.add(enhanced);
      }
      
      // Adiciona organismos específicos para culturas importantes
      if (cropName.toLowerCase() == 'soja') {
        enhancedOrganisms.addAll(_createEnhancedSojaOrganisms());
      } else if (cropName.toLowerCase() == 'milho') {
        enhancedOrganisms.addAll(_createEnhancedMilhoOrganisms());
      } else if (cropName.toLowerCase() == 'algodao') {
        enhancedOrganisms.addAll(_createEnhancedAlgodaoOrganisms());
      } else if (cropName.toLowerCase() == 'sorgo') {
        enhancedOrganisms.addAll(_createEnhancedSorgoOrganisms());
      } else if (cropName.toLowerCase() == 'cana') {
        enhancedOrganisms.addAll(_createEnhancedCanaOrganisms());
      }
      
      Logger.info('✅ Dados melhorados criados para $cropName: ${enhancedOrganisms.length} organismos');
      return enhancedOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao criar dados melhorados para $cropName: $e');
      return [];
    }
  }
  
  /// Melhora organismo específico para cultura
  EnhancedAIOrganismData _enhanceOrganismForCrop(EnhancedAIOrganismData organism, String cropName) {
    // Adiciona dados específicos baseados na cultura
    final cropSpecificData = _getCropSpecificEnhancements(cropName, organism.name);
    
    return organism.copyWith(
      condicoesFavoraveis: cropSpecificData['condicoesFavoraveis'] ?? organism.condicoesFavoraveis,
      limiaresAcao: cropSpecificData['limiaresAcao'] ?? organism.limiaresAcao,
      danoEconomico: cropSpecificData['danoEconomico'] ?? organism.danoEconomico,
      observacoes: [...organism.observacoes, ...(cropSpecificData['observacoes'] ?? [])],
    );
  }
  
  /// Obtém melhorias específicas por cultura
  Map<String, dynamic> _getCropSpecificEnhancements(String cropName, String organismName) {
    final enhancements = <String, dynamic>{};
    
    switch (cropName.toLowerCase()) {
      case 'soja':
        enhancements['observacoes'] = [
          'Monitoramento semanal durante período crítico',
          'Aplicação preventiva em condições favoráveis',
          'Rotação com milho para quebrar ciclo'
        ];
        break;
      case 'milho':
        enhancements['observacoes'] = [
          'Controle no estágio V6-V8 é crítico',
          'Aplicação noturna para melhor eficácia',
          'Considerar resistência a herbicidas'
        ];
        break;
      case 'algodao':
        enhancements['observacoes'] = [
          'Monitoramento intensivo na floração',
          'Cuidado com resíduos em fibras',
          'Aplicação em horários específicos'
        ];
        break;
      case 'sorgo':
        enhancements['observacoes'] = [
          'Controle precoce é fundamental',
          'Aplicação em condições de baixa umidade',
          'Considerar variedades resistentes'
        ];
        break;
      case 'cana':
        enhancements['observacoes'] = [
          'Controle em cana-planta é prioritário',
          'Aplicação em condições secas',
          'Considerar queima controlada'
        ];
        break;
    }
    
    return enhancements;
  }
  
  /// Cria organismos melhorados para soja
  List<EnhancedAIOrganismData> _createEnhancedSojaOrganisms() {
    return [
      _createEnhancedOrganism(
        name: 'Lagarta-da-soja (Anticarsia gemmatalis)',
        scientificName: 'Anticarsia gemmatalis',
        type: 'pest',
        crops: ['Soja'],
        symptoms: ['Desfolha intensa', 'Folhas com bordas irregulares'],
        managementStrategies: ['Clorantraniliprole', 'Spinosad', 'Bacillus thuringiensis'],
        description: 'Principal praga da soja, causa desfolha severa',
        fases: [
          FaseDesenvolvimento(
            fase: 'Ovo',
            tamanhoMM: '0.5',
            danos: 'Início da infestação',
            duracaoDias: '3-5',
            caracteristicas: 'Postura em folhas, cor esbranquiçada'
          ),
          FaseDesenvolvimento(
            fase: 'Neonata',
            tamanhoMM: '1-2',
            danos: 'Raspagens leves',
            duracaoDias: '2-3',
            caracteristicas: 'Lagartas pequenas, cor verde clara'
          ),
          FaseDesenvolvimento(
            fase: 'Média',
            tamanhoMM: '10-25',
            danos: 'Desfolha significativa',
            duracaoDias: '8-12',
            caracteristicas: 'Lagartas verdes com listras'
          ),
          FaseDesenvolvimento(
            fase: 'Adulta',
            tamanhoMM: '30-35',
            danos: 'Desfolha severa',
            duracaoDias: '5-8',
            caracteristicas: 'Lagartas grandes, alta voracidade'
          ),
        ],
        severidadeDetalhada: {
          'baixo': SeveridadeDetalhada(
            descricao: 'Até 5 lagartas por pano',
            perdaProdutividade: '0-5%',
            corAlerta: '#4CAF50',
            acao: 'Monitoramento intensificado'
          ),
          'medio': SeveridadeDetalhada(
            descricao: '6-15 lagartas por pano',
            perdaProdutividade: '6-20%',
            corAlerta: '#FF9800',
            acao: 'Aplicação de inseticida'
          ),
          'alto': SeveridadeDetalhada(
            descricao: 'Acima de 15 lagartas',
            perdaProdutividade: '21-40%',
            corAlerta: '#F44336',
            acao: 'Aplicação imediata'
          ),
        },
        condicoesFavoraveis: CondicoesFavoraveis(
          temperatura: '20-30°C',
          umidade: 'Alta umidade relativa (>70%)',
        ),
        limiaresAcao: LimiaresAcao(baixo: 5, medio: 15, alto: 25, unidade: 'lagartas/pano'),
        danoEconomico: DanoEconomico(
          descricao: 'Pode causar perdas de até 40% na produtividade',
          perdaMaxima: '40%',
        ),
        fenologia: ['Vegetativo', 'Floração'],
        partesAfetadas: ['Folhas'],
        manejoIntegrado: ManejoIntegrado(
          quimico: ['Clorantraniliprole (IRAC 28)', 'Spinosad (IRAC 5)'],
          biologico: ['Trichogramma pretiosum', 'Bacillus thuringiensis'],
          cultural: ['Rotação de culturas', 'Plantio na época recomendada'],
        ),
        observacoes: [
          'Monitoramento semanal durante período crítico',
          'Aplicação preventiva em condições favoráveis',
          'Rotação com milho para quebrar ciclo'
        ],
        icone: '🐛',
        categoria: 'Praga',
        culturaId: 'soja',
        nivelAcao: 'Desfolha ≥ 30% no estágio vegetativo',
      ),
    ];
  }
  
  /// Cria organismos melhorados para milho
  List<EnhancedAIOrganismData> _createEnhancedMilhoOrganisms() {
    return [
      _createEnhancedOrganism(
        name: 'Lagarta-do-cartucho (Spodoptera frugiperda)',
        scientificName: 'Spodoptera frugiperda',
        type: 'pest',
        crops: ['Milho'],
        symptoms: ['Danos no cartucho', 'Perfuração de folhas'],
        managementStrategies: ['Bacillus thuringiensis', 'Clorantraniliprole'],
        description: 'Principal praga do milho, ataca cartucho e folhas',
        fases: [
          FaseDesenvolvimento(
            fase: 'Ovo',
            tamanhoMM: '0.4',
            danos: 'Início da infestação',
            duracaoDias: '2-4',
            caracteristicas: 'Postura em massas, cor branca'
          ),
          FaseDesenvolvimento(
            fase: 'Neonata',
            tamanhoMM: '1-3',
            danos: 'Raspagens superficiais',
            duracaoDias: '2-3',
            caracteristicas: 'Lagartas pequenas, cor escura'
          ),
          FaseDesenvolvimento(
            fase: 'Média',
            tamanhoMM: '8-20',
            danos: 'Danos no cartucho',
            duracaoDias: '6-10',
            caracteristicas: 'Lagartas com listras longitudinais'
          ),
          FaseDesenvolvimento(
            fase: 'Adulta',
            tamanhoMM: '25-40',
            danos: 'Destruição do cartucho',
            duracaoDias: '4-6',
            caracteristicas: 'Lagartas grandes, alta voracidade'
          ),
        ],
        severidadeDetalhada: {
          'baixo': SeveridadeDetalhada(
            descricao: 'Até 3 lagartas por planta',
            perdaProdutividade: '0-5%',
            corAlerta: '#4CAF50',
            acao: 'Monitoramento intensificado'
          ),
          'medio': SeveridadeDetalhada(
            descricao: '4-8 lagartas por planta',
            perdaProdutividade: '6-15%',
            corAlerta: '#FF9800',
            acao: 'Aplicação de inseticida'
          ),
          'alto': SeveridadeDetalhada(
            descricao: 'Acima de 8 lagartas',
            perdaProdutividade: '16-35%',
            corAlerta: '#F44336',
            acao: 'Aplicação imediata'
          ),
        },
        condicoesFavoraveis: CondicoesFavoraveis(
          temperatura: '22-32°C',
          umidade: 'Umidade relativa moderada (50-70%)',
        ),
        limiaresAcao: LimiaresAcao(baixo: 3, medio: 8, alto: 12, unidade: 'lagartas/planta'),
        danoEconomico: DanoEconomico(
          descricao: 'Pode causar perdas de até 35% na produtividade',
          perdaMaxima: '35%',
        ),
        fenologia: ['V6-V8', 'Floração'],
        partesAfetadas: ['Cartucho', 'Folhas'],
        manejoIntegrado: ManejoIntegrado(
          quimico: ['Bacillus thuringiensis', 'Clorantraniliprole'],
          biologico: ['Trichogramma pretiosum', 'Telenomus remus'],
          cultural: ['Plantio na época recomendada', 'Destruição de restos culturais'],
        ),
        observacoes: [
          'Controle no estágio V6-V8 é crítico',
          'Aplicação noturna para melhor eficácia',
          'Considerar resistência a herbicidas'
        ],
        icone: '🐛',
        categoria: 'Praga',
        culturaId: 'milho',
        nivelAcao: 'Controle quando 5% das plantas apresentam danos',
      ),
    ];
  }
  
  /// Cria organismos melhorados para algodão
  List<EnhancedAIOrganismData> _createEnhancedAlgodaoOrganisms() {
    return [
      _createEnhancedOrganism(
        name: 'Bicudo-do-algodoeiro (Anthonomus grandis)',
        scientificName: 'Anthonomus grandis',
        type: 'pest',
        crops: ['Algodão'],
        symptoms: ['Botões florais perfurados', 'Flores com orifícios'],
        managementStrategies: ['Malathion', 'Endosulfan'],
        description: 'Principal praga do algodão, ataca botões florais',
        fases: [
          FaseDesenvolvimento(
            fase: 'Ovo',
            tamanhoMM: '0.3',
            danos: 'Início da infestação',
            duracaoDias: '3-5',
            caracteristicas: 'Postura em botões florais'
          ),
          FaseDesenvolvimento(
            fase: 'Larva',
            tamanhoMM: '1-4',
            danos: 'Perfuração de botões',
            duracaoDias: '7-10',
            caracteristicas: 'Larvas brancas, sem pernas'
          ),
          FaseDesenvolvimento(
            fase: 'Pupa',
            tamanhoMM: '3-4',
            danos: 'Desenvolvimento',
            duracaoDias: '5-7',
            caracteristicas: 'Pupa dentro do botão'
          ),
          FaseDesenvolvimento(
            fase: 'Adulta',
            tamanhoMM: '4-6',
            danos: 'Perfuração de botões',
            duracaoDias: '30-60',
            caracteristicas: 'Besouro pequeno, cor escura'
          ),
        ],
        severidadeDetalhada: {
          'baixo': SeveridadeDetalhada(
            descricao: 'Até 2 bicudos por armadilha',
            perdaProdutividade: '0-5%',
            corAlerta: '#4CAF50',
            acao: 'Monitoramento intensificado'
          ),
          'medio': SeveridadeDetalhada(
            descricao: '3-5 bicudos por armadilha',
            perdaProdutividade: '6-20%',
            corAlerta: '#FF9800',
            acao: 'Aplicação de inseticida'
          ),
          'alto': SeveridadeDetalhada(
            descricao: 'Acima de 5 bicudos',
            perdaProdutividade: '21-50%',
            corAlerta: '#F44336',
            acao: 'Aplicação imediata'
          ),
        },
        condicoesFavoraveis: CondicoesFavoraveis(
          temperatura: '25-35°C',
          umidade: 'Umidade relativa alta (>80%)',
        ),
        limiaresAcao: LimiaresAcao(baixo: 2, medio: 5, alto: 8, unidade: 'bicudos/armadilha'),
        danoEconomico: DanoEconomico(
          descricao: 'Pode causar perdas de até 50% na produtividade',
          perdaMaxima: '50%',
        ),
        fenologia: ['Floração', 'Formação de capulhos'],
        partesAfetadas: ['Botões florais', 'Flores'],
        manejoIntegrado: ManejoIntegrado(
          quimico: ['Malathion', 'Endosulfan'],
          biologico: ['Controle biológico natural'],
          cultural: ['Destruição de restos culturais', 'Vazio sanitário'],
        ),
        observacoes: [
          'Monitoramento intensivo na floração',
          'Cuidado com resíduos em fibras',
          'Aplicação em horários específicos'
        ],
        icone: '🪲',
        categoria: 'Praga',
        culturaId: 'algodao',
        nivelAcao: 'Controle quando 5% dos botões apresentam danos',
      ),
    ];
  }
  
  /// Cria organismos melhorados para sorgo
  List<EnhancedAIOrganismData> _createEnhancedSorgoOrganisms() {
    return [
      _createEnhancedOrganism(
        name: 'Pulgão-do-sorgo (Melanaphis sacchari)',
        scientificName: 'Melanaphis sacchari',
        type: 'pest',
        crops: ['Sorgo'],
        symptoms: ['Enrolamento de folhas', 'Redução do crescimento'],
        managementStrategies: ['Imidacloprid', 'Tiametoxam'],
        description: 'Principal praga do sorgo, suga seiva das folhas',
        fases: [
          FaseDesenvolvimento(
            fase: 'Ninfas',
            tamanhoMM: '0.5-1.0',
            danos: 'Sugação de seiva',
            duracaoDias: '5-7',
            caracteristicas: 'Pequenos insetos, cor amarela'
          ),
          FaseDesenvolvimento(
            fase: 'Adultas',
            tamanhoMM: '1-2',
            danos: 'Sugação intensa',
            duracaoDias: '15-20',
            caracteristicas: 'Insetos alados e ápteros'
          ),
        ],
        severidadeDetalhada: {
          'baixo': SeveridadeDetalhada(
            descricao: 'Até 10 pulgões por folha',
            perdaProdutividade: '0-5%',
            corAlerta: '#4CAF50',
            acao: 'Monitoramento intensificado'
          ),
          'medio': SeveridadeDetalhada(
            descricao: '11-30 pulgões por folha',
            perdaProdutividade: '6-15%',
            corAlerta: '#FF9800',
            acao: 'Aplicação de inseticida'
          ),
          'alto': SeveridadeDetalhada(
            descricao: 'Acima de 30 pulgões',
            perdaProdutividade: '16-30%',
            corAlerta: '#F44336',
            acao: 'Aplicação imediata'
          ),
        },
        condicoesFavoraveis: CondicoesFavoraveis(
          temperatura: '20-30°C',
          umidade: 'Umidade relativa moderada (60-80%)',
        ),
        limiaresAcao: LimiaresAcao(baixo: 10, medio: 30, alto: 50, unidade: 'pulgões/folha'),
        danoEconomico: DanoEconomico(
          descricao: 'Pode causar perdas de até 30% na produtividade',
          perdaMaxima: '30%',
        ),
        fenologia: ['Vegetativo', 'Floração'],
        partesAfetadas: ['Folhas'],
        manejoIntegrado: ManejoIntegrado(
          quimico: ['Imidacloprid', 'Tiametoxam'],
          biologico: ['Controle biológico natural'],
          cultural: ['Plantio na época recomendada', 'Variedades resistentes'],
        ),
        observacoes: [
          'Controle precoce é fundamental',
          'Aplicação em condições de baixa umidade',
          'Considerar variedades resistentes'
        ],
        icone: '🦗',
        categoria: 'Praga',
        culturaId: 'sorgo',
        nivelAcao: 'Controle quando 20% das folhas apresentam pulgões',
      ),
    ];
  }
  
  /// Cria organismos melhorados para cana-de-açúcar
  List<EnhancedAIOrganismData> _createEnhancedCanaOrganisms() {
    return [
      _createEnhancedOrganism(
        name: 'Broca-da-cana (Diatraea saccharalis)',
        scientificName: 'Diatraea saccharalis',
        type: 'pest',
        crops: ['Cana-de-açúcar'],
        symptoms: ['Perfuração de colmos', 'Redução do teor de açúcar'],
        managementStrategies: ['Bacillus thuringiensis', 'Cotesia flavipes'],
        description: 'Principal praga da cana-de-açúcar, perfura colmos',
        fases: [
          FaseDesenvolvimento(
            fase: 'Ovo',
            tamanhoMM: '0.8',
            danos: 'Início da infestação',
            duracaoDias: '4-6',
            caracteristicas: 'Postura em folhas, cor branca'
          ),
          FaseDesenvolvimento(
            fase: 'Larva',
            tamanhoMM: '2-25',
            danos: 'Perfuração de colmos',
            duracaoDias: '25-30',
            caracteristicas: 'Larvas brancas com pontos escuros'
          ),
          FaseDesenvolvimento(
            fase: 'Pupa',
            tamanhoMM: '15-20',
            danos: 'Desenvolvimento',
            duracaoDias: '8-12',
            caracteristicas: 'Pupa dentro do colmo'
          ),
          FaseDesenvolvimento(
            fase: 'Adulta',
            tamanhoMM: '20-25',
            danos: 'Postura de ovos',
            duracaoDias: '5-8',
            caracteristicas: 'Mariposa pequena, cor amarela'
          ),
        ],
        severidadeDetalhada: {
          'baixo': SeveridadeDetalhada(
            descricao: 'Até 5% de colmos atacados',
            perdaProdutividade: '0-5%',
            corAlerta: '#4CAF50',
            acao: 'Monitoramento intensificado'
          ),
          'medio': SeveridadeDetalhada(
            descricao: '6-15% de colmos atacados',
            perdaProdutividade: '6-20%',
            corAlerta: '#FF9800',
            acao: 'Aplicação de inseticida'
          ),
          'alto': SeveridadeDetalhada(
            descricao: 'Acima de 15% de colmos',
            perdaProdutividade: '21-40%',
            corAlerta: '#F44336',
            acao: 'Aplicação imediata'
          ),
        },
        condicoesFavoraveis: CondicoesFavoraveis(
          temperatura: '22-32°C',
          umidade: 'Umidade relativa alta (>70%)',
        ),
        limiaresAcao: LimiaresAcao(baixo: 5, medio: 15, alto: 25, unidade: '% colmos atacados'),
        danoEconomico: DanoEconomico(
          descricao: 'Pode causar perdas de até 40% na produtividade',
          perdaMaxima: '40%',
        ),
        fenologia: ['Vegetativo', 'Crescimento'],
        partesAfetadas: ['Colmos'],
        manejoIntegrado: ManejoIntegrado(
          quimico: ['Bacillus thuringiensis'],
          biologico: ['Cotesia flavipes', 'Trichogramma galloi'],
          cultural: ['Destruição de restos culturais', 'Queima controlada'],
        ),
        observacoes: [
          'Controle em cana-planta é prioritário',
          'Aplicação em condições secas',
          'Considerar queima controlada'
        ],
        icone: '🦋',
        categoria: 'Praga',
        culturaId: 'cana',
        nivelAcao: 'Controle quando 5% dos colmos apresentam danos',
      ),
    ];
  }
  
  /// Cria organismo melhorado genérico
  EnhancedAIOrganismData _createEnhancedOrganism({
    required String name,
    required String scientificName,
    required String type,
    required List<String> crops,
    required List<String> symptoms,
    required List<String> managementStrategies,
    required String description,
    required List<FaseDesenvolvimento> fases,
    required Map<String, SeveridadeDetalhada> severidadeDetalhada,
    required CondicoesFavoraveis condicoesFavoraveis,
    required LimiaresAcao limiaresAcao,
    required DanoEconomico danoEconomico,
    required List<String> fenologia,
    required List<String> partesAfetadas,
    required ManejoIntegrado manejoIntegrado,
    required List<String> observacoes,
    required String icone,
    required String categoria,
    required String culturaId,
    required String nivelAcao,
  }) {
    return EnhancedAIOrganismData(
      id: name.hashCode,
      name: name,
      scientificName: scientificName,
      type: type,
      crops: crops,
      symptoms: symptoms,
      managementStrategies: managementStrategies,
      description: description,
      imageUrl: '',
      characteristics: {},
      severity: 0.5,
      keywords: _extractKeywordsFromName(name),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fases: fases,
      severidadeDetalhada: severidadeDetalhada,
      condicoesFavoraveis: condicoesFavoraveis,
      limiaresAcao: limiaresAcao,
      danoEconomico: danoEconomico,
      fenologia: fenologia,
      partesAfetadas: partesAfetadas,
      manejoIntegrado: manejoIntegrado,
      observacoes: observacoes,
      icone: icone,
      ativo: true,
      categoria: categoria,
      culturaId: culturaId,
      nivelAcao: nivelAcao,
    );
  }
  
  /// Extrai palavras-chave do nome
  List<String> _extractKeywordsFromName(String name) {
    return name.toLowerCase()
        .split(' ')
        .where((word) => word.length > 2)
        .toList();
  }
}

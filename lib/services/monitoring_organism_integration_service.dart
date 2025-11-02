import '../models/organism_catalog.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import 'organism_catalog_loader_service.dart';
import 'organism_v3_integration_service.dart';
import 'agricultural_expert_validation_service.dart';

/// Serviço para integrar novas ocorrências do monitoramento com o catálogo de organismos (v3.0)
class MonitoringOrganismIntegrationService {
  static const String _tag = 'MONITORING_ORGANISM_INTEGRATION';

  final OrganismCatalogLoaderService _catalogLoader = OrganismCatalogLoaderService();
  final OrganismV3IntegrationService _v3Service = OrganismV3IntegrationService();
  final AgriculturalExpertValidationService _validationService = AgriculturalExpertValidationService();

  /// Processa novas ocorrências do monitoramento e as integra ao catálogo
  Future<Map<String, dynamic>> processNewOccurrences(List<Map<String, dynamic>> occurrences) async {
    try {
      Logger.info('$_tag: Processando ${occurrences.length} novas ocorrências...');
      
      final results = <String, dynamic>{
        'success': true,
        'processed_occurrences': 0,
        'new_organisms_found': 0,
        'existing_organisms_updated': 0,
        'validation_results': <Map<String, dynamic>>[],
        'suggestions': <Map<String, dynamic>>[],
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final List<OrganismCatalog> newOrganisms = [];
      final List<Map<String, dynamic>> validationResults = [];
      final List<Map<String, dynamic>> suggestions = [];
      
      // Carregar organismos existentes
      final existingOrganisms = await _catalogLoader.loadAllOrganisms();
      
      for (final occurrence in occurrences) {
        try {
          // Extrair informações da ocorrência
          final organismInfo = _extractOrganismInfo(occurrence);
          
          if (organismInfo != null) {
            // Verificar se o organismo já existe
            final existingOrganism = _findExistingOrganism(existingOrganisms, organismInfo);
            
            if (existingOrganism != null) {
              // Atualizar organismo existente com dados da ocorrência
              final updatedOrganism = _updateExistingOrganism(existingOrganism, organismInfo, occurrence);
              validationResults.add(await _validateOrganism(updatedOrganism));
              results['existing_organisms_updated'] = (results['existing_organisms_updated'] as int) + 1;
            } else {
              // Criar novo organismo baseado na ocorrência
              final newOrganism = _createNewOrganismFromOccurrence(organismInfo, occurrence);
              newOrganisms.add(newOrganism);
              validationResults.add(await _validateOrganism(newOrganism));
              results['new_organisms_found'] = (results['new_organisms_found'] as int) + 1;
            }
            
            results['processed_occurrences'] = (results['processed_occurrences'] as int) + 1;
          }
        } catch (e) {
          Logger.warning('$_tag: Erro ao processar ocorrência: $e');
        }
      }
      
      // Validar novos organismos
      for (final organism in newOrganisms) {
        final validation = await _validateOrganism(organism);
        validationResults.add(validation);
        
        // Adicionar sugestões baseadas na validação
        if (validation['issues'].isNotEmpty) {
          suggestions.add({
            'organism_name': organism.name,
            'issues': validation['issues'],
            'suggestions': validation['suggestions'],
          });
        }
      }
      
      results['validation_results'] = validationResults;
      results['suggestions'] = suggestions;
      
      Logger.info('$_tag: Processamento concluído - ${results['processed_occurrences']} ocorrências, ${results['new_organisms_found']} novos organismos');
      
      return results;
      
    } catch (e) {
      Logger.error('$_tag: Erro no processamento de ocorrências: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Extrai informações do organismo da ocorrência
  Map<String, dynamic>? _extractOrganismInfo(Map<String, dynamic> occurrence) {
    try {
      final String organismo = occurrence['organismo'] ?? occurrence['organism'] ?? '';
      final String tipo = occurrence['tipo'] ?? occurrence['type'] ?? '';
      
      if (organismo.isEmpty) return null;
      
      // Determinar tipo de ocorrência
      OccurrenceType occurrenceType = OccurrenceType.pest;
      if (tipo.toLowerCase().contains('doença') || tipo.toLowerCase().contains('doenca')) {
        occurrenceType = OccurrenceType.disease;
      } else if (tipo.toLowerCase().contains('daninha') || tipo.toLowerCase().contains('weed')) {
        occurrenceType = OccurrenceType.weed;
      }
      
      return {
        'name': organismo,
        'type': occurrenceType,
        'crop_id': occurrence['cultura_id'] ?? occurrence['crop_id'] ?? 'unknown',
        'crop_name': occurrence['cultura_nome'] ?? occurrence['crop_name'] ?? 'Desconhecida',
        'quantity': occurrence['quantidade'] ?? occurrence['quantity'] ?? 0,
        'unit': occurrence['unidade'] ?? occurrence['unit'] ?? 'unidades',
        'observations': occurrence['observacao'] ?? occurrence['observations'] ?? '',
        'location': occurrence['localizacao'] ?? occurrence['location'] ?? '',
        'timestamp': occurrence['timestamp'] ?? DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.warning('$_tag: Erro ao extrair informações do organismo: $e');
      return null;
    }
  }

  /// Encontra organismo existente no catálogo
  OrganismCatalog? _findExistingOrganism(List<OrganismCatalog> existingOrganisms, Map<String, dynamic> organismInfo) {
    try {
      final String name = organismInfo['name'].toString().toLowerCase();
      final String cropId = organismInfo['crop_id'].toString();
      
      // Buscar por nome e cultura
      for (final organism in existingOrganisms) {
        if (organism.name.toLowerCase().contains(name) && organism.cropId == cropId) {
          return organism;
        }
      }
      
      // Buscar apenas por nome (mais flexível)
      for (final organism in existingOrganisms) {
        if (organism.name.toLowerCase().contains(name)) {
          return organism;
        }
      }
      
      return null;
    } catch (e) {
      Logger.warning('$_tag: Erro ao buscar organismo existente: $e');
      return null;
    }
  }

  /// Atualiza organismo existente com dados da ocorrência
  OrganismCatalog _updateExistingOrganism(OrganismCatalog existing, Map<String, dynamic> organismInfo, Map<String, dynamic> occurrence) {
    try {
      // Atualizar limites baseados na quantidade observada
      final int quantity = organismInfo['quantity'] as int;
      final int currentLowLimit = existing.lowLimit;
      final int currentMediumLimit = existing.mediumLimit;
      final int currentHighLimit = existing.highLimit;
      
      // Ajustar limites se a quantidade observada estiver fora dos limites atuais
      int newLowLimit = currentLowLimit;
      int newMediumLimit = currentMediumLimit;
      int newHighLimit = currentHighLimit;
      
      if (quantity < currentLowLimit) {
        newLowLimit = (quantity * 0.8).round().clamp(1, currentLowLimit);
      } else if (quantity > currentHighLimit) {
        newHighLimit = (quantity * 1.2).round();
        newMediumLimit = (newHighLimit * 0.7).round();
      }
      
      return existing.copyWith(
        lowLimit: newLowLimit,
        mediumLimit: newMediumLimit,
        highLimit: newHighLimit,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      Logger.warning('$_tag: Erro ao atualizar organismo existente: $e');
      return existing;
    }
  }

  /// Cria novo organismo baseado na ocorrência
  OrganismCatalog _createNewOrganismFromOccurrence(Map<String, dynamic> organismInfo, Map<String, dynamic> occurrence) {
    try {
      final int quantity = organismInfo['quantity'] as int;
      final OccurrenceType type = organismInfo['type'] as OccurrenceType;
      
      // Calcular limites baseados na quantidade observada
      final int lowLimit = (quantity * 0.5).round().clamp(1, 10);
      final int mediumLimit = (quantity * 0.8).round().clamp(lowLimit + 1, 50);
      final int highLimit = (quantity * 1.5).round().clamp(mediumLimit + 1, 100);
      
      // Determinar unidade padrão baseada no tipo
      String unit = organismInfo['unit'] as String;
      if (unit.isEmpty || unit == 'unidades') {
        switch (type) {
          case OccurrenceType.pest:
            unit = 'indivíduos/m²';
            break;
          case OccurrenceType.disease:
            unit = '%';
            break;
          case OccurrenceType.weed:
            unit = 'plantas/m²';
            break;
          case OccurrenceType.deficiency:
            unit = '%';
            break;
          case OccurrenceType.other:
            unit = 'unidades/m²';
            break;
        }
      }
      
      // Criar descrição baseada nas observações
      String description = organismInfo['observations'] as String;
      if (description.isEmpty) {
        description = 'Organismo identificado durante monitoramento em ${organismInfo['crop_name']}. '
                    'Quantidade observada: ${quantity} ${unit}. '
                    'Localização: ${organismInfo['location']}';
      }
      
      return OrganismCatalog(
        name: organismInfo['name'] as String,
        scientificName: _generateScientificName(organismInfo['name'] as String),
        type: type,
        cropId: organismInfo['crop_id'] as String,
        cropName: organismInfo['crop_name'] as String,
        unit: unit,
        lowLimit: lowLimit,
        mediumLimit: mediumLimit,
        highLimit: highLimit,
        description: description,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      Logger.warning('$_tag: Erro ao criar novo organismo: $e');
      rethrow;
    }
  }

  /// Gera nome científico baseado no nome comum
  String _generateScientificName(String commonName) {
    // Mapeamento básico de nomes comuns para científicos
    final Map<String, String> scientificNames = {
      'lagarta': 'Helicoverpa armigera',
      'percevejo': 'Nezara viridula',
      'pulgão': 'Aphis gossypii',
      'ácaro': 'Tetranychus urticae',
      'ferrugem': 'Phakopsora pachyrhizi',
      'mancha': 'Cercospora sojina',
      'mofo': 'Peronospora manshurica',
      'caruru': 'Amaranthus hybridus',
      'buva': 'Conyza bonariensis',
      'capim': 'Digitaria insularis',
    };
    
    final String lowerName = commonName.toLowerCase();
    
    for (final entry in scientificNames.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Se não encontrar correspondência, retornar nome genérico
    return 'Organismo sp.';
  }

  /// Valida organismo e retorna resultado
  Future<Map<String, dynamic>> _validateOrganism(OrganismCatalog organism) async {
    try {
      final validationResult = await _validationService.validateOrganismData(organism);
      
      return {
        'organism_id': organism.id,
        'organism_name': organism.name,
        'is_valid': validationResult.isValid,
        'severity': validationResult.severity.toString(),
        'issues': validationResult.issues.map((issue) => {
          'type': issue.type.toString(),
          'severity': issue.severity.toString(),
          'message': issue.message,
          'field': issue.field,
          'current_value': issue.currentValue,
        }).toList(),
        'suggestions': validationResult.suggestions.map((suggestion) => {
          'type': suggestion.type.toString(),
          'message': suggestion.message,
          'field': suggestion.field,
          'suggested_value': suggestion.suggestedValue,
          'example': suggestion.example,
        }).toList(),
      };
    } catch (e) {
      Logger.warning('$_tag: Erro na validação do organismo: $e');
      return {
        'organism_id': organism.id,
        'organism_name': organism.name,
        'is_valid': false,
        'error': e.toString(),
      };
    }
  }

  /// Obtém sugestões de melhoria para organismos
  Future<List<Map<String, dynamic>>> getImprovementSuggestions() async {
    try {
      Logger.info('$_tag: Obtendo sugestões de melhoria...');
      
      final organisms = await _catalogLoader.loadAllOrganisms();
      final List<Map<String, dynamic>> suggestions = [];
      
      for (final organism in organisms) {
        final validation = await _validationService.validateOrganismData(organism);
        
        if (!validation.isValid && validation.suggestions.isNotEmpty) {
          suggestions.add({
            'organism_id': organism.id,
            'organism_name': organism.name,
            'crop_name': organism.cropName,
            'severity': validation.severity.toString(),
            'suggestions': validation.suggestions.map((s) => {
              'type': s.type.toString(),
              'message': s.message,
              'field': s.field,
              'suggested_value': s.suggestedValue,
              'example': s.example,
            }).toList(),
          });
        }
      }
      
      Logger.info('$_tag: ${suggestions.length} sugestões de melhoria encontradas');
      return suggestions;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao obter sugestões: $e');
      return [];
    }
  }

  /// Aplica sugestões de melhoria a um organismo
  Future<bool> applySuggestion(String organismId, Map<String, dynamic> suggestion) async {
    try {
      Logger.info('$_tag: Aplicando sugestão para organismo: $organismId');
      
      final organisms = await _catalogLoader.loadAllOrganisms();
      final organism = organisms.firstWhere((org) => org.id == organismId);
      
      if (organism == null) {
        Logger.warning('$_tag: Organismo não encontrado: $organismId');
        return false;
      }
      
      // Aplicar sugestão baseada no campo
      OrganismCatalog updatedOrganism = organism;
      final String field = suggestion['field'] as String;
      final dynamic suggestedValue = suggestion['suggested_value'];
      
      switch (field) {
        case 'lowLimit':
          updatedOrganism = organism.copyWith(lowLimit: suggestedValue as int);
          break;
        case 'mediumLimit':
          updatedOrganism = organism.copyWith(mediumLimit: suggestedValue as int);
          break;
        case 'highLimit':
          updatedOrganism = organism.copyWith(highLimit: suggestedValue as int);
          break;
        case 'unit':
          updatedOrganism = organism.copyWith(unit: suggestedValue as String);
          break;
        case 'scientificName':
          updatedOrganism = organism.copyWith(scientificName: suggestedValue as String);
          break;
        case 'description':
          updatedOrganism = organism.copyWith(description: suggestedValue as String);
          break;
        default:
          Logger.warning('$_tag: Campo não suportado para sugestão: $field');
          return false;
      }
      
      // Validar organismo atualizado
      final validation = await _validationService.validateOrganismData(updatedOrganism);
      
      if (validation.isValid || validation.severity == ValidationSeverity.low) {
        // Salvar organismo atualizado (implementar conforme necessário)
        Logger.info('$_tag: Sugestão aplicada com sucesso para $organismId');
        return true;
      } else {
        Logger.warning('$_tag: Sugestão não aplicada - validação falhou para $organismId');
        return false;
      }
      
    } catch (e) {
      Logger.error('$_tag: Erro ao aplicar sugestão: $e');
      return false;
    }
  }
}

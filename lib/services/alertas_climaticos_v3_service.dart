import '../models/organism_catalog_v3.dart';
import '../utils/logger.dart';
import 'fortsmart_ai_v3_integration.dart';
import 'organism_catalog_loader_service_v3.dart';

/// Serviço de alertas climáticos automáticos usando dados v3.0
class AlertasClimaticosV3Service {
  final OrganismCatalogLoaderServiceV3 _loader = OrganismCatalogLoaderServiceV3();
  
  /// Gera alertas climáticos para todos os organismos de uma cultura
  Future<List<Map<String, dynamic>>> gerarAlertasParaCultura({
    required String cultura,
    required double temperaturaAtual,
    required double umidadeAtual,
  }) async {
    try {
      Logger.info('🌡️ Gerando alertas climáticos para: $cultura');
      
      final organismos = await _loader.loadCultureOrganismsV3(cultura);
      final alertas = <Map<String, dynamic>>[];
      
      for (var organismo in organismos) {
        if (organismo.climaticConditions == null) continue;
        
        final alerta = FortSmartAIV3Integration.gerarAlertaClimatico(
          organismo: organismo,
          temperaturaAtual: temperaturaAtual,
          umidadeAtual: umidadeAtual,
          cultura: cultura,
        );
        
        // Adicionar apenas alertas de risco médio ou alto
        if (alerta['risco'] >= 0.4) {
          alertas.add({
            ...alerta,
            'organismo_id': organismo.id,
            'categoria': organismo.type.toString(),
          });
        }
      }
      
      // Ordenar por risco (maior primeiro)
      alertas.sort((a, b) => 
        (b['risco'] as double).compareTo(a['risco'] as double)
      );
      
      Logger.info('✅ ${alertas.length} alertas gerados para $cultura');
      return alertas;
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar alertas: $e');
      return [];
    }
  }
  
  /// Monitora condições climáticas e gera alertas proativos
  Future<Map<String, dynamic>> monitorarCondicoes({
    required String cultura,
    required double temperaturaAtual,
    required double umidadeAtual,
    required List<String> organismosMonitorados, // IDs dos organismos
  }) async {
    try {
      final todosOrganismos = await _loader.loadAllOrganismsV3();
      final organismos = todosOrganismos.where((org) => 
        organismosMonitorados.contains(org.id) &&
        org.affectedCrops.any((c) => c.toLowerCase() == cultura.toLowerCase())
      ).toList();
      
      final alertas = <Map<String, dynamic>>[];
      
      for (var organismo in organismos) {
        if (organismo.climaticConditions == null) continue;
        
        final risco = FortSmartAIV3Integration.calcularRiscoClimatico(
          organismo: organismo,
          temperaturaAtual: temperaturaAtual,
          umidadeAtual: umidadeAtual,
        );
        
        if (risco >= 0.5) {
          alertas.add({
            'organismo': organismo.name,
            'organismo_id': organismo.id,
            'risco': risco,
            'nivel': risco >= 0.7 ? 'Alto' : 'Médio',
            'temperatura_ideal': organismo.climaticConditions!.minTemperature != null &&
                                 organismo.climaticConditions!.maxTemperature != null
              ? '${organismo.climaticConditions!.minTemperature}-${organismo.climaticConditions!.maxTemperature}°C'
              : 'N/A',
            'umidade_ideal': organismo.climaticConditions!.minHumidity != null &&
                            organismo.climaticConditions!.maxHumidity != null
              ? '${organismo.climaticConditions!.minHumidity}-${organismo.climaticConditions!.maxHumidity}%'
              : 'N/A',
          });
        }
      }
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'cultura': cultura,
        'temperatura_atual': temperaturaAtual,
        'umidade_atual': umidadeAtual,
        'total_alertas': alertas.length,
        'alertas': alertas,
      };
      
    } catch (e) {
      Logger.error('❌ Erro no monitoramento: $e');
      return {'error': e.toString()};
    }
  }
}


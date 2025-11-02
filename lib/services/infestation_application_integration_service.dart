import 'package:flutter/material.dart';
import '../modules/infestation_map/models/models.dart';
import '../utils/logger.dart';

/// Serviço de integração entre Infestação e Aplicação
/// Permite criar prescrições diretamente a partir de alertas resolvidos
class InfestationApplicationIntegrationService {
  static final InfestationApplicationIntegrationService _instance = 
      InfestationApplicationIntegrationService._internal();
  
  factory InfestationApplicationIntegrationService() => _instance;
  
  InfestationApplicationIntegrationService._internal();
  
  /// Cria prescrição de aplicação a partir de alerta resolvido
  Future<Map<String, dynamic>?> createPrescriptionFromAlert({
    required InfestationAlert alert,
    required BuildContext context,
    String? recommendedProduct,
    double? recommendedDose,
    String? applicationMethod,
    String? notes,
  }) async {
    try {
      Logger.info('🔄 [APP-INTEGRATION] Criando prescrição a partir de alerta: ${alert.id}');
      
      // Preparar dados da prescrição
      final prescriptionData = _preparePrescriptionData(
        alert: alert,
        recommendedProduct: recommendedProduct,
        recommendedDose: recommendedDose,
        applicationMethod: applicationMethod,
        notes: notes,
      );
      
      // Mostrar diálogo de confirmação
      final confirmed = await _showConfirmationDialog(context, prescriptionData);
      
      if (confirmed) {
        // Navegar para tela de prescrição com dados pré-preenchidos
        final result = await _navigateToPrescriptionScreen(context, prescriptionData);
        
        if (result != null) {
          Logger.info('✅ [APP-INTEGRATION] Prescrição criada com sucesso');
          return result;
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ [APP-INTEGRATION] Erro ao criar prescrição: $e');
      return null;
    }
  }
  
  /// Prepara dados da prescrição baseados no alerta
  Map<String, dynamic> _preparePrescriptionData({
    required InfestationAlert alert,
    String? recommendedProduct,
    double? recommendedDose,
    String? applicationMethod,
    String? notes,
  }) {
    // Mapear organismo para produto recomendado
    final productMapping = _getProductMapping(alert.organismoId);
    
    return {
      'talhao_id': alert.talhaoId,
      'organismo_id': alert.organismoId,
      'nivel_infestacao': alert.level,
      'risk_level': alert.riskLevel,
      'priority_score': alert.priorityScore,
      'recommended_product': recommendedProduct ?? productMapping['product'],
      'recommended_dose': recommendedDose ?? productMapping['dose'],
      'application_method': applicationMethod ?? productMapping['method'],
      'notes': notes ?? 'Prescrição gerada automaticamente a partir de alerta de infestação',
      'alert_id': alert.id,
      'alert_created_at': alert.createdAt.toIso8601String(),
      'prescription_type': 'infestation_control',
      'urgency_level': _getUrgencyLevel(alert.level),
      'estimated_area': null, // Será preenchido na tela de prescrição
      'application_date': null, // Será definido pelo usuário
    };
  }
  
  /// Mapeia organismo para produto recomendado
  Map<String, dynamic> _getProductMapping(String organismoId) {
    // Mapeamento básico de organismos para produtos
    final mapping = {
      'Lagarta-do-cartucho': {
        'product': 'Bacillus thuringiensis',
        'dose': 1.0,
        'method': 'Pulverização',
      },
      'Percevejo-marrom': {
        'product': 'Neonicotinóide',
        'dose': 0.5,
        'method': 'Pulverização',
      },
      'Percevejo-verde': {
        'product': 'Neonicotinóide',
        'dose': 0.5,
        'method': 'Pulverização',
      },
      'Mosca-branca': {
        'product': 'Imidacloprido',
        'dose': 0.3,
        'method': 'Pulverização',
      },
      'Ácaro-vermelho': {
        'product': 'Acaricida específico',
        'dose': 0.8,
        'method': 'Pulverização',
      },
      'Bicudo-do-algodoeiro': {
        'product': 'Fipronil',
        'dose': 0.4,
        'method': 'Pulverização',
      },
      'Lagarta-rosada': {
        'product': 'Bacillus thuringiensis',
        'dose': 1.2,
        'method': 'Pulverização',
      },
      'Buva': {
        'product': 'Glifosato',
        'dose': 2.0,
        'method': 'Pulverização',
      },
      'Capim-amargoso': {
        'product': 'Glifosato',
        'dose': 2.5,
        'method': 'Pulverização',
      },
    };
    
    return mapping[organismoId] ?? {
      'product': 'Produto genérico',
      'dose': 1.0,
      'method': 'Pulverização',
    };
  }
  
  /// Obtém nível de urgência baseado no nível do alerta
  String _getUrgencyLevel(String alertLevel) {
    switch (alertLevel) {
      case 'CRÍTICO':
        return 'alta';
      case 'ALTO':
        return 'média';
      case 'MODERADO':
        return 'baixa';
      default:
        return 'baixa';
    }
  }
  
  /// Mostra diálogo de confirmação
  Future<bool> _showConfirmationDialog(BuildContext context, Map<String, dynamic> prescriptionData) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Prescrição de Aplicação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Talhão: ${prescriptionData['talhao_id']}'),
            Text('Organismo: ${prescriptionData['organismo_id']}'),
            Text('Nível: ${prescriptionData['nivel_infestacao']}'),
            const SizedBox(height: 8),
            Text('Produto recomendado: ${prescriptionData['recommended_product']}'),
            Text('Dose: ${prescriptionData['recommended_dose']} L/ha'),
            Text('Método: ${prescriptionData['application_method']}'),
            const SizedBox(height: 8),
            const Text(
              'Deseja criar uma prescrição de aplicação baseada neste alerta?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A4F3D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar Prescrição'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Navega para tela de prescrição
  Future<Map<String, dynamic>?> _navigateToPrescriptionScreen(
    BuildContext context,
    Map<String, dynamic> prescriptionData,
  ) async {
    try {
      // Navegar para tela de prescrição com dados pré-preenchidos
      final result = await Navigator.pushNamed(
        context,
        '/prescription/create',
        arguments: {
          'prefilled_data': prescriptionData,
          'source': 'infestation_alert',
        },
      );
      
      return result as Map<String, dynamic>?;
    } catch (e) {
      Logger.error('❌ [APP-INTEGRATION] Erro na navegação: $e');
      return null;
    }
  }
  
  /// Obtém histórico de prescrições criadas a partir de alertas
  Future<List<Map<String, dynamic>>> getPrescriptionHistory({
    String? alertId,
    String? talhaoId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Implementar busca no banco de dados
      // Por enquanto, retornar lista vazia
      Logger.info('🔍 [APP-INTEGRATION] Buscando histórico de prescrições');
      return [];
    } catch (e) {
      Logger.error('❌ [APP-INTEGRATION] Erro ao buscar histórico: $e');
      return [];
    }
  }
  
  /// Valida se alerta pode gerar prescrição
  bool canCreatePrescription(InfestationAlert alert) {
    // Só pode criar prescrição se alerta foi reconhecido e resolvido
    return alert.isAcknowledged && alert.status.toString() == 'resolvido';
  }
  
  /// Obtém recomendações de aplicação baseadas no alerta
  Map<String, dynamic> getApplicationRecommendations(InfestationAlert alert) {
    final productMapping = _getProductMapping(alert.organismoId);
    
    return {
      'recommended_products': [
        {
          'name': productMapping['product'],
          'dose': productMapping['dose'],
          'method': productMapping['method'],
          'priority': 1,
        },
        // Adicionar produtos alternativos se necessário
      ],
      'application_timing': _getApplicationTiming(alert),
      'weather_considerations': _getWeatherConsiderations(),
      'safety_notes': _getSafetyNotes(productMapping['product']),
    };
  }
  
  /// Obtém timing recomendado para aplicação
  Map<String, dynamic> _getApplicationTiming(InfestationAlert alert) {
    return {
      'best_time': 'Manhã cedo ou final da tarde',
      'avoid_times': 'Meio-dia (temperatura alta)',
      'wind_speed_max': '15 km/h',
      'temperature_range': '15-30°C',
      'humidity_range': '40-80%',
    };
  }
  
  /// Obtém considerações climáticas
  Map<String, dynamic> _getWeatherConsiderations() {
    return {
      'rain_forecast': 'Evitar aplicação se chuva prevista em 24h',
      'wind_direction': 'Aplicar com vento favorável',
      'temperature': 'Evitar temperaturas extremas',
      'humidity': 'Manter umidade adequada',
    };
  }
  
  /// Obtém notas de segurança
  List<String> _getSafetyNotes(String product) {
    return [
      'Usar EPI completo durante aplicação',
      'Respeitar período de carência',
      'Evitar contato com culturas sensíveis',
      'Armazenar produto em local seguro',
      'Seguir bula do produto',
    ];
  }
}

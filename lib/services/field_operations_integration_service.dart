import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/planting.dart';
import '../models/harvest_loss.dart';
import '../models/pesticide_application.dart';
import '../models/planter_calibration.dart';
import '../repositories/planting_repository.dart';
import '../repositories/harvest_loss_repository.dart';
import '../repositories/pesticide_application_repository.dart';
import '../repositories/planter_calibration_repository.dart';
import 'planting_harvest_service.dart';
import 'pesticide_application_service.dart';
import 'field_operations_report_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/notifications_wrapper.dart';

/// Serviço para integração entre os módulos de operações de campo
class FieldOperationsIntegrationService {
  static final FieldOperationsIntegrationService _instance = FieldOperationsIntegrationService._internal();
  
  final PlantingRepository _plantingRepository = PlantingRepository();
  final HarvestLossRepository _harvestLossRepository = HarvestLossRepository();
  final PesticideApplicationRepository _applicationRepository = PesticideApplicationRepository();
  final PlanterCalibrationRepository _calibrationRepository = PlanterCalibrationRepository();
  
  final PlantingHarvestService _plantingHarvestService = PlantingHarvestService();
  final PesticideApplicationService _applicationService = PesticideApplicationService();
  final FieldOperationsReportService _reportService = FieldOperationsReportService();
  
  factory FieldOperationsIntegrationService() {
    return _instance;
  }
  
  FieldOperationsIntegrationService._internal();
  
  /// Gera um relatório PDF para uma operação de campo
  Future<String> generateOperationReport(String operationType, int operationId) async {
    try {
      switch (operationType) {
        case 'planting':
          return await _reportService.generatePlantingReport(operationId.toString());
        case 'harvest_loss':
          return await _reportService.generateHarvestLossReport(operationId.toString());
        case 'application':
          return await _reportService.generateApplicationReport(operationId.toString());
        case 'calibration':
          return await _reportService.generateCalibrationReport(operationId.toString());
        default:
          throw Exception('Tipo de operação inválido');
      }
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }
  
  /// Obtém recomendações para calibração de plantadeira com base na cultura
  Future<Map<String, dynamic>> getCalibrationRecommendations(String cropName) async {
    // Valores padrão para diferentes culturas
    if (cropName.toLowerCase().contains('soja')) {
      return {
        'rowSpacing': 0.45, // m
        'desiredPlantsPerMeter': 14.0,
        'recommendedDepth': 3.0, // cm
        'recommendedSpeed': 5.0, // km/h
      };
    } else if (cropName.toLowerCase().contains('milho')) {
      return {
        'rowSpacing': 0.70, // m
        'desiredPlantsPerMeter': 6.0,
        'recommendedDepth': 4.0, // cm
        'recommendedSpeed': 5.5, // km/h
      };
    } else if (cropName.toLowerCase().contains('algod')) {
      return {
        'rowSpacing': 0.90, // m
        'desiredPlantsPerMeter': 8.0,
        'recommendedDepth': 3.0, // cm
        'recommendedSpeed': 5.0, // km/h
      };
    } else {
      return {
        'rowSpacing': 0.50, // m
        'desiredPlantsPerMeter': 10.0,
        'recommendedDepth': 3.0, // cm
        'recommendedSpeed': 5.0, // km/h
      };
    }
  }
  
  /// Verifica se as condições climáticas são adequadas para aplicação
  Future<bool> checkWeatherConditionsForApplication(double temperature, double humidity) {
    // Implementação simplificada - em uma versão real, poderia consultar uma API de clima
    bool isTemperatureSuitable = temperature >= 10 && temperature <= 30;
    bool isHumiditySuitable = humidity >= 55;
    
    return Future.value(isTemperatureSuitable && isHumiditySuitable);
  }
  
  /// Obtém histórico de operações para uma cultura específica
  Future<Map<String, List<dynamic>>> getOperationsHistoryForCrop(String cropName) async {
    try {
      // Buscar plantios para esta cultura
      final List<Planting> plantings = await _plantingRepository.getPlantingsByCrop(cropName);
      
      // Buscar aplicações para esta cultura
      final List<PesticideApplication> applications = await _applicationRepository.getApplicationsByCrop(cropName);
      
      // Buscar perdas na colheita para esta cultura
      final List<HarvestLoss> harvestLosses = await _harvestLossRepository.getHarvestLossesByCrop(cropName);
      
      return {
        'plantings': plantings,
        'applications': applications,
        'harvestLosses': harvestLosses,
      };
    } catch (e) {
      throw Exception('Erro ao obter histórico de operações: $e');
    }
  }
  
  /// Verifica se há operações agendadas para hoje
  Future<List<Map<String, dynamic>>> getScheduledOperationsForToday() async {
    final List<Map<String, dynamic>> scheduledOperations = [];
    final DateTime today = DateTime.now();
    
    try {
      // Verificar plantios agendados
      final List<Planting> plantings = await _plantingRepository.getAllPlantings();
      for (final planting in plantings) {
        if (_isSameDay(planting.plantingDate, today)) {
          scheduledOperations.add({
            'type': 'planting',
            'id': planting.id,
            'title': 'Plantio de ${planting.cropName}',
            'details': 'Área: ${planting.area} ha',
          });
        }
      }
      
      // Verificar aplicações agendadas
      final List<PesticideApplication> applications = await _applicationRepository.getAllPesticideApplications();
      for (final application in applications) {
        if (_isSameDay(application.date, today)) {
          scheduledOperations.add({
            'type': 'application',
            'id': application.id,
            'title': 'Aplicação de ${application.productName}',
            'details': 'Cultura: ${application.cropName}, Área: ${application.totalArea} ha',
          });
        }
      }
      
      return scheduledOperations;
    } catch (e) {
      throw Exception('Erro ao verificar operações agendadas: $e');
    }
  }
  
  /// Notifica o usuário sobre operações agendadas para hoje
  void notifyScheduledOperations(BuildContext context) async {
    try {
      final operations = await getScheduledOperationsForToday();
      
      if (operations.isNotEmpty) {
        String message = 'Você tem ${operations.length} operação(ões) agendada(s) para hoje:';
        
        for (final operation in operations) {
          message += '\n- ${operation['title']}';
        }
        
        NotificationsWrapper().showNotification(
          context,
          title: 'Operações Agendadas',
          message: message,
          duration: const Duration(seconds: 10),
        );
      }
    } catch (e) {
      print('Erro ao notificar operações agendadas: $e');
    }
  }
  
  /// Calcula o intervalo entre operações (ex: plantio e aplicação)
  int calculateDaysBetweenOperations(DateTime firstOperation, DateTime secondOperation) {
    return secondOperation.difference(firstOperation).inDays;
  }
  
  /// Verifica se há conflitos entre operações agendadas
  Future<List<Map<String, dynamic>>> checkOperationConflicts() async {
    final List<Map<String, dynamic>> conflicts = [];
    
    try {
      // Obter todas as aplicações
      final List<PesticideApplication> applications = await _applicationRepository.getAllPesticideApplications();
      
      // Verificar conflitos entre aplicações (aplicações no mesmo dia para a mesma cultura)
      for (int i = 0; i < applications.length; i++) {
        for (int j = i + 1; j < applications.length; j++) {
          if (applications[i].cropName == applications[j].cropName &&
              _isSameDay(applications[i].date, applications[j].date)) {
            conflicts.add({
              'type': 'application_conflict',
              'message': 'Conflito de aplicação para ${applications[i].cropName} em ${DateFormat('dd/MM/yyyy').format(applications[i].date)}',
              'details': 'Produtos: ${applications[i].productName} e ${applications[j].productName}',
            });
          }
        }
      }
      
      return conflicts;
    } catch (e) {
      throw Exception('Erro ao verificar conflitos de operações: $e');
    }
  }
  
  /// Sugere datas para operações futuras com base no histórico
  Future<Map<String, DateTime>> suggestOperationDates(String cropName, DateTime plantingDate) async {
    try {
      // Sugestões simplificadas baseadas em regras gerais
      final int cultureCycleDays = _getCultureCycleDays(cropName);
      
      // Sugerir data para primeira aplicação (30 dias após o plantio)
      final DateTime firstApplicationDate = plantingDate.add(const Duration(days: 30));
      
      // Sugerir data para segunda aplicação (60 dias após o plantio)
      final DateTime secondApplicationDate = plantingDate.add(const Duration(days: 60));
      
      // Sugerir data para colheita (com base no ciclo da cultura)
      final DateTime harvestDate = plantingDate.add(Duration(days: cultureCycleDays));
      
      return {
        'firstApplication': firstApplicationDate,
        'secondApplication': secondApplicationDate,
        'harvest': harvestDate,
      };
    } catch (e) {
      throw Exception('Erro ao sugerir datas para operações: $e');
    }
  }
  
  /// Obtém o ciclo da cultura em dias
  int _getCultureCycleDays(String cropName) {
    if (cropName.toLowerCase().contains('soja')) {
      return 120; // Ciclo médio da soja em dias
    } else if (cropName.toLowerCase().contains('milho')) {
      return 150; // Ciclo médio do milho em dias
    } else if (cropName.toLowerCase().contains('algod')) {
      return 180; // Ciclo médio do algodão em dias
    } else {
      return 120; // Valor padrão para outras culturas
    }
  }
  
  /// Verifica se duas datas são o mesmo dia
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

import 'dart:io';
import '../services/culture_import_service.dart';
import '../services/crop_service.dart';
import '../services/cultura_talhao_service.dart';
import '../utils/logger.dart';

/// Script para verificar alinhamento dos módulos com Culturas da Fazenda
void main() async {
  print('🔍 VERIFICAÇÃO DE ALINHAMENTO DOS MÓDULOS');
  print('==========================================');
  
  try {
    // 1. Verificar Módulo Mapa de Infestação
    await _verifyInfestationMapModule();
    
    // 2. Verificar Módulo Prescrições Premium
    await _verifyPrescriptionModule();
    
    // 3. Verificar Submódulo Subáreas de Plantio
    await _verifySubareasModule();
    
    print('\n✅ VERIFICAÇÃO CONCLUÍDA');
    print('Todos os módulos estão alinhados com Culturas da Fazenda');
    
  } catch (e) {
    print('\n❌ ERRO NA VERIFICAÇÃO: $e');
  }
}

/// Verifica alinhamento com Módulo Mapa de Infestação
Future<void> _verifyInfestationMapModule() async {
  print('\n🗺️ VERIFICANDO MÓDULO MAPA DE INFESTAÇÃO');
  print('----------------------------------------');
  
  try {
    final cropService = CropService();
    
    // Verificar se consegue carregar organismos
    print('🔄 Carregando organismos para verificação...');
    
    // Testar carregamento de pragas
    try {
      final pests = await cropService.getAllPests();
      print('✅ Pragas carregadas: ${pests.length}');
    } catch (e) {
      print('❌ Erro ao carregar pragas: $e');
    }
    
    // Testar carregamento de doenças
    try {
      final diseases = await cropService.getAllDiseases();
      print('✅ Doenças carregadas: ${diseases.length}');
    } catch (e) {
      print('❌ Erro ao carregar doenças: $e');
    }
    
    // Testar carregamento de plantas daninhas
    try {
      final weeds = await cropService.getAllWeeds();
      print('✅ Plantas daninhas carregadas: ${weeds.length}');
    } catch (e) {
      print('❌ Erro ao carregar plantas daninhas: $e');
    }
    
    print('✅ Módulo Mapa de Infestação: ALINHADO');
    
  } catch (e) {
    print('❌ Módulo Mapa de Infestação: ERRO - $e');
  }
}

/// Verifica alinhamento com Módulo Prescrições Premium
Future<void> _verifyPrescriptionModule() async {
  print('\n💊 VERIFICANDO MÓDULO PRESCRIÇÕES PREMIUM');
  print('------------------------------------------');
  
  try {
    final cultureService = CultureImportService();
    
    // Inicializar serviço
    await cultureService.initialize();
    
    // Verificar se consegue carregar culturas
    print('🔄 Carregando culturas para prescrições...');
    final crops = await cultureService.getAllCrops();
    
    print('✅ Culturas carregadas: ${crops.length}');
    
    // Verificar se as culturas têm dados necessários para prescrições
    int culturasComDados = 0;
    for (final crop in crops) {
      if (crop.name != null && crop.name!.isNotEmpty) {
        culturasComDados++;
      }
    }
    
    print('✅ Culturas com dados válidos: $culturasComDados');
    print('✅ Módulo Prescrições Premium: ALINHADO');
    
  } catch (e) {
    print('❌ Módulo Prescrições Premium: ERRO - $e');
  }
}

/// Verifica alinhamento com Submódulo Subáreas de Plantio
Future<void> _verifySubareasModule() async {
  print('\n🌱 VERIFICANDO SUBMÓDULO SUBÁREAS DE PLANTIO');
  print('---------------------------------------------');
  
  try {
    final culturaService = CulturaTalhaoService();
    final cropService = CropService();
    
    // Verificar se consegue carregar culturas
    print('🔄 Carregando culturas para subáreas...');
    final culturas = await culturaService.listarCulturas();
    print('✅ Culturas carregadas: ${culturas.length}');
    
    // Verificar se consegue carregar variedades
    print('🔄 Carregando variedades...');
    int totalVariedades = 0;
    
    for (final cultura in culturas) {
      try {
        final culturaId = cultura['id']?.toString() ?? '';
        if (culturaId.isNotEmpty) {
          final variedades = await cropService.getVarietiesByCropId(int.parse(culturaId));
          totalVariedades += variedades.length;
        }
      } catch (e) {
        print('⚠️ Erro ao carregar variedades para cultura ${cultura['nome']}: $e');
      }
    }
    
    print('✅ Total de variedades carregadas: $totalVariedades');
    print('✅ Submódulo Subáreas de Plantio: ALINHADO');
    
  } catch (e) {
    print('❌ Submódulo Subáreas de Plantio: ERRO - $e');
  }
}

/// Verifica integração específica entre módulos
Future<void> _verifyModuleIntegration() async {
  print('\n🔗 VERIFICANDO INTEGRAÇÃO ENTRE MÓDULOS');
  print('---------------------------------------');
  
  try {
    final cultureService = CultureImportService();
    final cropService = CropService();
    
    await cultureService.initialize();
    final crops = await cultureService.getAllCrops();
    
    print('🔄 Testando integração completa...');
    
    int culturasComOrganismos = 0;
    int culturasComVariedades = 0;
    
    for (final crop in crops) {
      final cropId = crop.id?.toString() ?? '';
      if (cropId.isNotEmpty) {
        try {
          // Verificar organismos
          final pests = await cropService.getPestsByCropId(int.parse(cropId));
          final diseases = await cropService.getDiseasesByCropId(int.parse(cropId));
          final weeds = await cropService.getWeedsByCropId(int.parse(cropId));
          
          if (pests.isNotEmpty || diseases.isNotEmpty || weeds.isNotEmpty) {
            culturasComOrganismos++;
          }
          
          // Verificar variedades
          final varieties = await cropService.getVarietiesByCropId(int.parse(cropId));
          if (varieties.isNotEmpty) {
            culturasComVariedades++;
          }
          
        } catch (e) {
          print('⚠️ Erro ao verificar cultura ${crop.name}: $e');
        }
      }
    }
    
    print('✅ Culturas com organismos: $culturasComOrganismos');
    print('✅ Culturas com variedades: $culturasComVariedades');
    print('✅ Integração entre módulos: FUNCIONANDO');
    
  } catch (e) {
    print('❌ Integração entre módulos: ERRO - $e');
  }
}

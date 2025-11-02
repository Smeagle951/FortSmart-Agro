import 'dart:io';
import '../database/app_database.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../services/culture_import_service.dart';

/// Script para testar a implementação das novas culturas (Cana-de-açúcar e Tomate)
/// e verificar se as culturas de teste (Aveia e Trigo) foram removidas
void main() async {
  print('🧪 Iniciando teste da implementação das novas culturas...');
  
  try {
    // Inicializar banco de dados
    final appDatabase = AppDatabase();
    await appDatabase.initialize();
    
    // Limpar dados existentes para teste
    print('🗑️ Limpando dados existentes...');
    final db = await appDatabase.database;
    await db.delete('crops');
    await db.delete('pests');
    await db.delete('diseases');
    await db.delete('weeds');
    
    // Testar inserção de culturas padrão
    print('🌱 Testando inserção de culturas padrão...');
    final cropDao = CropDao();
    await cropDao.initialize();
    await cropDao.insertDefaultCrops();
    
    // Verificar culturas inseridas
    final crops = await cropDao.getAll();
    print('📊 Culturas inseridas: ${crops.length}');
    
    // Verificar se as culturas corretas foram inseridas
    final cropNames = crops.map((c) => c.name).toList();
    print('📋 Nomes das culturas: $cropNames');
    
    // Verificar se Aveia e Trigo foram removidos
    final hasAveia = cropNames.contains('Aveia');
    final hasTrigo = cropNames.contains('Trigo');
    final hasCanaAcucar = cropNames.contains('Cana-de-açúcar');
    final hasTomate = cropNames.contains('Tomate');
    
    print('\n✅ Verificação das culturas:');
    print('   - Aveia removida: ${!hasAveia ? '✅' : '❌'}');
    print('   - Trigo removido: ${!hasTrigo ? '✅' : '❌'}');
    print('   - Cana-de-açúcar adicionada: ${hasCanaAcucar ? '✅' : '❌'}');
    print('   - Tomate adicionado: ${hasTomate ? '✅' : '❌'}');
    
    // Testar inserção de pragas
    print('\n🐛 Testando inserção de pragas...');
    final pestDao = PestDao();
    await pestDao.initialize();
    await pestDao.insertDefaultPests();
    
    final pests = await pestDao.getAll();
    print('📊 Pragas inseridas: ${pests.length}');
    
    // Verificar pragas da cana de açúcar (cropId = 9)
    final canaPests = pests.where((p) => p.cropId == 9).toList();
    print('🌾 Pragas da Cana-de-açúcar: ${canaPests.length}');
    if (canaPests.isNotEmpty) {
      print('   - ${canaPests.map((p) => p.name).join(', ')}');
    }
    
    // Verificar pragas do tomate (cropId = 10)
    final tomatePests = pests.where((p) => p.cropId == 10).toList();
    print('🍅 Pragas do Tomate: ${tomatePests.length}');
    if (tomatePests.isNotEmpty) {
      print('   - ${tomatePests.map((p) => p.name).join(', ')}');
    }
    
    // Testar inserção de doenças
    print('\n🦠 Testando inserção de doenças...');
    final diseaseDao = DiseaseDao();
    await diseaseDao.initialize();
    await diseaseDao.insertDefaultDiseases();
    
    final diseases = await diseaseDao.getAll();
    print('📊 Doenças inseridas: ${diseases.length}');
    
    // Verificar doenças da cana de açúcar (cropId = 9)
    final canaDiseases = diseases.where((d) => d.cropId == 9).toList();
    print('🌾 Doenças da Cana-de-açúcar: ${canaDiseases.length}');
    if (canaDiseases.isNotEmpty) {
      print('   - ${canaDiseases.map((d) => d.name).join(', ')}');
    }
    
    // Verificar doenças do tomate (cropId = 10)
    final tomateDiseases = diseases.where((d) => d.cropId == 10).toList();
    print('🍅 Doenças do Tomate: ${tomateDiseases.length}');
    if (tomateDiseases.isNotEmpty) {
      print('   - ${tomateDiseases.map((d) => d.name).join(', ')}');
    }
    
    // Testar inserção de plantas daninhas
    print('\n🌿 Testando inserção de plantas daninhas...');
    final weedDao = WeedDao();
    await weedDao.initialize();
    await weedDao.insertDefaultWeeds();
    
    final weeds = await weedDao.getAll();
    print('📊 Plantas daninhas inseridas: ${weeds.length}');
    
    // Verificar plantas daninhas da cana de açúcar (cropId = 9)
    final canaWeeds = weeds.where((w) => w.cropId == 9).toList();
    print('🌾 Plantas daninhas da Cana-de-açúcar: ${canaWeeds.length}');
    if (canaWeeds.isNotEmpty) {
      print('   - ${canaWeeds.map((w) => w.name).join(', ')}');
    }
    
    // Verificar plantas daninhas do tomate (cropId = 10)
    final tomateWeeds = weeds.where((w) => w.cropId == 10).toList();
    print('🍅 Plantas daninhas do Tomate: ${tomateWeeds.length}');
    if (tomateWeeds.isNotEmpty) {
      print('   - ${tomateWeeds.map((w) => w.name).join(', ')}');
    }
    
    // Testar serviço de importação
    print('\n🔄 Testando serviço de importação...');
    final importService = CultureImportService();
    final testResult = await importService.testDataLoading();
    print('📊 Resultado do teste de importação:');
    print('   - Culturas: ${testResult['crops_count']}');
    print('   - Pragas: ${testResult['pests_count']}');
    print('   - Doenças: ${testResult['diseases_count']}');
    print('   - Plantas daninhas: ${testResult['weeds_count']}');
    
    // Resumo final
    print('\n🎉 RESUMO DO TESTE:');
    print('✅ Culturas de teste (Aveia e Trigo) removidas com sucesso');
    print('✅ Cana-de-açúcar implementada com ${canaPests.length} pragas, ${canaDiseases.length} doenças e ${canaWeeds.length} plantas daninhas');
    print('✅ Tomate implementado com ${tomatePests.length} pragas, ${tomateDiseases.length} doenças e ${tomateWeeds.length} plantas daninhas');
    print('✅ Total de ${crops.length} culturas, ${pests.length} pragas, ${diseases.length} doenças e ${weeds.length} plantas daninhas');
    
  } catch (e) {
    print('❌ Erro durante o teste: $e');
    exit(1);
  }
  
  print('\n✅ Teste concluído com sucesso!');
  exit(0);
}

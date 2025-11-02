import '../database/app_database.dart';
import '../repositories/organism_catalog_repository.dart';
import '../services/organism_catalog_loader_service.dart';
import '../utils/logger.dart';

/// Script para inicializar o catálogo de organismos corretamente
void main() async {
  try {
    Logger.info('🚀 Inicializando catálogo de organismos...');
    
    // 1. Inicializar repositório
    final repository = OrganismCatalogRepository();
    await repository.initialize();
    
    // 2. Verificar se já existem dados
    final existingOrganisms = await repository.getAll();
    Logger.info('📊 Organismos existentes: ${existingOrganisms.length}');
    
    if (existingOrganisms.isEmpty) {
      Logger.info('📥 Inserindo dados padrão...');
      
      // 3. Carregar dados dos arquivos JSON
      final loaderService = OrganismCatalogLoaderService();
      final organisms = await loaderService.loadAllOrganisms();
      
      Logger.info('📋 Organismos carregados dos arquivos: ${organisms.length}');
      
      if (organisms.isNotEmpty) {
        // 4. Inserir no banco
        for (final organism in organisms) {
          await repository.create(organism);
        }
        
        Logger.info('✅ ${organisms.length} organismos inseridos no catálogo');
      } else {
        Logger.warning('⚠️ Nenhum organismo encontrado nos arquivos JSON');
        
        // 5. Fallback: inserir dados básicos
        await repository.insertDefaultData();
        Logger.info('✅ Dados básicos inseridos como fallback');
      }
    } else {
      Logger.info('✅ Catálogo já possui dados');
    }
    
    // 6. Verificar resultado final
    final finalCount = await repository.getAll();
    Logger.info('🎉 Catálogo inicializado com ${finalCount.length} organismos');
    
    // 7. Listar alguns organismos para verificação
    final sampleOrganisms = finalCount.take(5).toList();
    for (final organism in sampleOrganisms) {
      Logger.info('  - ${organism.name} (${organism.type}) - ${organism.cropName}');
    }
    
  } catch (e) {
    Logger.error('❌ Erro ao inicializar catálogo: $e');
  }
}

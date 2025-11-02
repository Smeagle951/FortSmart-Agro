import 'dart:io';

/// Script para corrigir o nome da tabela de catalog_organisms para organism_catalog
/// em todos os arquivos do projeto
void main() async {
  print('🔧 Corrigindo nome da tabela catalog_organisms para organism_catalog...');
  
  final files = [
    'lib/services/organism_catalog_service.dart',
    'lib/services/integrated_monitoring_service.dart',
    'lib/services/monitoring_api_service.dart',
    'lib/services/monitoring_report_service.dart',
    'lib/services/monitoring_prescription_service.dart',
    'lib/database/monitoring_database_schema.dart',
    'lib/scripts/test_monitoring_implementation.dart',
  ];
  
  int totalChanges = 0;
  
  for (final filePath in files) {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        String content = await file.readAsString();
        final originalContent = content;
        
        // Substituir todas as ocorrências
        content = content.replaceAll('catalog_organisms', 'organism_catalog');
        
        if (content != originalContent) {
          await file.writeAsString(content);
          final changes = originalContent.split('catalog_organisms').length - 1;
          totalChanges += changes;
          print('✅ $filePath: $changes substituições');
        } else {
          print('ℹ️ $filePath: nenhuma alteração necessária');
        }
      } else {
        print('⚠️ Arquivo não encontrado: $filePath');
      }
    } catch (e) {
      print('❌ Erro ao processar $filePath: $e');
    }
  }
  
  print('🎉 Correção concluída: $totalChanges substituições realizadas');
}

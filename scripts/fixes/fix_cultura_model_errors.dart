import 'dart:io';

void main() async {
  print('🔧 Iniciando correção automática dos erros do CulturaModel...');
  
  final files = [
    'lib/screens/monitoring/advanced_monitoring_screen.dart',
    'lib/screens/infestacao/mapa_infestacao_screen.dart',
    'lib/providers/cultura_provider.dart',
    'lib/services/farm_culture_sync_service.dart',
    'lib/models/talhoes/talhao_safra_model.dart',
    'lib/screens/plantio/submods/plantio_estande_plantas_screen.dart',
    'lib/screens/plantio/submods/plantio_calibragem_adubo_coleta_screen.dart',
    'lib/screens/plantio/submods/plantio_calibragem_plantadeira_screen.dart',
  ];
  
  for (final file in files) {
    if (await File(file).exists()) {
      print('📝 Corrigindo: $file');
      await fixFile(file);
    }
  }
  
  print('✅ Correções concluídas!');
}

Future<void> fixFile(String filePath) async {
  final file = File(filePath);
  String content = await file.readAsString();
  
  // Correções do CulturaModel
  content = content.replaceAll('cultura.nome', 'cultura.name');
  content = content.replaceAll('cultura.cor', 'cultura.color');
  content = content.replaceAll('cultura.descricao', 'cultura.description');
  content = content.replaceAll('cultura.fazendaId', 'cultura.farmId');
  
  // Correções de construtor
  content = content.replaceAll('nome: ', 'name: ');
  content = content.replaceAll('cor: ', 'color: ');
  content = content.replaceAll('descricao: ', 'description: ');
  content = content.replaceAll('fazendaId: ', 'farmId: ');
  
  // Correções de tipo
  content = content.replaceAll('cultura.id.toString()', 'cultura.id');
  content = content.replaceAll('cultura.color.value', 'cultura.color.value.toString()');
  
  // Correções de CulturaService
  content = content.replaceAll('CulturaService()', 'CulturaService(AppDatabase.instance)');
  
  // Correções de imports
  if (!content.contains("import '../database/app_database.dart';") && 
      content.contains('AppDatabase.instance')) {
    content = content.replaceFirst(
      "import '../models/cultura_model.dart';",
      "import '../models/cultura_model.dart';\nimport '../database/app_database.dart';"
    );
  }
  
  await file.writeAsString(content);
}

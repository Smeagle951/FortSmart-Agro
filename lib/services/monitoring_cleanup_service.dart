import 'dart:io';
import 'package:path/path.dart';
import '../utils/logger.dart';

/// Serviço para limpeza e organização do módulo de monitoramento
/// Remove código duplicado e organiza a estrutura
class MonitoringCleanupService {
  
  /// Executa limpeza completa do módulo de monitoramento
  Future<bool> performFullCleanup() async {
    try {
      Logger.info('🧹 Iniciando limpeza completa do módulo de monitoramento...');
      
      // 1. Verificar arquivos duplicados
      await _checkDuplicateFiles();
      
      // 2. Verificar imports conflitantes
      await _checkConflictingImports();
      
      // 3. Verificar modelos não utilizados
      await _checkUnusedModels();
      
      // 4. Verificar serviços duplicados
      await _checkDuplicateServices();
      
      // 5. Gerar relatório de limpeza
      await _generateCleanupReport();
      
      Logger.info('✅ Limpeza completa concluída!');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro durante limpeza: $e');
      return false;
    }
  }

  /// Verifica arquivos duplicados
  Future<void> _checkDuplicateFiles() async {
    try {
      Logger.info('📋 Verificando arquivos duplicados...');
      
      final duplicateFiles = <String, List<String>>{};
      
      // Verificar modelos duplicados
      final modelFiles = [
        'lib/models/monitoring.dart',
        'lib/modules/monitoring/models/monitoring_model.dart',
      ];
      
      for (final file in modelFiles) {
        if (await File(file).exists()) {
          final fileName = basename(file);
          duplicateFiles.putIfAbsent(fileName, () => []).add(file);
        }
      }
      
      // Verificar repositórios duplicados
      final repositoryFiles = [
        'lib/repositories/monitoring_repository.dart',
        'lib/modules/monitoring/repositories/monitoring_repository.dart',
      ];
      
      for (final file in repositoryFiles) {
        if (await File(file).exists()) {
          final fileName = basename(file);
          duplicateFiles.putIfAbsent(fileName, () => []).add(file);
        }
      }
      
      // Reportar duplicações encontradas
      for (final entry in duplicateFiles.entries) {
        if (entry.value.length > 1) {
          Logger.warning('⚠️ Arquivo duplicado encontrado: ${entry.key}');
          Logger.warning('   Localizações: ${entry.value.join(', ')}');
        }
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar arquivos duplicados: $e');
    }
  }

  /// Verifica imports conflitantes
  Future<void> _checkConflictingImports() async {
    try {
      Logger.info('🔍 Verificando imports conflitantes...');
      
      final filesToCheck = [
        'lib/screens/monitoring/monitoring_point_screen.dart',
        'lib/screens/monitoring/monitoring_screen.dart',
        'lib/services/monitoring_service.dart',
      ];
      
      for (final filePath in filesToCheck) {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          
          // Verificar imports de modelos conflitantes
          if (content.contains('import.*monitoring_model.dart') && 
              content.contains('import.*monitoring.dart')) {
            Logger.warning('⚠️ Imports conflitantes em: $filePath');
            Logger.warning('   - Contém imports de modelos diferentes');
          }
          
          // Verificar imports de repositórios conflitantes
          if (content.contains('import.*monitoring_repository.dart') && 
              content.contains('import.*repositories/monitoring_repository.dart')) {
            Logger.warning('⚠️ Imports conflitantes em: $filePath');
            Logger.warning('   - Contém imports de repositórios diferentes');
          }
        }
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar imports conflitantes: $e');
    }
  }

  /// Verifica modelos não utilizados
  Future<void> _checkUnusedModels() async {
    try {
      Logger.info('📊 Verificando modelos não utilizados...');
      
      final modelFiles = [
        'lib/modules/monitoring/models/monitoring_model.dart',
        'lib/modules/monitoring/models/monitoring_point_model.dart',
        'lib/modules/monitoring/models/pest_occurrence.dart',
        'lib/modules/monitoring/models/disease_occurrence.dart',
        'lib/modules/monitoring/models/weed_occurrence.dart',
      ];
      
      final unusedModels = <String>[];
      
      for (final modelFile in modelFiles) {
        final file = File(modelFile);
        if (await file.exists()) {
          final fileName = basename(modelFile);
          final isUsed = await _isModelUsed(fileName);
          
          if (!isUsed) {
            unusedModels.add(modelFile);
            Logger.warning('⚠️ Modelo não utilizado: $modelFile');
          }
        }
      }
      
      if (unusedModels.isNotEmpty) {
        Logger.info('📋 Modelos não utilizados encontrados: ${unusedModels.length}');
        Logger.info('   Considere remover: ${unusedModels.join(', ')}');
      } else {
        Logger.info('✅ Todos os modelos estão sendo utilizados');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar modelos não utilizados: $e');
    }
  }

  /// Verifica se um modelo está sendo usado
  Future<bool> _isModelUsed(String modelFileName) async {
    try {
      final searchDirectories = [
        'lib/screens',
        'lib/services',
        'lib/repositories',
        'lib/widgets',
      ];
      
      for (final directory in searchDirectories) {
        final dir = Directory(directory);
        if (await dir.exists()) {
          final files = await dir.list(recursive: true).where((entity) => 
            entity is File && entity.path.endsWith('.dart')).toList();
          
          for (final file in files) {
            final content = await File(file.path).readAsString();
            if (content.contains(modelFileName)) {
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao verificar uso do modelo: $e');
      return false;
    }
  }

  /// Verifica serviços duplicados
  Future<void> _checkDuplicateServices() async {
    try {
      Logger.info('🔧 Verificando serviços duplicados...');
      
      final serviceFiles = [
        'lib/services/monitoring_service.dart',
        'lib/modules/monitoring/services/monitoring_service.dart',
        'lib/services/enhanced_monitoring_service.dart',
        'lib/services/premium_monitoring_service.dart',
      ];
      
      final duplicateServices = <String, List<String>>{};
      
      for (final serviceFile in serviceFiles) {
        final file = File(serviceFile);
        if (await file.exists()) {
          final content = await file.readAsString();
          
          // Extrair nome da classe do serviço
          final classNameMatch = RegExp(r'class\s+(\w+)').firstMatch(content);
          if (classNameMatch != null) {
            final className = classNameMatch.group(1);
            duplicateServices.putIfAbsent(className!, () => []).add(serviceFile);
          }
        }
      }
      
      // Reportar serviços duplicados
      for (final entry in duplicateServices.entries) {
        if (entry.value.length > 1) {
          Logger.warning('⚠️ Serviço duplicado encontrado: ${entry.key}');
          Logger.warning('   Localizações: ${entry.value.join(', ')}');
        }
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar serviços duplicados: $e');
    }
  }

  /// Gera relatório de limpeza
  Future<void> _generateCleanupReport() async {
    try {
      Logger.info('📄 Gerando relatório de limpeza...');
      
      final report = '''
# Relatório de Limpeza - Módulo de Monitoramento

## Data: ${DateTime.now()}

## Problemas Identificados:

### 1. Arquivos Duplicados
- Verificar se há modelos duplicados
- Verificar se há repositórios duplicados

### 2. Imports Conflitantes
- Verificar imports de modelos diferentes
- Verificar imports de repositórios diferentes

### 3. Modelos Não Utilizados
- Verificar se modelos do módulo estão sendo usados
- Considerar remoção de modelos não utilizados

### 4. Serviços Duplicados
- Verificar serviços com funcionalidades similares
- Considerar unificação de serviços

## Recomendações:

1. **Usar apenas o modelo principal**: `lib/models/monitoring.dart`
2. **Usar apenas o repositório principal**: `lib/repositories/monitoring_repository.dart`
3. **Usar o serviço de correção**: `MonitoringSaveFixService`
4. **Remover código duplicado não utilizado**

## Próximos Passos:

1. Executar unificação de dados
2. Remover arquivos duplicados
3. Corrigir imports conflitantes
4. Implementar testes automatizados
''';

      // Salvar relatório
      final reportFile = File('lib/docs/monitoring_cleanup_report.md');
      await reportFile.writeAsString(report);
      
      Logger.info('✅ Relatório de limpeza gerado: lib/docs/monitoring_cleanup_report.md');
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório: $e');
    }
  }

  /// Remove arquivos duplicados (modo seguro)
  Future<bool> removeDuplicateFiles({bool dryRun = true}) async {
    try {
      Logger.info('🗑️ ${dryRun ? 'Simulando' : 'Executando'} remoção de arquivos duplicados...');
      
      final filesToRemove = [
        'lib/modules/monitoring/models/monitoring_model.dart',
        'lib/modules/monitoring/models/monitoring_point_model.dart',
        'lib/modules/monitoring/models/pest_occurrence.dart',
        'lib/modules/monitoring/models/disease_occurrence.dart',
        'lib/modules/monitoring/models/weed_occurrence.dart',
        'lib/modules/monitoring/repositories/monitoring_repository.dart',
        'lib/modules/monitoring/services/monitoring_service.dart',
      ];
      
      int removedCount = 0;
      
      for (final filePath in filesToRemove) {
        final file = File(filePath);
        if (await file.exists()) {
          if (dryRun) {
            Logger.info('📋 Simulando remoção: $filePath');
          } else {
            await file.delete();
            Logger.info('🗑️ Removido: $filePath');
          }
          removedCount++;
        }
      }
      
      Logger.info('✅ ${dryRun ? 'Simulação' : 'Remoção'} concluída: $removedCount arquivos');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao remover arquivos: $e');
      return false;
    }
  }

  /// Corrige imports conflitantes
  Future<bool> fixConflictingImports() async {
    try {
      Logger.info('🔧 Corrigindo imports conflitantes...');
      
      final filesToFix = [
        'lib/screens/monitoring/monitoring_point_screen.dart',
        'lib/screens/monitoring/monitoring_screen.dart',
        'lib/services/monitoring_service.dart',
      ];
      
      int fixedCount = 0;
      
      for (final filePath in filesToFix) {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          String fixedContent = content;
          
          // Substituir imports do módulo pelos principais
          fixedContent = fixedContent.replaceAll(
            "import '../../modules/monitoring/models/monitoring_model.dart';",
            "import '../../models/monitoring.dart';"
          );
          
          fixedContent = fixedContent.replaceAll(
            "import '../../modules/monitoring/repositories/monitoring_repository.dart';",
            "import '../../repositories/monitoring_repository.dart';"
          );
          
          if (fixedContent != content) {
            await file.writeAsString(fixedContent);
            Logger.info('🔧 Corrigido: $filePath');
            fixedCount++;
          }
        }
      }
      
      Logger.info('✅ Imports corrigidos: $fixedCount arquivos');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir imports: $e');
      return false;
    }
  }
}

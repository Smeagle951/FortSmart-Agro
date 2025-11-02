import 'diagnose_plantio_issues.dart';

/// Script para executar diagnóstico do módulo de plantio
void main() async {
  print('🔍 INICIANDO DIAGNÓSTICO DO MÓDULO DE PLANTIO...');
  print('⚠️  Este script APENAS identifica problemas, NÃO altera dados!');
  print('');
  
  await DiagnosePlantioIssues.diagnose();
  
  print('');
  print('🎯 PRÓXIMOS PASSOS:');
  print('1. Analise o diagnóstico acima');
  print('2. Identifique os problemas específicos');
  print('3. Aplique correções pontuais se necessário');
  print('4. Teste o módulo de plantio');
}

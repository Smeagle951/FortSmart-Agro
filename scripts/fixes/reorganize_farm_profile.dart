import 'dart:io';

void main() {
  final file = File('lib/screens/farm/farm_profile_screen.dart');
  final content = file.readAsStringSync();
  
  // Encontrar onde começa o método build
  final buildStart = content.indexOf('  @override\n  Widget build(BuildContext context) {');
  if (buildStart == -1) {
    print('❌ Não foi possível encontrar o método build');
    return;
  }
  
  // Encontrar onde termina o método build
  final buildEnd = content.indexOf('  }', buildStart);
  if (buildEnd == -1) {
    print('❌ Não foi possível encontrar o final do método build');
    return;
  }
  
  // Encontrar o final da classe
  final classEnd = content.lastIndexOf('  }\n}');
  if (classEnd == -1) {
    print('❌ Não foi possível encontrar o final da classe');
    return;
  }
  
  // Extrair o método build
  final buildMethod = content.substring(buildStart, buildEnd + 3);
  
  // Extrair todos os outros métodos (após o build)
  final otherMethods = content.substring(buildEnd + 3, classEnd);
  
  // Encontrar onde termina a declaração de variáveis (antes do initState)
  final initStateStart = content.indexOf('  @override\n  void initState() {');
  if (initStateStart == -1) {
    print('❌ Não foi possível encontrar o método initState');
    return;
  }
  
  // Extrair a parte inicial (imports, declaração da classe, variáveis)
  final initialPart = content.substring(0, initStateStart);
  
  // Extrair métodos de lifecycle (initState, dispose, etc.)
  final lifecycleMethods = content.substring(initStateStart, buildStart);
  
  // Reorganizar o arquivo
  final reorganizedContent = initialPart + lifecycleMethods + otherMethods + buildMethod + '\n}';
  
  // Salvar o arquivo reorganizado
  file.writeAsStringSync(reorganizedContent);
  print('✅ Arquivo farm_profile_screen.dart reorganizado com sucesso!');
  print('📊 Tamanho original: ${content.length} caracteres');
  print('📊 Tamanho reorganizado: ${reorganizedContent.length} caracteres');
}

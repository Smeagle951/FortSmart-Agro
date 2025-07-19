import 'dart:io';

void main() async {
  final originalPath = r'c:\Users\fortu\fortsmart_agro_new\lib\screens\farm\farm_profile_screen.dart';
  final backupPath = r'c:\Users\fortu\fortsmart_agro_new\backup\farm_profile_screen.dart.bak2';
  final file = File(originalPath);
  
  // Fazer backup
  await file.copy(backupPath);
  print('Backup criado em $backupPath');
  
  // Ler o conteúdo do arquivo
  String content = await file.readAsString();
  
  // Substituir o bloco problemático (linhas 672 a 815 aproximadamente)
  // Aqui estamos corrigindo as linhas que contêm problemas de indentação
  
  // 1. Corrigir indentação do comentário e GestureDetector na linha 672-673
  content = content.replaceAll(
    "                                     children: [\n                                    // Logo da fazenda (círculo com borda e sombra)\n                                    GestureDetector(",
    "                                     children: [\n                                      // Logo da fazenda (círculo com borda e sombra)\n                                      GestureDetector("
  );
  
  // 2. Corrigir indentação do Align na linha 814
  content = content.replaceAll(
    "                                      _buildInfoRow('📍 Endereço:', farm.address ?? 'Não informado'),\n                                    \n                                    Align(",
    "                                      _buildInfoRow('📍 Endereço:', farm.address ?? 'Não informado'),\n                                    \n                                      Align("
  );
  
  // Salvar o conteúdo corrigido de volta ao arquivo
  await file.writeAsString(content);
  print('Correções aplicadas ao arquivo $originalPath');
}

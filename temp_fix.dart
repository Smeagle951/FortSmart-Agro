// Script temporário para contar parênteses e chaves
import 'dart:io';

void main() {
  final file = File(r'c:\Users\fortu\fortsmart_agro_new\lib\screens\farm\farm_profile_screen.dart');
  final contents = file.readAsStringSync();
  
  int parenthesesCount = 0;
  int bracesCount = 0;
  int bracketsCount = 0;
  
  for (int i = 0; i < contents.length; i++) {
    final char = contents[i];
    if (char == '(') parenthesesCount++;
    if (char == ')') parenthesesCount--;
    if (char == '{') bracesCount++;
    if (char == '}') bracesCount--;
    if (char == '[') bracketsCount++;
    if (char == ']') bracketsCount--;
    
    // Se houver desequilíbrio, mostrar a linha aproximada
    if (parenthesesCount < 0 || bracesCount < 0 || bracketsCount < 0) {
      final lineNumber = contents.substring(0, i).split('\n').length;
      print('Desequilíbrio na linha aproximada $lineNumber:');
      print('  Parênteses: $parenthesesCount');
      print('  Chaves: $bracesCount');
      print('  Colchetes: $bracketsCount');
      
      // Mostrar o contexto
      final lines = contents.split('\n');
      final start = lineNumber > 5 ? lineNumber - 5 : 0;
      final end = start + 10 < lines.length ? start + 10 : lines.length;
      for (int j = start; j < end; j++) {
        print('${j+1}: ${lines[j]}');
      }
      
      break;
    }
  }
  
  print('\nContagem final:');
  print('  Parênteses: $parenthesesCount');
  print('  Chaves: $bracesCount');
  print('  Colchetes: $bracketsCount');
}

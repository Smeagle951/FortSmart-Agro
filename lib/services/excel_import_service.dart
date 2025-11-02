import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/inventory_movement_repository.dart';

/// Serviço para importação de dados de planilhas Excel


class ExcelImportService {
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final InventoryMovementRepository _movementRepository = InventoryMovementRepository();

  /// Importa produtos e entradas de estoque a partir de um arquivo Excel
  Future<ImportResult> importInventoryFromExcel(File file, String responsiblePerson) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    final results = ImportResult();
    
    // Verifica se há planilhas no arquivo
    if (excel.tables.isEmpty) {
      results.errors.add('O arquivo não contém planilhas.');
      return results;
    }
    
    // Usa a primeira planilha
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet];
    
    if (table == null || table.rows.isEmpty) {
      results.errors.add('A planilha está vazia.');
      return results;
    }
    
    // Verifica o cabeçalho
    final headers = _extractRowValues(table.rows[0]);
    final requiredHeaders = [
      'nome', 'tipo', 'formulacao', 'unidade', 'quantidade', 
      'local', 'data', 'nfe', 'fabricante'
    ];
    
    for (final header in requiredHeaders) {
      if (!headers.map((h) => h.toLowerCase()).contains(header)) {
        results.errors.add('Cabeçalho obrigatório não encontrado: $header');
      }
    }
    
    if (results.errors.isNotEmpty) {
      return results;
    }
    
    // Mapeia os índices das colunas
    final nameIndex = _findColumnIndex(headers, 'nome');
    final typeIndex = _findColumnIndex(headers, 'tipo');
    final formulationIndex = _findColumnIndex(headers, 'formulacao');
    final unitIndex = _findColumnIndex(headers, 'unidade');
    final quantityIndex = _findColumnIndex(headers, 'quantidade');
    final locationIndex = _findColumnIndex(headers, 'local');
    final dateIndex = _findColumnIndex(headers, 'data');
    final nfeIndex = _findColumnIndex(headers, 'nfe');
    final manufacturerIndex = _findColumnIndex(headers, 'fabricante');
    final expirationDateIndex = _findColumnIndex(headers, 'validade');
    final minimumLevelIndex = _findColumnIndex(headers, 'nivel_minimo');
    final registrationNumberIndex = _findColumnIndex(headers, 'registro');
    
    // Processa cada linha (exceto o cabeçalho)
    for (int i = 1; i < table.rows.length; i++) {
      try {
        final row = _extractRowValues(table.rows[i]);
        
        // Verifica se a linha tem células suficientes
        if (row.length <= nameIndex || row[nameIndex].trim().isEmpty) {
          continue; // Pula linhas vazias
        }
        
        // Extrai os dados obrigatórios
        final name = row[nameIndex];
        final type = row[typeIndex];
        final formulation = row[formulationIndex];
        final unit = row[unitIndex];
        final quantityStr = row[quantityIndex];
        final location = row[locationIndex];
        final dateStr = row[dateIndex];
        final nfe = row[nfeIndex];
        final manufacturer = row[manufacturerIndex];
        
        // Converte quantidade para double
        double quantity;
        try {
          quantity = double.parse(quantityStr.replaceAll(',', '.'));
        } catch (e) {
          results.errors.add('Linha ${i+1}: Quantidade inválida: $quantityStr');
          continue;
        }
        
        // Converte data para DateTime
        DateTime date;
        try {
          date = _parseDate(dateStr);
        } catch (e) {
          results.errors.add('Linha ${i+1}: Data inválida: $dateStr');
          continue;
        }
        
        // Extrai dados opcionais
        DateTime? expirationDate;
        if (expirationDateIndex >= 0 && expirationDateIndex < row.length && row[expirationDateIndex].isNotEmpty) {
          try {
            expirationDate = _parseDate(row[expirationDateIndex]);
          } catch (e) {
            // Ignora datas de validade inválidas
          }
        }
        
        double? minimumLevel;
        if (minimumLevelIndex >= 0 && minimumLevelIndex < row.length && row[minimumLevelIndex].isNotEmpty) {
          try {
            minimumLevel = double.parse(row[minimumLevelIndex].replaceAll(',', '.'));
          } catch (e) {
            // Ignora níveis mínimos inválidos
          }
        }
        
        String? registrationNumber;
        if (registrationNumberIndex >= 0 && registrationNumberIndex < row.length) {
          registrationNumber = row[registrationNumberIndex];
        }
        
        // Verifica se o produto já existe no estoque
        final existingItems = await _inventoryRepository.getItemsByName(name, formulation);
        
        if (existingItems.isNotEmpty) {
          // Atualiza o item existente
          final existingItem = existingItems.first;
          final updatedItem = existingItem.copyWith(
            quantity: existingItem.quantity + quantity,
            updatedAt: DateTime.now().toIso8601String(),
          );
          
          await _inventoryRepository.updateItem(updatedItem);
          
          // Registra a movimentação de entrada
          final movement = InventoryMovement(
            inventoryItemId: existingItem.id.toString(), // Convertendo para String
            type: MovementType.entry,
            quantity: quantity,
            purpose: 'Importação por Planilha',
            responsiblePerson: responsiblePerson,
            date: date,
            previousQuantity: existingItem.quantity - quantity,
            newQuantity: existingItem.quantity,
            reason: 'Importação por Planilha',
          );
          
          await _movementRepository.addMovement(movement);
          
          results.updatedItems.add(existingItem.name);
        } else {
          // Cria um novo item diretamente no formato do banco de dados
          final now = DateTime.now();
          final dbItem = InventoryItem(
            id: null,
            name: name,
            type: type,
            formulation: formulation,
            unit: unit,
            quantity: quantity,
            location: location,
            expirationDate: expirationDate != null ? DateTime.parse(expirationDate.toIso8601String()) : null,
            manufacturer: manufacturer,
            minimumLevel: minimumLevel,
            registrationNumber: registrationNumber,
            createdAt: now,
            updatedAt: now,
            category: 'Insumo',
          );
          
          // Convertemos para o modelo de banco de dados antes de adicionar
          final dbModelItem = dbItem.toDbModel();
          final itemId = await _inventoryRepository.addItem(dbModelItem);
          
          if (itemId != null) {
            // Registra a movimentação de entrada
            final movement = InventoryMovement(
              inventoryItemId: itemId.toString(), // Convertendo para String
              type: MovementType.entry,
              quantity: quantity,
              purpose: 'Importação por Planilha',
              responsiblePerson: responsiblePerson,
              date: date,
              previousQuantity: 0,
              newQuantity: quantity,
              reason: 'Importação por Planilha',
            );
            
            await _movementRepository.addMovement(movement);
            
            results.createdItems.add(name);
          }
        }
      } catch (e) {
        results.errors.add('Erro ao processar linha ${i+1}: $e');
      }
    }
    
    return results;
  }
  
  /// Gera um arquivo Excel de modelo para importação
  Future<File> generateTemplateFile() async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;
    
    // Define o cabeçalho
    final headers = [
      'Nome', 'Tipo', 'Formulacao', 'Unidade', 'Quantidade', 
      'Local', 'Data', 'NFe', 'Fabricante', 'Validade', 
      'Nivel_Minimo', 'Registro'
    ];
    
    // Adiciona o cabeçalho
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = headers[i]
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          // Removendo o parâmetro backgroundColorHex para evitar o erro
        );
    }
    
    // Adiciona exemplos
    final examples = [
      ['Glifosato', 'Herbicida', 'SL', 'L', '20', 'Depósito A', '01/05/2025', '123456', 'Bayer', '01/05/2027', '10', 'REG12345'],
      ['2,4-D', 'Herbicida', 'EC', 'L', '10', 'Depósito B', '02/05/2025', '123457', 'BASF', '02/05/2027', '5', 'REG67890'],
    ];
    
    for (int i = 0; i < examples.length; i++) {
      for (int j = 0; j < examples[i].length; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
          ..value = examples[i][j];
      }
    }
    
    // Ajusta a largura das colunas
    for (int i = 0; i < headers.length; i++) {
      // Na versão atual do pacote Excel, precisamos definir as propriedades da coluna de outra forma
      try {
        // Tenta definir a largura da coluna usando propriedades do sheet
        if (excel.sheets[sheet.sheetName]?.maxCols != null && 
            excel.sheets[sheet.sheetName]?.maxRows != null) {
          // Definir a largura da coluna de forma compatível
          excel.sheets[sheet.sheetName]?.setColWidth(i, 20);
        }
      } catch (e) {
        print('Aviso: Não foi possível definir a largura da coluna: $e');
      }
    }
    
    // Salva o arquivo
    final directory = await Directory.systemTemp.createTemp('fortsmartagro_');
    final file = File('${directory.path}/modelo_importacao_estoque.xlsx');
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    
    return file;
  }
  
  /// Extrai os valores de uma linha da planilha
  List<String> _extractRowValues(List<Data?> row) {
    return row.map((cell) => cell?.value?.toString() ?? '').toList();
  }
  
  /// Encontra o índice de uma coluna pelo nome (case insensitive)
  int _findColumnIndex(List<String> headers, String columnName) {
    final lowerColumnName = columnName.toLowerCase();
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].toLowerCase() == lowerColumnName) {
        return i;
      }
    }
    return -1;
  }
  
  /// Tenta converter uma string para DateTime em vários formatos
  DateTime _parseDate(String dateStr) {
    final formats = [
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'd/M/yyyy',
      'dd-MM-yyyy',
      'yyyy/MM/dd',
    ];
    
    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (e) {
        // Tenta o próximo formato
      }
    }
    
    throw FormatException('Formato de data não reconhecido: $dateStr');
  }
}

/// Classe para armazenar os resultados da importação
class ImportResult {
  final List<String> createdItems = [];
  final List<String> updatedItems = [];
  final List<String> errors = [];
  
  bool get hasErrors => errors.isNotEmpty;
  
  int get totalProcessed => createdItems.length + updatedItems.length;
  
  String getSummary() {
    return 'Importação concluída: ${createdItems.length} produtos criados, '
        '${updatedItems.length} produtos atualizados, '
        '${errors.length} erros.';
  }
}

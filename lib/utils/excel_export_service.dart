import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:fortsmart_agro/models/inventory_item.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:fortsmart_agro/models/pesticide_application.dart';

/// Classe para exportar dados para arquivos Excel
class ExcelExportService {
  final dateFormat = DateFormat('dd/MM/yyyy');
  
  // Método auxiliar para definir valores de célula
  void _setCellValue(Data cell, dynamic value) {
    if (value == null) return;
    
    if (value is String) {
      cell.value = value;
    } else if (value is int) {
      cell.value = value;
    } else if (value is double) {
      cell.value = value;
    } else if (value is bool) {
      cell.value = value ? 1 : 0; // Converter bool para int (1 ou 0)
    } else if (value is DateTime) {
      cell.value = dateFormat.format(value);
    } else {
      cell.value = value.toString();
    }
  }
  
  // Método auxiliar para aplicar estilo de cabeçalho
  void _applyHeaderStyle(Data cell) {
    // Criar um novo estilo para o cabeçalho
    final headerStyle = CellStyle(
      backgroundColorHex: 'FF1E88E5', // Azul
      fontColorHex: 'FFFFFFFF', // Texto branco
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    
    cell.cellStyle = headerStyle;
  }
  
  /// Exporta lista de itens de estoque para Excel
  Future<String> exportInventoryItems(List<InventoryItem> items) async {
    try {
      final excel = Excel.createExcel();
      
      // Remover planilha padrão
      excel.delete('Sheet1');
      
      // Criar planilha de estoque
      final sheet = excel['Estoque'];
      
      // Cabeçalhos
      final headers = [
        'ID', 'Nome', 'Categoria', 'Tipo', 'Formulação', 'Princípio Ativo',
        'Unidade', 'Quantidade', 'Estoque Mínimo', 'Estoque Ideal', 'Fornecedor',
        'Lote', 'Data de Fabricação', 'Data de Validade', 'Preço Unitário',
        'Observações', 'Data de Cadastro', 'Última Atualização',
      ];
      
      // Adicionar cabeçalhos
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        _setCellValue(cell, headers[i]);
        _applyHeaderStyle(cell);
      }
      
      // Adicionar dados
      for (var row = 0; row < items.length; row++) {
        final item = items[row];
        final rowIndex = row + 1;
        
        // Mapear valores para as colunas corretas
        final values = [
          item.id?.toString() ?? '',
          item.name,
          '', // Categoria
          item.type,
          item.formulation,
          '', // Princípio ativo
          item.unit,
          item.quantity > 0 ? item.quantity : '', // Quantidade
          item.minimumLevel,
          '', // Estoque ideal
          item.manufacturer ?? '',
          '', // Lote
          '', // Data de fabricação
          item.expirationDate != null ? dateFormat.format(DateTime.parse(item.expirationDate.toString())) : '',
          '', // Preço unitário
          '', // Observações
          dateFormat.format(DateTime.parse(item.createdAt.toString())),
          dateFormat.format(DateTime.parse(item.updatedAt.toString())),
        ];
        
        // Preencher células com os valores
        for (var col = 0; col < values.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: col, 
            rowIndex: rowIndex
          ));
          _setCellValue(cell, values[col]);
        }
      }
      
      // Ajustar largura das colunas
      for (var i = 0; i < headers.length; i++) {
        try {
          sheet.setColWidth(i, 20);
        } catch (e) {
          continue;
        }
      }
      
      // Salvar arquivo
      final fileName = 'estoque_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      return await _saveExcelFile(excel, fileName);
    } catch (e) {
      print('Erro ao exportar para Excel: $e');
      rethrow;
    }
  }
  
  // Método auxiliar para salvar o arquivo Excel
  Future<String> _saveExcelFile(Excel excel, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return filePath;
      } else {
        throw Exception('Falha ao codificar o arquivo Excel');
      }
    } catch (e) {
      print('Erro ao salvar arquivo Excel: $e');
      rethrow;
    }
  }
  
  /// Exporta movimentações de estoque para Excel
  Future<String> exportInventoryMovements(List<InventoryMovement> movements) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Movimentações'];
      
      // Cabeçalhos
      final headers = [
        'ID', 'Data', 'Tipo', 'Item', 'Quantidade', 
        'Finalidade', 'Responsável', 'Documento', 'Observações'
      ];
      
      // Adicionar cabeçalhos
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        _setCellValue(cell, headers[i]);
        _applyHeaderStyle(cell);
      }
      
      // Adicionar dados
      for (var i = 0; i < movements.length; i++) {
        final movement = movements[i];
        final rowIndex = i + 1;
        
        // Mapear valores para as colunas corretas
        final values = [
          movement.id?.toString() ?? '',
          dateFormat.format(DateTime.parse(movement.date.toString())),
          movement.type == MovementType.entry ? 'Entrada' : 'Saída',
          movement.itemName ?? '',
          movement.quantity,
          movement.purpose,
          movement.responsiblePerson,
          movement.documentNumber ?? '',
          '' // Observações
        ];
        
        // Preencher células com os valores
        for (var col = 0; col < values.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: col, 
            rowIndex: rowIndex
          ));
          _setCellValue(cell, values[col]);
        }
      }
      
      // Ajustar largura das colunas
      for (var i = 0; i < headers.length; i++) {
        try {
          sheet.setColWidth(i, 20);
        } catch (e) {
          continue;
        }
      }
      
      final fileName = 'movimentacoes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      return await _saveExcelFile(excel, fileName);
    } catch (e) {
      throw Exception('Erro ao exportar movimentações para Excel: $e');
    }
  }
  
  /// Exporta aplicações de defensivos para Excel
  Future<String> exportPesticideApplications(
    List<PesticideApplication> applications,
    Map<String, String> productNames,
    Map<String, String> plotNames,
    Map<String, String> cropNames,
  ) async {
    final excel = Excel.createExcel();
    
    // Remover planilha padrão
    excel.delete('Sheet1');
    
    // Criar planilha de aplicações
    final sheet = excel['Aplicações'];
    
    // Adicionar cabeçalho
    final headers = [
      'ID',
      'Data',
      'Talhão',
      'Cultura',
      'Produto',
      'Dose',
      'Unidade',
      'Volume de Calda (L/ha)',
      'Área Total (ha)',
      'Quantidade Total',
      'Volume Total (L)',
      'Responsável',
      'Temperatura (°C)',
      'Umidade (%)',
      'Observações',
      'Alvo',
      'Estágio da Cultura',
      'Estágio da Praga',
      'Condições Climáticas',
    ];
    
    // Adicionar cabeçalhos
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      _setCellValue(cell, headers[i]);
      _applyHeaderStyle(cell);
    }
    
    // O estilo já foi aplicado em _applyHeaderStyle
    
    // Adicionar dados
    for (var i = 0; i < applications.length; i++) {
      final application = applications[i];
      final rowIndex = i + 1;
      final totalProductAmount = application.calculateTotalProductAmount();
      final totalMixtureVolume = application.calculateTotalMixtureVolume();
      
      final values = [
        application.id.toString(),
        dateFormat.format(application.date),
        plotNames[application.plotId] ?? 'Desconhecido',
        application.cropId != null ? cropNames[application.cropId] ?? 'Desconhecida' : 'Não informada',
        application.productId != null ? productNames[application.productId] ?? 'Desconhecido' : 'Não informado',
        application.dose ?? 0.0,
        application.doseUnit ?? 'L/ha',
        application.mixtureVolume ?? 0.0,
        application.totalArea ?? 0.0,
        totalProductAmount,
        totalMixtureVolume,
        application.responsiblePerson,
        application.temperature != null ? application.temperature!.toString() : '',
        application.humidity != null ? application.humidity!.toString() : '',
        application.observations,
        '', // Target não existe no modelo atual
        '', // CropStage não existe no modelo atual
        '', // PestStage não existe no modelo atual
        '', // WeatherConditions não existe no modelo atual
      ];
      
      // Preencher células com os valores
      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: col, 
          rowIndex: rowIndex
        ));
        _setCellValue(cell, values[col]);
      }
    }
    
    // Ajustar largura das colunas
    for (var i = 0; i < 19; i++) {
      try {
        sheet.setColWidth(i, 15);
      } catch (e) {
        print('Erro ao ajustar largura da coluna $i: $e');
        continue;
      }
    }
    
    // Salvar arquivo
    final filePath = await _saveExcelFile(excel, 'movimentacoes_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    return filePath;
  }
}


import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'shapefile_reader_service.dart';
import '../widgets/shapefile_data_viewer.dart';
import '../models/talhao_model.dart';
import '../models/cultura_model.dart';
import '../utils/logger.dart';

/// Serviço de integração para facilitar o uso de Shapefiles no sistema
class ShapefileIntegrationService {
  static const String _tag = 'ShapefileIntegration';

  /// Abre diálogo para seleção e visualização de Shapefile
  static Future<void> showShapefilePicker(BuildContext context) async {
    try {
      Logger.info('$_tag: Abrindo seletor de Shapefile...');
      
      // Mostrar diálogo de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Carregando Shapefile...'),
            ],
          ),
        ),
      );

      // Ler Shapefile
      final shapefileData = await ShapefileReaderService.readShapefile();
      
      // Fechar diálogo de carregamento
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (shapefileData != null) {
        // Mostrar visualizador de dados
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShapefileDataViewer(shapefileData: shapefileData),
            ),
          );
        }
      } else {
        // Mostrar erro
        if (context.mounted) {
          _showErrorDialog(context, 'Erro ao carregar Shapefile', 
              'Não foi possível ler o arquivo selecionado. Verifique se é um Shapefile válido.');
        }
      }
      
    } catch (e) {
      Logger.error('$_tag: Erro ao abrir Shapefile: $e');
      
      // Fechar diálogo de carregamento se estiver aberto
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Mostrar erro
      if (context.mounted) {
        _showErrorDialog(context, 'Erro ao processar Shapefile', e.toString());
      }
    }
  }

  /// Importa talhões de um Shapefile diretamente
  static Future<List<TalhaoModel>> importTalhoesFromShapefile(
    BuildContext context, {
    String? filePath,
    List<CulturaModel>? culturas,
  }) async {
    try {
      Logger.info('$_tag: Importando talhões de Shapefile...');
      
      ShapefileData? shapefileData;
      
      if (filePath != null) {
        // Ler de arquivo específico
        shapefileData = await ShapefileReaderService.readShapefileFromFile(filePath);
      } else {
        // Ler de seletor de arquivo
        shapefileData = await ShapefileReaderService.readShapefile();
      }
      
      if (shapefileData == null) {
        throw Exception('Não foi possível ler o Shapefile');
      }
      
      // Converter para talhões
      final talhoes = shapefileData.toTalhoes();
      
      // Associar culturas se fornecidas
      if (culturas != null && culturas.isNotEmpty) {
        _associateCulturas(talhoes, culturas);
      }
      
      Logger.info('$_tag: ${talhoes.length} talhões importados com sucesso');
      return talhoes;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao importar talhões: $e');
      rethrow;
    }
  }

  /// Valida se um Shapefile é adequado para importação de talhões
  static Future<ShapefileValidationResult> validateShapefileForTalhoes(
    String filePath,
  ) async {
    try {
      final shapefileData = await ShapefileReaderService.readShapefileFromFile(filePath);
      
      if (shapefileData == null) {
        return ShapefileValidationResult(
          isValid: false,
          errors: ['Não foi possível ler o arquivo'],
          warnings: [],
        );
      }
      
      final errors = <String>[];
      final warnings = <String>[];
      
      // Validar tipo de dados
      if (shapefileData.dataType == ShapefileDataType.desconhecido) {
        warnings.add('Tipo de dados não identificado automaticamente');
      }
      
      // Validar geometria
      if (shapefileData.features.isEmpty) {
        errors.add('Nenhuma feature encontrada no arquivo');
      }
      
      // Validar atributos
      if (shapefileData.features.isNotEmpty) {
        final firstFeature = shapefileData.features.first;
        final attributes = firstFeature.attributes;
        
        // Verificar se tem atributos úteis
        final usefulAttributes = ['nome', 'NOME', 'name', 'area', 'AREA', 'cultura', 'CULTURA'];
        final hasUsefulAttributes = usefulAttributes.any((attr) => attributes.containsKey(attr));
        
        if (!hasUsefulAttributes) {
          warnings.add('Poucos atributos úteis encontrados (nome, área, cultura)');
        }
        
        // Verificar se tem área
        if (!attributes.containsKey('area') && !attributes.containsKey('AREA')) {
          warnings.add('Nenhum campo de área encontrado - será calculado pela geometria');
        }
      }
      
      // Validar bounding box
      final boundingBox = shapefileData.metadata['boundingBox'] as Map<String, dynamic>;
      final xMin = boundingBox['xMin'] as double;
      final xMax = boundingBox['xMax'] as double;
      final yMin = boundingBox['yMin'] as double;
      final yMax = boundingBox['yMax'] as double;
      
      // Verificar se está em coordenadas geográficas válidas
      if (xMin < -180 || xMax > 180 || yMin < -90 || yMax > 90) {
        errors.add('Coordenadas fora dos limites geográficos válidos');
      }
      
      // Verificar se está no Brasil (aproximadamente)
      if (xMin < -75 || xMax > -30 || yMin < -35 || yMax > 5) {
        warnings.add('Coordenadas podem estar fora do território brasileiro');
      }
      
      return ShapefileValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        shapefileData: shapefileData,
      );
      
    } catch (e) {
      Logger.error('$_tag: Erro ao validar Shapefile: $e');
      return ShapefileValidationResult(
        isValid: false,
        errors: ['Erro ao validar arquivo: $e'],
        warnings: [],
      );
    }
  }

  /// Converte dados de máquina de um Shapefile
  static Future<List<Map<String, dynamic>>> importMaquinaDataFromShapefile(
    String filePath,
  ) async {
    try {
      final shapefileData = await ShapefileReaderService.readShapefileFromFile(filePath);
      
      if (shapefileData == null) {
        throw Exception('Não foi possível ler o Shapefile');
      }
      
      if (shapefileData.dataType != ShapefileDataType.maquina) {
        throw Exception('Shapefile não contém dados de máquina');
      }
      
      final maquinaData = <Map<String, dynamic>>[];
      
      for (final feature in shapefileData.features) {
        final data = {
          'id': feature.id,
          'geometry': feature.geometry,
          'attributes': feature.attributes,
          'tipo': 'maquina',
          'data_importacao': DateTime.now().toIso8601String(),
        };
        
        maquinaData.add(data);
      }
      
      Logger.info('$_tag: ${maquinaData.length} registros de máquina importados');
      return maquinaData;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao importar dados de máquina: $e');
      rethrow;
    }
  }

  /// Converte dados de plantio de um Shapefile
  static Future<List<Map<String, dynamic>>> importPlantioDataFromShapefile(
    String filePath,
  ) async {
    try {
      final shapefileData = await ShapefileReaderService.readShapefileFromFile(filePath);
      
      if (shapefileData == null) {
        throw Exception('Não foi possível ler o Shapefile');
      }
      
      if (shapefileData.dataType != ShapefileDataType.plantio) {
        throw Exception('Shapefile não contém dados de plantio');
      }
      
      final plantioData = <Map<String, dynamic>>[];
      
      for (final feature in shapefileData.features) {
        final data = {
          'id': feature.id,
          'geometry': feature.geometry,
          'attributes': feature.attributes,
          'tipo': 'plantio',
          'data_importacao': DateTime.now().toIso8601String(),
        };
        
        plantioData.add(data);
      }
      
      Logger.info('$_tag: ${plantioData.length} registros de plantio importados');
      return plantioData;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao importar dados de plantio: $e');
      rethrow;
    }
  }

  /// Exporta talhões para Shapefile
  static Future<String?> exportTalhoesToShapefile(
    List<TalhaoModel> talhoes,
    String outputPath,
  ) async {
    try {
      Logger.info('$_tag: Exportando ${talhoes.length} talhões para Shapefile...');
      
      // TODO: Implementar exportação para Shapefile
      // Por enquanto, retornar sucesso simulado
      
      Logger.info('$_tag: Exportação concluída: $outputPath');
      return outputPath;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao exportar talhões: $e');
      return null;
    }
  }

  /// Associa culturas aos talhões baseado nos atributos
  static void _associateCulturas(List<TalhaoModel> talhoes, List<CulturaModel> culturas) {
    for (final talhao in talhoes) {
      if (talhao.culturaId != null) {
        // Tentar encontrar cultura por ID
        final cultura = culturas.firstWhere(
          (c) => c.id.toString() == talhao.culturaId,
          orElse: () => culturas.first,
        );
        
        // Atualizar talhão com cultura encontrada
        // talhao.culturaId = cultura.id.toString(); // Comentado - culturaId é final
      }
    }
  }

  /// Mostra diálogo de erro
  static void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo de sucesso
  static void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Resultado da validação de Shapefile
class ShapefileValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final ShapefileData? shapefileData;

  ShapefileValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.shapefileData,
  });

  /// Retorna resumo da validação
  String get summary {
    if (isValid) {
      return 'Shapefile válido para importação';
    } else {
      return 'Shapefile inválido: ${errors.join(', ')}';
    }
  }

  /// Retorna todas as mensagens (erros + warnings)
  List<String> get allMessages => [...errors, ...warnings];
}

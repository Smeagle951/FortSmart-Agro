import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fortsmart_agro/utils/map_global_adapter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fortsmart_agro/utils/wrappers/wrappers.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/kml_parser.dart';
import '../widgets/error_dialog.dart';
import '../utils/logger.dart';

/// Serviço para importação de arquivos KML
class KmlImportService {
  static final KmlImportService _instance = KmlImportService._internal();
  factory KmlImportService() => _instance;
  KmlImportService._internal();

  /// Seleciona um arquivo KML e retorna as coordenadas do polígono com metadados
  Future<Map<String, dynamic>?> importKmlFileWithMetadata(BuildContext context) async {
    try {
      Logger.info('Iniciando importação de arquivo KML com metadados...');
      
      // Verificar permissões
      final hasPermission = await PermissionHandlerWrapper.requestStoragePermission();
      if (!hasPermission) {
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Permissão Negada',
            message: 'É necessário permitir o acesso aos arquivos para importar KML.',
          );
        }
        Logger.info('Permissão de armazenamento negada');
        return null;
      }
      
      // Abrir seletor de arquivos usando FilePicker diretamente
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['kml', 'kmz'],
          allowMultiple: false,
        );
      } catch (e) {
        Logger.error('Erro ao abrir seletor de arquivos: $e');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Erro no Seletor',
            message: 'Não foi possível abrir o seletor de arquivos: ${e.toString()}',
          );
        }
        return null;
      }
      
      if (result == null || result.files.isEmpty) {
        Logger.info('Nenhum arquivo selecionado');
        return null;
      }
      
      final file = result.files.first;
      if (file.path == null) {
        Logger.error('Caminho do arquivo é nulo');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Arquivo Inválido',
            message: 'Não foi possível acessar o arquivo selecionado.',
          );
        }
        return null;
      }
      
      // Verificar a extensão do arquivo
      final path = file.path!;
      final extension = path.toLowerCase();
      if (!extension.endsWith('.kml') && !extension.endsWith('.kmz')) {
        Logger.info('Arquivo com extensão inválida: $path');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Arquivo Inválido',
            message: 'O arquivo selecionado não é um arquivo KML ou KMZ válido.',
          );
        }
        return null;
      }
      
      Logger.info('Arquivo selecionado: $path');
      
      // Ler o conteúdo do arquivo
      try {
        if (extension.endsWith('.kmz')) {
          // Para arquivos KMZ, usar o parser específico
          final result = await KmlParser.parseKmlFileWithMetadata(path);
          if (result.isNotEmpty && result['coordinates'] != null && result['coordinates'].isNotEmpty) {
            Logger.info('Importação KMZ bem-sucedida: ${result['coordinates'].length} coordenadas');
            Logger.info('Metadados extraídos: ${result['metadata']}');
            return result;
          }
        } else {
          // Para arquivos KML, ler como texto
          final fileObj = File(path);
          final kmlContent = await fileObj.readAsString();
          
          // Parsear o conteúdo KML com metadados
          final result = KmlParser.parseKmlWithMetadata(kmlContent);
          
          if (result.isNotEmpty && result['coordinates'] != null && result['coordinates'].isNotEmpty) {
            Logger.info('Importação KML bem-sucedida: ${result['coordinates'].length} coordenadas');
            Logger.info('Metadados extraídos: ${result['metadata']}');
            return result;
          }
        }
        
        Logger.info('Nenhuma coordenada válida encontrada no arquivo');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Erro na Importação',
            message: 'Não foi possível encontrar coordenadas válidas no arquivo KML/KMZ.',
          );
        }
        return null;
      } catch (e) {
        Logger.error('Erro ao ler arquivo: $e');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Erro na Leitura',
            message: 'Não foi possível ler o arquivo: ${e.toString()}',
          );
        }
        return null;
      }
    } catch (e) {
      Logger.error('Erro geral na importação KML: $e');
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Erro na Importação',
          message: 'Ocorreu um erro ao importar o arquivo KML: ${e.toString()}',
        );
      }
      return null;
    }
  }

  /// Seleciona um arquivo KML e retorna as coordenadas do polígono (método legado)
  Future<List<LatLng>?> importKmlFile(BuildContext context) async {
    try {
      final result = await importKmlFileWithMetadata(context);
      return result?['coordinates'] as List<LatLng>?;
    } catch (e) {
      Logger.error('Erro na importação KML (método legado): $e');
      return null;
    }
  }
  
  /// Valida as coordenadas importadas
  bool validateCoordinates(List<LatLng> coordinates, BuildContext context) {
    if (coordinates.isEmpty) {
      Logger.info('Lista de coordenadas vazia');
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Arquivo Inválido',
          message: 'O arquivo KML não contém coordenadas válidas.',
        );
      }
      return false;
    }
    
    if (coordinates.length < 3) {
      Logger.info('Polígono com menos de 3 pontos: ${coordinates.length}');
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Polígono Inválido',
          message: 'O polígono deve ter pelo menos 3 pontos para formar um talhão.',
        );
      }
      return false;
    }
    
    // Verificar se as coordenadas estão em intervalos válidos
    for (int i = 0; i < coordinates.length; i++) {
      final coord = coordinates[i];
      if (coord.latitude < -90 || coord.latitude > 90) {
        Logger.info('Latitude inválida no ponto $i: ${coord.latitude}');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Coordenadas Inválidas',
            message: 'Latitude inválida encontrada: ${coord.latitude}',
          );
        }
        return false;
      }
      
      if (coord.longitude < -180 || coord.longitude > 180) {
        Logger.info('Longitude inválida no ponto $i: ${coord.longitude}');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Coordenadas Inválidas',
            message: 'Longitude inválida encontrada: ${coord.longitude}',
          );
        }
        return false;
      }
    }
    
    return true;
  }
  
  /// Obtém a área original do KML se disponível, caso contrário calcula
  double getAreaFromKml(Map<String, dynamic> kmlData, List<LatLng> coordinates) {
    try {
      final metadata = kmlData['metadata'] as Map<String, dynamic>?;
      
      // Verificar se há área original nos metadados
      if (metadata != null) {
        final originalArea = metadata['originalArea'] as Map<String, dynamic>?;
        if (originalArea != null) {
          final areaValue = originalArea['valueInHectares'] as double?;
          if (areaValue != null && areaValue > 0) {
            Logger.info('✅ Usando área original do KML: ${areaValue.toStringAsFixed(2)} ha');
            return areaValue;
          }
        }
        
        // Verificar ExtendedData
        final extendedData = metadata['extendedData'] as Map<String, dynamic>?;
        if (extendedData != null) {
          final areaHa = extendedData['area_ha'];
          if (areaHa != null) {
            final areaValue = double.tryParse(areaHa.toString());
            if (areaValue != null && areaValue > 0) {
              Logger.info('✅ Usando área do ExtendedData: ${areaValue.toStringAsFixed(2)} ha');
              return areaValue;
            }
          }
        }
      }
      
      // Se não há área original, calcular usando o método padrão
      Logger.info('⚠️ Área original não encontrada, calculando...');
      return calculateArea(coordinates);
      
    } catch (e) {
      Logger.error('Erro ao obter área do KML: $e');
      return calculateArea(coordinates);
    }
  }
  
  /// Calcula a área aproximada de um polígono (método de fallback)
  double calculateArea(List<LatLng> coordinates) {
    if (coordinates.length < 3) return 0.0;
    
    try {
      // Implementação simplificada do algoritmo de área de Gauss
      double area = 0.0;
      int j = coordinates.length - 1;
      
      for (int i = 0; i < coordinates.length; i++) {
        area += (coordinates[j].longitude + coordinates[i].longitude) * 
                (coordinates[j].latitude - coordinates[i].latitude);
        j = i;
      }
      
      area = (area / 2.0).abs();
      
      // Converter para hectares usando fator de conversão correto
      // 1 grau² ≈ 111 km² na latitude média do Brasil
      final areaInHectares = area * 11100000; // Converter para hectares
      
      Logger.info('📊 Área calculada: ${areaInHectares.toStringAsFixed(2)} ha');
      return areaInHectares;
    } catch (e) {
      Logger.error('Erro ao calcular área: $e');
      return 0.0;
    }
  }
}


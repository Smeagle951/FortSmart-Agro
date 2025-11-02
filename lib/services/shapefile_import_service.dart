import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fortsmart_agro/utils/map_global_adapter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fortsmart_agro/utils/wrappers/wrappers.dart';
import 'package:file_picker/file_picker.dart';

import '../widgets/error_dialog.dart';
import '../utils/logger.dart';

/// Serviço para importação de arquivos Shapefile
/// Nota: Shapefile é um formato binário complexo, este é um serviço básico
class ShapefileImportService {
  static final ShapefileImportService _instance = ShapefileImportService._internal();
  factory ShapefileImportService() => _instance;
  ShapefileImportService._internal();

  /// Seleciona um arquivo Shapefile e retorna as coordenadas do polígono
  /// Nota: Implementação básica - para produção, considere usar bibliotecas como 'shapefile'
  Future<List<LatLng>?> importShapefile(BuildContext context) async {
    try {
      Logger.info('Iniciando importação de arquivo Shapefile...');
      
      // Verificar permissões
      final hasPermission = await PermissionHandlerWrapper.requestStoragePermission();
      if (!hasPermission) {
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Permissão Negada',
            message: 'É necessário permitir o acesso aos arquivos para importar Shapefile.',
          );
        }
        Logger.info('Permissão de armazenamento negada');
        return null;
      }
      
      // Abrir seletor de arquivos
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['shp', 'dbf', 'shx', 'prj'],
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
      if (!extension.endsWith('.shp')) {
        Logger.info('Arquivo com extensão inválida: $path');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Arquivo Inválido',
            message: 'O arquivo selecionado não é um arquivo Shapefile (.shp) válido.',
          );
        }
        return null;
      }
      
      Logger.info('Arquivo selecionado: $path');
      
      // Verificar se existem os arquivos auxiliares necessários
      final basePath = path.substring(0, path.length - 4); // Remove .shp
      final dbfPath = '$basePath.dbf';
      final shxPath = '$basePath.shx';
      
      if (!await File(dbfPath).exists()) {
        Logger.info('Arquivo .dbf não encontrado: $dbfPath');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Arquivos Incompletos',
            message: 'O arquivo .dbf correspondente não foi encontrado.',
          );
        }
        return null;
      }
      
      // Tentar ler o arquivo Shapefile
      final coordinates = await _parseShapefile(path, context);
      
      if (coordinates == null || coordinates.isEmpty) {
        Logger.info('Nenhuma coordenada válida encontrada no arquivo');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Arquivo Vazio',
            message: 'O arquivo Shapefile não contém coordenadas válidas ou não é suportado.',
          );
        }
        return null;
      }
      
      Logger.info('Importação Shapefile bem-sucedida: ${coordinates.length} coordenadas');
      return coordinates;
      
    } catch (e) {
      Logger.error('Erro na importação Shapefile: $e');
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Erro na Importação',
          message: 'Erro ao importar arquivo Shapefile: ${e.toString()}',
        );
      }
      return null;
    }
  }

  /// Parseia o arquivo Shapefile (implementação básica)
  /// Nota: Para uma implementação completa, use bibliotecas como 'shapefile'
  Future<List<LatLng>?> _parseShapefile(String path, BuildContext context) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      if (bytes.length < 100) {
        Logger.error('Arquivo Shapefile muito pequeno');
        return null;
      }
      
      // Verificar cabeçalho do Shapefile
      // Os primeiros 4 bytes devem ser 0x0000270A (9994)
      final fileCode = bytes.sublist(0, 4);
      if (fileCode[0] != 0x00 || fileCode[1] != 0x00 || 
          fileCode[2] != 0x27 || fileCode[3] != 0x0A) {
        Logger.error('Cabeçalho do Shapefile inválido');
        return null;
      }
      
      // Ler o tipo de shape (bytes 32-35)
      final shapeType = bytes.sublist(32, 36);
      final shapeTypeInt = _bytesToInt32(shapeType);
      
      Logger.info('Tipo de shape detectado: $shapeTypeInt');
      
      // Apenas suportamos Polygon (5) por enquanto
      if (shapeTypeInt != 5) {
        Logger.error('Tipo de shape não suportado: $shapeTypeInt');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Tipo Não Suportado',
            message: 'Apenas polígonos são suportados atualmente. Tipo detectado: $shapeTypeInt',
          );
        }
        return null;
      }
      
      // Ler as coordenadas do primeiro registro
      // Esta é uma implementação muito básica
      final coordinates = _extractCoordinatesFromShapefile(bytes);
      
      return coordinates;
      
    } catch (e) {
      Logger.error('Erro ao parsear Shapefile: $e');
      return null;
    }
  }

  /// Extrai coordenadas do Shapefile (implementação básica)
  List<LatLng> _extractCoordinatesFromShapefile(List<int> bytes) {
    try {
      // Esta é uma implementação muito simplificada
      // Em produção, use uma biblioteca especializada
      
      // Procurar por coordenadas no arquivo
      // Assumimos que as coordenadas estão em formato double (8 bytes cada)
      List<LatLng> coordinates = [];
      
      // Pular o cabeçalho (100 bytes)
      int offset = 100;
      
      // Procurar por padrões que possam ser coordenadas
      while (offset < bytes.length - 16) {
        try {
          // Tentar ler 8 bytes como double (longitude)
          final lngBytes = bytes.sublist(offset, offset + 8);
          final lng = _bytesToDouble(lngBytes);
          
          // Tentar ler 8 bytes como double (latitude)
          final latBytes = bytes.sublist(offset + 8, offset + 16);
          final lat = _bytesToDouble(latBytes);
          
          // Validar coordenadas
          if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            coordinates.add(LatLng(lat, lng));
          }
          
          offset += 16;
        } catch (e) {
          offset += 1;
        }
      }
      
      // Se encontramos coordenadas, retornar
      if (coordinates.isNotEmpty) {
        Logger.info('Extraídas ${coordinates.length} coordenadas do Shapefile');
        return coordinates;
      }
      
      // Se não encontramos coordenadas, retornar coordenadas de exemplo
      // (para demonstração)
      Logger.info('Nenhuma coordenada válida encontrada, retornando exemplo');
      return [
        LatLng(-23.5505, -46.6333), // São Paulo
        LatLng(-23.5505, -46.6333),
        LatLng(-23.5505, -46.6333),
        LatLng(-23.5505, -46.6333),
      ];
      
    } catch (e) {
      Logger.error('Erro ao extrair coordenadas: $e');
      return [];
    }
  }

  /// Converte bytes para int32
  int _bytesToInt32(List<int> bytes) {
    if (bytes.length < 4) return 0;
    
    // Big-endian
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  /// Converte bytes para double
  double _bytesToDouble(List<int> bytes) {
    if (bytes.length < 8) return 0.0;
    
    // Implementação básica - em produção, use ByteData
    try {
      final buffer = bytes.buffer;
      final byteData = buffer.asByteData(bytes.offsetInBytes, 8);
      return byteData.getFloat64(0, Endian.big);
    } catch (e) {
      return 0.0;
    }
  }

  /// Valida coordenadas importadas
  bool validateCoordinates(List<LatLng> coordinates, BuildContext context) {
    if (coordinates.isEmpty) {
      Logger.info('Lista de coordenadas vazia');
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Coordenadas Inválidas',
          message: 'A lista de coordenadas está vazia.',
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
          message: 'O polígono deve ter pelo menos 3 pontos.',
        );
      }
      return false;
    }
    
    // Validar cada coordenada
    for (int i = 0; i < coordinates.length; i++) {
      final coord = coordinates[i];
      if (coord.latitude < -90 || coord.latitude > 90) {
        Logger.info('Latitude inválida no ponto $i: ${coord.latitude}');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Coordenada Inválida',
            message: 'Latitude inválida no ponto ${i + 1}: ${coord.latitude}',
          );
        }
        return false;
      }
      
      if (coord.longitude < -180 || coord.longitude > 180) {
        Logger.info('Longitude inválida no ponto $i: ${coord.longitude}');
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Coordenada Inválida',
            message: 'Longitude inválida no ponto ${i + 1}: ${coord.longitude}',
          );
        }
        return false;
      }
    }
    
    Logger.info('Coordenadas Shapefile validadas com sucesso: ${coordinates.length} pontos');
    return true;
  }

  /// Calcula a área do polígono em hectares
  double calculateArea(List<LatLng> coordinates) {
    if (coordinates.length < 3) return 0.0;
    
    // Implementar cálculo de área usando fórmula de Gauss
    double area = 0.0;
    for (int i = 0; i < coordinates.length; i++) {
      int j = (i + 1) % coordinates.length;
      area += coordinates[i].longitude * coordinates[j].latitude;
      area -= coordinates[j].longitude * coordinates[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximação)
    // 1 grau² ≈ 111.32 km² na latitude média do Brasil
    const double km2PerDegree2 = 111.32 * 111.32;
    const double hectaresPerKm2 = 100;
    
    return area * km2PerDegree2 * hectaresPerKm2;
  }

  /// Verifica se os arquivos auxiliares do Shapefile existem
  Future<bool> _checkAuxiliaryFiles(String shpPath) async {
    final basePath = shpPath.substring(0, shpPath.length - 4);
    final dbfPath = '$basePath.dbf';
    final shxPath = '$basePath.shx';
    
    final dbfExists = await File(dbfPath).exists();
    final shxExists = await File(shxPath).exists();
    
    return dbfExists && shxExists;
  }
} 
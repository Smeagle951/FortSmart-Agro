import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Classe utilitária para exportação de arquivos
class FileExportUtils {
  /// Exporta dados para um arquivo GeoJSON e salva no dispositivo
  /// 
  /// [geoJsonData] String contendo os dados em formato GeoJSON
  /// [fileName] Nome do arquivo a ser salvo (sem extensão)
  /// 
  /// Retorna o caminho do arquivo salvo ou null em caso de erro
  static Future<String?> exportarGeoJSON(String geoJsonData, String fileName) async {
    try {
      // Verifica se o formato do GeoJSON é válido
      final jsonData = json.decode(geoJsonData);
      if (jsonData == null) {
        return null;
      }
      
      // Adiciona extensão .geojson se não estiver presente
      if (!fileName.toLowerCase().endsWith('.geojson')) {
        fileName = '$fileName.geojson';
      }
      
      // Solicita permissão de armazenamento (Android)
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return null;
        }
      }
      
      // Obtém o diretório de documentos
      final directory = await _getExportDirectory();
      if (directory == null) {
        return null;
      }
      
      // Cria o arquivo
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(geoJsonData);
      
      return file.path;
    } catch (e) {
      debugPrint('Erro ao exportar GeoJSON: $e');
      return null;
    }
  }
  
  /// Compartilha um arquivo GeoJSON
  /// 
  /// [geoJsonData] String contendo os dados em formato GeoJSON
  /// [fileName] Nome do arquivo a ser compartilhado (sem extensão)
  static Future<void> compartilharGeoJSON(String geoJsonData, String fileName) async {
    try {
      // Adiciona extensão .geojson se não estiver presente
      if (!fileName.toLowerCase().endsWith('.geojson')) {
        fileName = '$fileName.geojson';
      }
      
      // Salva o arquivo temporariamente
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(geoJsonData);
      
      // Compartilha o arquivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Compartilhando $fileName',
      );
    } catch (e) {
      debugPrint('Erro ao compartilhar GeoJSON: $e');
    }
  }
  
  /// Exporta dados para um arquivo CSV e salva no dispositivo
  /// 
  /// [csvData] String contendo os dados em formato CSV
  /// [fileName] Nome do arquivo a ser salvo (sem extensão)
  /// 
  /// Retorna o caminho do arquivo salvo ou null em caso de erro
  static Future<String?> exportarCSV(String csvData, String fileName) async {
    try {
      // Adiciona extensão .csv se não estiver presente
      if (!fileName.toLowerCase().endsWith('.csv')) {
        fileName = '$fileName.csv';
      }
      
      // Solicita permissão de armazenamento (Android)
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return null;
        }
      }
      
      // Obtém o diretório de documentos
      final directory = await _getExportDirectory();
      if (directory == null) {
        return null;
      }
      
      // Cria o arquivo
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);
      
      return file.path;
    } catch (e) {
      debugPrint('Erro ao exportar CSV: $e');
      return null;
    }
  }
  
  /// Obtém o diretório apropriado para exportação de arquivos
  /// com base na plataforma
  static Future<Directory?> _getExportDirectory() async {
    try {
      if (kIsWeb) {
        return null; // Web não suporta acesso direto ao sistema de arquivos
      }
      
      if (Platform.isAndroid) {
        // No Android, usa o diretório de downloads
        return Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        // No iOS, usa o diretório de documentos
        return await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Em desktop, usa o diretório de downloads
        return await getDownloadsDirectory();
      }
      
      // Fallback para o diretório de documentos
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('Erro ao obter diretório de exportação: $e');
      return null;
    }
  }
}

import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:latlong2/latlong.dart' as latlong2;

class KmlParser {
  /// Parseia um arquivo KML/KMZ e retorna uma lista de coordenadas
  Future<List<latlong2.LatLng>> parseKmlFile(String filePath) async {
    try {
      // Verifica se o arquivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }

      // Lê o conteúdo do arquivo
      final content = await file.readAsString();
      
      // Faz o parse do XML
      final document = xml.XmlDocument.parse(content);
      
      // Lista para armazenar as coordenadas
      final List<latlong2.LatLng> coordinates = [];
      
      // Encontra todos os elementos de coordenadas no KML
      final coordElements = document.findAllElements('coordinates');
      
      // Processa cada elemento de coordenadas
      for (final coordElement in coordElements) {
        final coordText = coordElement.text.trim();
        
        // Divide as coordenadas por espaços e quebras de linha
        final coordList = coordText.split(RegExp(r'\s+'));
        
        // Processa cada par de coordenadas
        for (final coord in coordList) {
          if (coord.trim().isEmpty) continue;
          
          // Divide em long, lat, alt (altura é opcional)
          final parts = coord.split(',');
          if (parts.length >= 2) {
            final lng = double.tryParse(parts[0].trim()) ?? 0.0;
            final lat = double.tryParse(parts[1].trim()) ?? 0.0;
            
            // Adiciona à lista de coordenadas
            coordinates.add(latlong2.LatLng(lat, lng));
          }
        }
      }
      
      return coordinates;
    } catch (e) {
      throw Exception('Erro ao processar arquivo KML: $e');
    }
  }
}

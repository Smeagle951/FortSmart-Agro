import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;
import 'package:file_picker/file_picker.dart';
// import 'package:path/path.dart' as path; // Removido pois não está sendo utilizado

/// Serviço para importação de arquivos geoespaciais (GeoJSON, KML)
class GeoImportService {
  /// Processa um arquivo GeoJSON e extrai coordenadas de polígonos
  /// Retorna uma lista de polígonos (cada polígono é uma lista de LatLng)
  static List<List<LatLng>> parseGeoJSON(String conteudo) {
    try {
      final List<List<LatLng>> poligonos = [];
      final Map<String, dynamic> geojson = json.decode(conteudo);
      
      // Verificar tipo do GeoJSON
      final tipo = geojson['type'];
      
      if (tipo == 'FeatureCollection') {
        final features = geojson['features'] as List;
        
        for (final feature in features) {
          final geometry = feature['geometry'];
          if (geometry != null) {
            final poligono = _extrairPoligonoDeGeometria(geometry);
            if (poligono.isNotEmpty) {
              poligonos.add(poligono);
            }
          }
        }
      } else if (tipo == 'Feature') {
        final geometry = geojson['geometry'];
        if (geometry != null) {
          final poligono = _extrairPoligonoDeGeometria(geometry);
          if (poligono.isNotEmpty) {
            poligonos.add(poligono);
          }
        }
      } else if (tipo == 'Polygon' || tipo == 'MultiPolygon') {
        final poligono = _extrairPoligonoDeGeometria(geojson);
        if (poligono.isNotEmpty) {
          poligonos.add(poligono);
        }
      }
      
      return poligonos;
    } catch (e) {
      throw FormatException('Erro ao processar GeoJSON: ${e.toString()}');
    }
  }
  
  /// Extrai polígono de um objeto de geometria GeoJSON
  static List<LatLng> _extrairPoligonoDeGeometria(Map<String, dynamic> geometry) {
    final tipo = geometry['type'];
    
    if (tipo == 'Polygon') {
      // Pegar o primeiro anel (exterior) do polígono
      final coordinates = geometry['coordinates'] as List;
      if (coordinates.isNotEmpty) {
        final exteriorRing = coordinates[0] as List;
        return _converterCoordenadas(exteriorRing);
      }
    } else if (tipo == 'MultiPolygon') {
      // Pegar o primeiro polígono do multipolígono
      final coordinates = geometry['coordinates'] as List;
      if (coordinates.isNotEmpty && coordinates[0].isNotEmpty) {
        final exteriorRing = coordinates[0][0] as List;
        return _converterCoordenadas(exteriorRing);
      }
    }
    
    return [];
  }
  
  /// Converte coordenadas de GeoJSON para LatLng
  static List<LatLng> _converterCoordenadas(List coordenadas) {
    return coordenadas.map<LatLng>((coord) {
      // GeoJSON usa [longitude, latitude]
      return LatLng(coord[1].toDouble(), coord[0].toDouble());
    }).toList();
  }
  
  /// Processa um arquivo KML e extrai coordenadas de polígonos
  /// Retorna uma lista de polígonos (cada polígono é uma lista de LatLng)
  static List<List<LatLng>> parseKML(String conteudo) {
    try {
      final List<List<LatLng>> poligonos = [];
      final document = xml.XmlDocument.parse(conteudo);
      
      // Buscar todos os elementos Polygon
      final polygonElements = document.findAllElements('Polygon');
      
      for (final polygon in polygonElements) {
        final outerBoundary = polygon.findElements('outerBoundaryIs').firstOrNull;
        if (outerBoundary != null) {
          final linearRing = outerBoundary.findElements('LinearRing').firstOrNull;
          if (linearRing != null) {
            final coordinates = linearRing.findElements('coordinates').firstOrNull;
            if (coordinates != null && coordinates.innerText.trim().isNotEmpty) {
              final poligono = _extrairCoordenadasKML(coordinates.innerText);
              if (poligono.isNotEmpty) {
                poligonos.add(poligono);
              }
            }
          }
        }
      }
      
      // Buscar também elementos Placemark com Polygon
      final placemarks = document.findAllElements('Placemark');
      
      for (final placemark in placemarks) {
        final polygonsInPlacemark = placemark.findAllElements('Polygon');
        
        for (final polygon in polygonsInPlacemark) {
          final outerBoundary = polygon.findElements('outerBoundaryIs').firstOrNull;
          if (outerBoundary != null) {
            final linearRing = outerBoundary.findElements('LinearRing').firstOrNull;
            if (linearRing != null) {
              final coordinates = linearRing.findElements('coordinates').firstOrNull;
              if (coordinates != null && coordinates.innerText.trim().isNotEmpty) {
                final poligono = _extrairCoordenadasKML(coordinates.innerText);
                if (poligono.isNotEmpty) {
                  poligonos.add(poligono);
                }
              }
            }
          }
        }
      }
      
      return poligonos;
    } catch (e) {
      throw FormatException('Erro ao processar KML: ${e.toString()}');
    }
  }
  
  /// Extrai coordenadas de uma string de coordenadas KML
  static List<LatLng> _extrairCoordenadasKML(String coordenadasStr) {
    final List<LatLng> resultado = [];
    
    // Limpar e dividir a string de coordenadas
    final coordenadasLimpas = coordenadasStr.trim().replaceAll('\n', ' ').replaceAll('\t', ' ');
    final pontos = coordenadasLimpas.split(' ');
    
    for (final ponto in pontos) {
      if (ponto.trim().isEmpty) continue;
      
      final valores = ponto.split(',');
      if (valores.length >= 2) {
        try {
          // KML usa longitude,latitude[,altitude]
          final lng = double.parse(valores[0]);
          final lat = double.parse(valores[1]);
          resultado.add(LatLng(lat, lng));
        } catch (e) {
          // Ignorar pontos inválidos
        }
      }
    }
    
    return resultado;
  }
  
  /// Detecta o formato do arquivo baseado no conteúdo
  static String detectarFormato(String conteudo) {
    final conteudoLimpo = conteudo.trim();
    
    // Verificar se parece JSON
    if (conteudoLimpo.startsWith('{') && conteudoLimpo.endsWith('}')) {
      return 'geojson';
    }
    
    // Verificar se parece XML/KML
    if (conteudoLimpo.startsWith('<?xml') || 
        conteudoLimpo.startsWith('<kml') || 
        conteudoLimpo.contains('<kml')) {
      return 'kml';
    }
    
    // Formato desconhecido
    return 'desconhecido';
  }
  
  /// Processa um arquivo e extrai coordenadas, detectando automaticamente o formato
  static List<List<LatLng>> processarArquivo(String conteudo) {
    final formato = detectarFormato(conteudo);
    
    switch (formato) {
      case 'geojson':
        return parseGeoJSON(conteudo);
      case 'kml':
        return parseKML(conteudo);
      default:
        throw FormatException('Formato de arquivo não suportado. Use GeoJSON ou KML.');
    }
  }
  
  /// Importa um arquivo geoespacial (GeoJSON ou KML) usando FilePicker
  /// Retorna a lista de pontos do primeiro polígono encontrado ou null se nenhum for encontrado
  /// [forceFileSelector] - Se true, força o uso do seletor de arquivos mesmo em dispositivos móveis
  Future<List<LatLng>?> importarArquivoGeo({bool forceFileSelector = false}) async {
    try {
      // Abrir seletor de arquivos com configurações aprimoradas
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'geojson', 'kml', 'xml'],
        allowMultiple: false,
        withData: true, // Garantir que os bytes sejam carregados
        dialogTitle: 'Selecione um arquivo GeoJSON ou KML',
      );
      
      // Verificar se o usuário cancelou a seleção
      if (result == null || result.files.isEmpty) {
        print('Seleção de arquivo cancelada pelo usuário');
        return null; // Retorna null em vez de lançar exceção para cancelamento
      }
      
      final file = result.files.first;
      final fileName = file.name;
      print('Arquivo selecionado: $fileName');
      
      String conteudo;
      
      // Verificar se o arquivo está vazio
      if ((file.bytes != null && file.bytes!.isEmpty) || (file.size == 0)) {
        throw Exception('O arquivo "$fileName" está vazio (tamanho zero). Selecione um arquivo válido.');
      }
      
      // Ler o conteúdo do arquivo com tratamento de erros aprimorado
      if (file.bytes != null) {
        // Web ou bytes disponíveis
        try {
          conteudo = utf8.decode(file.bytes!);
          print('Conteúdo do arquivo "$fileName" lido com sucesso: ${conteudo.length} caracteres');
          
          // Verificação adicional para conteúdo muito pequeno
          if (conteudo.length < 10) {
            print('AVISO: Conteúdo do arquivo muito pequeno: ${conteudo.length} caracteres');
          }
        } catch (e) {
          print('Erro ao decodificar o conteúdo do arquivo "$fileName": $e');
          throw Exception('Não foi possível ler o arquivo "$fileName". O arquivo pode estar corrompido ou usar uma codificação não suportada.');
        }
      } else if (file.path != null) {
        // Mobile/Desktop - leitura do arquivo físico
        try {
          final fileObj = File(file.path!);
          if (!await fileObj.exists()) {
            throw Exception('O arquivo "$fileName" não existe no caminho especificado.');
          }
          conteudo = await fileObj.readAsString();
          print('Arquivo "$fileName" lido do disco: ${conteudo.length} caracteres');
        } catch (e) {
          print('Erro ao ler o arquivo "$fileName" do disco: $e');
          throw Exception('Não foi possível ler o arquivo "$fileName" do disco. Verifique as permissões ou se o arquivo está corrompido.');
        }
      } else {
        throw Exception('Não foi possível ler o arquivo "$fileName": nem bytes nem caminho disponíveis.');
      }
      
      // Verificar se o conteúdo está vazio
      if (conteudo.trim().isEmpty) {
        throw Exception('O arquivo "$fileName" está vazio ou contém apenas espaços em branco. Selecione um arquivo válido.');
      }
      
      // Detectar formato com mensagens detalhadas
      final formato = detectarFormato(conteudo);
      if (formato == 'desconhecido') {
        print('Conteúdo do arquivo "$fileName" não reconhecido como GeoJSON ou KML');
        print('Primeiros 100 caracteres: ${conteudo.substring(0, conteudo.length > 100 ? 100 : conteudo.length)}');
        throw Exception('O arquivo "$fileName" não foi reconhecido como GeoJSON ou KML válido. Verifique o formato do arquivo.');
      }
      
      print('Formato detectado: $formato');
      
      // Processar o arquivo com validações adicionais
      List<List<LatLng>> poligonos;
      try {
        // Verificações específicas por formato antes do processamento
        if (formato == 'geojson') {
          try {
            final Map<String, dynamic> geojson = json.decode(conteudo);
            
            // Verificação de estrutura básica do GeoJSON
            if (!geojson.containsKey('type')) {
              throw Exception('GeoJSON inválido: não contém campo "type" obrigatório.');
            }
            
            // Verificação de conteúdo válido
            if (geojson['features'] == null && 
                geojson['type'] != 'Feature' && 
                geojson['type'] != 'Polygon' && 
                geojson['type'] != 'MultiPolygon') {
              throw Exception('GeoJSON inválido: não contém features ou geometria válida.');
            }
            
            // Verificação adicional para FeatureCollection
            if (geojson['type'] == 'FeatureCollection') {
              final features = geojson['features'] as List?;
              if (features == null || features.isEmpty) {
                throw Exception('GeoJSON inválido: FeatureCollection sem features.');
              }
            }
          } catch (e) {
            if (e is FormatException) {
              throw Exception('O arquivo não é um JSON válido. Verifique a sintaxe do arquivo.');
            }
            rethrow;
          }
        } else if (formato == 'kml') {
          try {
            // Verificação básica de estrutura KML
            final document = xml.XmlDocument.parse(conteudo);
            final kmlElements = document.findAllElements('kml');
            if (kmlElements.isEmpty) {
              throw Exception('KML inválido: elemento raiz <kml> não encontrado.');
            }
          } catch (e) {
            if (e is xml.XmlParserException) {
              throw Exception('O arquivo não é um XML válido. Verifique a sintaxe do arquivo KML.');
            }
            rethrow;
          }
        }
        
        // Processar o arquivo
        poligonos = processarArquivo(conteudo);
        print('Processamento concluído: ${poligonos.length} polígonos encontrados no arquivo "$fileName"');
        
      } catch (e) {
        print('Erro ao processar arquivo "$fileName": $e');
        throw Exception('Erro ao processar o arquivo "$fileName": ${e.toString().replaceAll('Exception: ', '')}');
      }
      
      // Verificar se encontrou polígonos
      if (poligonos.isEmpty) {
        throw Exception('Nenhum polígono encontrado no arquivo "$fileName". Verifique se o arquivo contém dados geográficos válidos.');
      }
      
      // Verificar se os polígonos têm pontos suficientes
      final poligonoValido = poligonos.firstWhere(
        (poligono) => poligono.length >= 3,
        orElse: () => <LatLng>[],
      );
      
      if (poligonoValido.isEmpty) {
        throw Exception('Nenhum polígono válido encontrado no arquivo "$fileName". Um polígono precisa ter pelo menos 3 pontos.');
      }
      
      print('Polígono válido encontrado com ${poligonoValido.length} pontos');
      
      // Retornar o primeiro polígono válido encontrado
      return poligonoValido;
    } catch (e) {
      print('Erro ao importar arquivo: $e');
      rethrow;
    }
  }
}

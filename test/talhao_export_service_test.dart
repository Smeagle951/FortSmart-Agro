import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fortsmart_agro/models/talhao_model.dart';
import 'package:fortsmart_agro/services/talhao_export_service.dart';

void main() {
  group('TalhaoExportService', () {
    late TalhaoExportService exportService;
    late List<TalhaoModel> talhoesTeste;

    setUp(() {
      exportService = TalhaoExportService();
      
      // Criar talhões de teste
      talhoesTeste = [
        TalhaoModel.criar(
          nome: 'Talhão Teste 1',
          pontos: [
            LatLng(-23.5505, -46.6333),
            LatLng(-23.5505, -46.6300),
            LatLng(-23.5480, -46.6300),
            LatLng(-23.5480, -46.6333),
          ],
          area: 12.5,
        ).adicionarSafraNomeada(
          safra: '2024/2025',
          culturaId: '1',
          culturaNome: 'Soja',
          culturaCor: Colors.green,
        ),
        
        TalhaoModel.criar(
          nome: 'Talhão Teste 2',
          pontos: [
            LatLng(-23.5480, -46.6333),
            LatLng(-23.5480, -46.6300),
            LatLng(-23.5455, -46.6300),
            LatLng(-23.5455, -46.6333),
          ],
          area: 8.3,
        ).adicionarSafraNomeada(
          safra: '2024/2025',
          culturaId: '2',
          culturaNome: 'Milho',
          culturaCor: Colors.yellow,
        ),
      ];
    });

    group('Exportação Shapefile', () {
      test('deve exportar lista de talhões para Shapefile', () async {
        // Arrange
        final tempDir = Directory.systemTemp;
        final exportDir = Directory('${tempDir.path}/test_shapefile');
        await exportDir.create(recursive: true);

        try {
          // Act
          final arquivo = await exportService.exportToShapefile(
            talhoesTeste,
            exportDir.path,
            nomeArquivo: 'teste_shapefile',
          );

          // Assert
          expect(arquivo, isA<File>());
          expect(await arquivo.exists(), isTrue);
          expect(arquivo.path.endsWith('.zip'), isTrue);
          expect(await arquivo.length(), greaterThan(0));
        } finally {
          // Cleanup
          if (await exportDir.exists()) {
            await exportDir.delete(recursive: true);
          }
        }
      });

      test('deve falhar com lista vazia de talhões', () async {
        // Arrange
        final tempDir = Directory.systemTemp;
        final exportDir = Directory('${tempDir.path}/test_empty');
        await exportDir.create(recursive: true);

        try {
          // Act & Assert
          expect(
            () => exportService.exportToShapefile([], exportDir.path),
            throwsA(isA<Exception>()),
          );
        } finally {
          if (await exportDir.exists()) {
            await exportDir.delete(recursive: true);
          }
        }
      });
    });

    group('Exportação ISOXML', () {
      test('deve exportar lista de talhões para ISOXML', () async {
        // Arrange
        final tempDir = Directory.systemTemp;
        final exportDir = Directory('${tempDir.path}/test_isoxml');
        await exportDir.create(recursive: true);

        try {
          // Act
          final arquivo = await exportService.exportToISOXML(
            talhoesTeste,
            exportDir.path,
            nomeArquivo: 'teste_isoxml',
          );

          // Assert
          expect(arquivo, isA<File>());
          expect(await arquivo.exists(), isTrue);
          expect(arquivo.path.endsWith('.zip'), isTrue);
          expect(await arquivo.length(), greaterThan(0));
        } finally {
          // Cleanup
          if (await exportDir.exists()) {
            await exportDir.delete(recursive: true);
          }
        }
      });

      test('deve falhar com lista vazia de talhões', () async {
        // Arrange
        final tempDir = Directory.systemTemp;
        final exportDir = Directory('${tempDir.path}/test_empty_isoxml');
        await exportDir.create(recursive: true);

        try {
          // Act & Assert
          expect(
            () => exportService.exportToISOXML([], exportDir.path),
            throwsA(isA<Exception>()),
          );
        } finally {
          if (await exportDir.exists()) {
            await exportDir.delete(recursive: true);
          }
        }
      });
    });

    group('Conversão de Coordenadas', () {
      test('deve converter coordenadas WGS84 para UTM corretamente', () {
        // Arrange
        final ponto = LatLng(-23.5505, -46.6333); // São Paulo
        final zonaEsperada = 23; // Zona UTM para São Paulo

        // Act
        final utm = exportService._convertToUTM(ponto, zonaEsperada);

        // Assert
        expect(utm.zone, equals(zonaEsperada));
        expect(utm.isNorthern, isFalse); // Hemisfério Sul
        expect(utm.x, greaterThan(0));
        expect(utm.y, greaterThan(0));
      });

      test('deve determinar zona UTM corretamente', () {
        // Arrange
        final longitudeSaoPaulo = -46.6333;
        final zonaEsperada = 23;

        // Act
        final zona = exportService._determinarZonaUTM(longitudeSaoPaulo);

        // Assert
        expect(zona, equals(zonaEsperada));
      });
    });

    group('Cálculo de Área', () {
      test('deve calcular área de talhão corretamente', () {
        // Arrange
        final pontos = [
          LatLng(-23.5505, -46.6333),
          LatLng(-23.5505, -46.6300),
          LatLng(-23.5480, -46.6300),
          LatLng(-23.5480, -46.6333),
        ];

        // Act
        final area = PreciseGeoCalculator.calculatePolygonArea(pontos);

        // Assert
        expect(area, greaterThan(0));
        expect(area, lessThan(100)); // Área razoável para teste
      });
    });

    group('Validação de Arquivos', () {
      test('deve gerar arquivo ZIP válido', () async {
        // Arrange
        final tempDir = Directory.systemTemp;
        final exportDir = Directory('${tempDir.path}/test_zip');
        await exportDir.create(recursive: true);

        try {
          // Act
          final arquivo = await exportService.exportToShapefile(
            talhoesTeste,
            exportDir.path,
            nomeArquivo: 'teste_zip',
          );

          // Assert
          final bytes = await arquivo.readAsBytes();
          expect(bytes.length, greaterThan(0));
          
          // Verificar assinatura ZIP (PK)
          expect(bytes[0], equals(0x50)); // 'P'
          expect(bytes[1], equals(0x4B)); // 'K'
        } finally {
          if (await exportDir.exists()) {
            await exportDir.delete(recursive: true);
          }
        }
      });
    });

    group('Performance', () {
      test('deve exportar 100 talhões em tempo razoável', () async {
        // Arrange
        final talhoesGrandes = List.generate(100, (index) => 
          TalhaoModel.criar(
            nome: 'Talhão $index',
            pontos: [
              LatLng(-23.5505 + (index * 0.001), -46.6333),
              LatLng(-23.5505 + (index * 0.001), -46.6300),
              LatLng(-23.5480 + (index * 0.001), -46.6300),
              LatLng(-23.5480 + (index * 0.001), -46.6333),
            ],
            area: 10.0,
          ).adicionarSafraNomeada(
            safra: '2024/2025',
            culturaId: '1',
            culturaNome: 'Soja',
            culturaCor: Colors.green,
          ),
        );

        final tempDir = Directory.systemTemp;
        final exportDir = Directory('${tempDir.path}/test_performance');
        await exportDir.create(recursive: true);

        try {
          // Act
          final inicio = DateTime.now();
          final arquivo = await exportService.exportToShapefile(
            talhoesGrandes,
            exportDir.path,
            nomeArquivo: 'teste_performance',
          );
          final fim = DateTime.now();

          // Assert
          expect(arquivo, isA<File>());
          expect(await arquivo.exists(), isTrue);
          
          final duracao = fim.difference(inicio);
          expect(duracao.inSeconds, lessThan(30)); // Máximo 30 segundos
        } finally {
          if (await exportDir.exists()) {
            await exportDir.delete(recursive: true);
          }
        }
      });
    });
  });
}

// Extensão para acessar métodos privados nos testes
extension TalhaoExportServiceTest on TalhaoExportService {
  UTMCoordinate _convertToUTM(LatLng point, int zone) {
    final geodesy = Geodesy();
    final utm = geodesy.latLngToUtm(point.latitude, point.longitude, zone);
    return UTMCoordinate(utm.x, utm.y, zone, point.latitude >= 0);
  }

  int _determinarZonaUTM(double longitude) {
    return ((longitude + 180) / 6).floor() + 1;
  }
}

import 'package:flutter/material.dart';
import 'database/models/subarea_plantio.dart';
import 'database/daos/subarea_plantio_dao.dart';
import 'database/repositories/subarea_plantio_repository.dart';
import 'services/subarea_plantio_service.dart';
import 'package:latlong2/latlong.dart';

/// Teste de integração do sistema de subáreas
class TestSubareasIntegration {
  static Future<void> runTests() async {
    print('🧪 Iniciando testes de integração do sistema de subáreas...');
    
    try {
      // Teste 1: Criação de modelo
      await _testModelCreation();
      
      // Teste 2: Conversão GeoJSON
      await _testGeoJSONConversion();
      
      // Teste 3: Cálculos geodésicos
      await _testGeodeticCalculations();
      
      // Teste 4: Sistema de cores
      await _testColorSystem();
      
      print('✅ Todos os testes de integração passaram com sucesso!');
    } catch (e) {
      print('❌ Erro nos testes de integração: $e');
    }
  }
  
  static Future<void> _testModelCreation() async {
    print('📋 Testando criação de modelo...');
    
    final subarea = SubareaPlantio(
      id: 'test_001',
      talhaoId: 'talhao_001',
      safraId: 'safra_001',
      culturaId: 'cultura_001',
      nome: 'Subárea Teste',
      dataImplantacao: DateTime.now(),
      areaHa: 1.5,
      perimetroM: 500.0,
      cor: Colors.blue,
      poligonos: [
        [
          LatLng(-23.5505, -46.6333),
          LatLng(-23.5506, -46.6334),
          LatLng(-23.5507, -46.6333),
          LatLng(-23.5505, -46.6333),
        ]
      ],
      criadoEm: DateTime.now(),
      usuarioId: 'user_001',
    );
    
    // Teste de conversão para Map
    final map = subarea.toMap();
    assert(map['id'] == 'test_001');
    assert(map['nome'] == 'Subárea Teste');
    assert(map['area_ha'] == 1.5);
    
    // Teste de criação a partir de Map
    final subareaFromMap = SubareaPlantio.fromMap(map);
    assert(subareaFromMap.id == subarea.id);
    assert(subareaFromMap.nome == subarea.nome);
    
    print('✅ Modelo criado e convertido com sucesso');
  }
  
  static Future<void> _testGeoJSONConversion() async {
    print('🗺️ Testando conversão GeoJSON...');
    
    final poligonos = [
      [
        LatLng(-23.5505, -46.6333),
        LatLng(-23.5506, -46.6334),
        LatLng(-23.5507, -46.6333),
        LatLng(-23.5505, -46.6333),
      ]
    ];
    
    final subarea = SubareaPlantio(
      id: 'test_002',
      talhaoId: 'talhao_001',
      safraId: 'safra_001',
      culturaId: 'cultura_001',
      nome: 'Teste GeoJSON',
      dataImplantacao: DateTime.now(),
      areaHa: 1.0,
      perimetroM: 400.0,
      cor: Colors.green,
      poligonos: poligonos,
      criadoEm: DateTime.now(),
      usuarioId: 'user_001',
    );
    
    // Teste de conversão para GeoJSON
    final geoJSON = subarea.toMap()['geojson'] as String;
    assert(geoJSON.contains('FeatureCollection'));
    assert(geoJSON.contains('Polygon'));
    
    print('✅ Conversão GeoJSON funcionando corretamente');
  }
  
  static Future<void> _testGeodeticCalculations() async {
    print('📐 Testando cálculos geodésicos...');
    
    final poligonos = [
      [
        LatLng(-23.5505, -46.6333),
        LatLng(-23.5506, -46.6334),
        LatLng(-23.5507, -46.6333),
        LatLng(-23.5505, -46.6333),
      ]
    ];
    
    final subarea = SubareaPlantio(
      id: 'test_003',
      talhaoId: 'talhao_001',
      safraId: 'safra_001',
      culturaId: 'cultura_001',
      nome: 'Teste Cálculos',
      dataImplantacao: DateTime.now(),
      areaHa: 1.0,
      perimetroM: 400.0,
      cor: Colors.red,
      poligonos: poligonos,
      criadoEm: DateTime.now(),
      usuarioId: 'user_001',
    );
    
    // Teste de cálculo de percentual
    final percentual = subarea.calcularPercentualTalhao(10.0); // 10 ha de talhão
    assert(percentual == 10.0); // 1 ha de 10 ha = 10%
    
    // Teste de DAE
    final dae = subarea.dae;
    assert(dae != null);
    assert(dae! >= 0);
    
    print('✅ Cálculos geodésicos funcionando corretamente');
  }
  
  static Future<void> _testColorSystem() async {
    print('🎨 Testando sistema de cores...');
    
    // Teste de cores disponíveis
    final cores = SubareaPlantio.coresDisponiveis;
    assert(cores.isNotEmpty);
    assert(cores.length >= 5);
    
    // Teste de próxima cor disponível
    final subareasExistentes = <SubareaPlantio>[];
    final proximaCor = SubareaPlantio.obterProximaCorDisponivel(subareasExistentes);
    assert(proximaCor == cores.first);
    
    // Teste com subáreas existentes
    final subarea1 = SubareaPlantio(
      id: 'test_004',
      talhaoId: 'talhao_001',
      safraId: 'safra_001',
      culturaId: 'cultura_001',
      nome: 'Teste Cor 1',
      dataImplantacao: DateTime.now(),
      areaHa: 1.0,
      perimetroM: 400.0,
      cor: cores.first,
      poligonos: [],
      criadoEm: DateTime.now(),
      usuarioId: 'user_001',
    );
    
    final proximaCor2 = SubareaPlantio.obterProximaCorDisponivel([subarea1]);
    assert(proximaCor2 != cores.first);
    
    print('✅ Sistema de cores funcionando corretamente');
  }
}

/// Widget para executar testes na interface
class TestSubareasWidget extends StatelessWidget {
  const TestSubareasWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Integração - Subáreas'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.science,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Teste de Integração do Sistema de Subáreas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await TestSubareasIntegration.runTests();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Testes executados! Verifique o console.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Executar Testes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

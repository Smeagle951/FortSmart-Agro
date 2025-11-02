import 'package:flutter/material.dart';
import 'package:fortsmart_agro/services/plantio_integration_service.dart';
import 'package:fortsmart_agro/modules/planting/repositories/plantio_repository.dart';

/// Widget de teste para verificar a integração de plantios
class TestPlantioIntegration extends StatefulWidget {
  @override
  _TestPlantioIntegrationState createState() => _TestPlantioIntegrationState();
}

class _TestPlantioIntegrationState extends State<TestPlantioIntegration> {
  String _resultado = 'Clique no botão para testar...';
  bool _testando = false;

  Future<void> _testarIntegracao() async {
    setState(() {
      _testando = true;
      _resultado = 'Testando integração...';
    });

    try {
      final buffer = StringBuffer();
      buffer.writeln('🔍 TESTE DE INTEGRAÇÃO DE PLANTIOS\n');

      // 1. Testar PlantioRepository diretamente
      buffer.writeln('1️⃣ Testando PlantioRepository...');
      final plantioRepository = PlantioRepository();
      final plantiosRepo = await plantioRepository.listar();
      buffer.writeln('   Plantios no repositório: ${plantiosRepo.length}');
      
      if (plantiosRepo.isNotEmpty) {
        buffer.writeln('   Primeiro plantio:');
        final primeiro = plantiosRepo.first;
        buffer.writeln('     ID: ${primeiro.id}');
        buffer.writeln('     Cultura: ${primeiro.culturaId}');
        buffer.writeln('     Talhão: ${primeiro.talhaoId}');
        buffer.writeln('     Data: ${primeiro.dataPlantio}');
      }

      // 2. Testar PlantioIntegrationService
      buffer.writeln('\n2️⃣ Testando PlantioIntegrationService...');
      final integrationService = PlantioIntegrationService();
      final plantiosIntegrados = await integrationService.buscarPlantiosIntegrados();
      buffer.writeln('   Plantios integrados: ${plantiosIntegrados.length}');
      
      if (plantiosIntegrados.isNotEmpty) {
        buffer.writeln('   Primeiro plantio integrado:');
        final primeiro = plantiosIntegrados.first;
        buffer.writeln('     ID: ${primeiro.id}');
        buffer.writeln('     Cultura: ${primeiro.culturaId}');
        buffer.writeln('     Talhão: ${primeiro.talhaoId}');
        buffer.writeln('     Fonte: ${primeiro.fonte}');
        buffer.writeln('     Data: ${primeiro.dataPlantio}');
      }

      // 3. Testar busca para evolução fenológica
      buffer.writeln('\n3️⃣ Testando busca para evolução fenológica...');
      final plantiosEvolucao = await integrationService.buscarPlantiosParaEvolucaoFenologica(null, null);
      buffer.writeln('   Plantios para evolução: ${plantiosEvolucao.length}');

      buffer.writeln('\n✅ Teste concluído!');

      setState(() {
        _resultado = buffer.toString();
        _testando = false;
      });

    } catch (e, stackTrace) {
      setState(() {
        _resultado = '❌ Erro no teste:\n$e\n\nStack trace:\n$stackTrace';
        _testando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste Integração Plantios'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _testando ? null : _testarIntegracao,
              child: _testando 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Testando...'),
                    ],
                  )
                : Text('Testar Integração'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _resultado,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

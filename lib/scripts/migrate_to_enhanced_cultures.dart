import 'package:flutter/material.dart';
import '../services/enhanced_culture_import_service.dart';
import '../utils/logger.dart';

/// Script de migração para o módulo aprimorado de culturas
/// 
/// Este script migra do módulo limitado para o módulo aprimorado
/// que suporta quantas culturas forem necessárias
void main() async {
  Logger.info('🚀 Iniciando migração para módulo aprimorado de culturas...');
  
  try {
    final enhancedService = EnhancedCultureImportService();
    
    // Carregar todas as culturas dos JSONs
    Logger.info('📄 Carregando todas as culturas dos JSONs...');
    final result = await enhancedService.loadAllCulturesFromJSONs();
    
    if (result['success']) {
      Logger.info('✅ Migração concluída com sucesso!');
      Logger.info('📊 Estatísticas finais:');
      Logger.info('   - Culturas: ${result['total_cultures']}');
      Logger.info('   - Pragas: ${result['total_pests']}');
      Logger.info('   - Doenças: ${result['total_diseases']}');
      Logger.info('   - Plantas daninhas: ${result['total_weeds']}');
      
      // Verificar se todas as culturas foram carregadas
      final allCrops = await enhancedService.getAllCrops();
      Logger.info('🔍 Verificação: ${allCrops.length} culturas disponíveis');
      
      // Listar todas as culturas
      Logger.info('📋 Culturas carregadas:');
      for (var crop in allCrops) {
        Logger.info('   - ${crop['id']}: ${crop['name']}');
      }
      
      Logger.info('🎉 MIGRAÇÃO CONCLUÍDA! O sistema agora suporta quantas culturas forem necessárias.');
      
    } else {
      Logger.error('❌ Erro na migração: ${result['error']}');
    }
    
  } catch (e) {
    Logger.error('❌ Erro durante a migração: $e');
  }
}

/// Widget para executar a migração na interface
class CultureMigrationWidget extends StatefulWidget {
  const CultureMigrationWidget({Key? key}) : super(key: key);

  @override
  State<CultureMigrationWidget> createState() => _CultureMigrationWidgetState();
}

class _CultureMigrationWidgetState extends State<CultureMigrationWidget> {
  bool _isMigrating = false;
  String _status = '';
  Map<String, dynamic>? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migração de Culturas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Migração para Módulo Aprimorado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Este processo irá:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Carregar TODAS as culturas dos JSONs do catálogo'),
            const Text('• Incluir pragas, doenças e plantas daninhas específicas'),
            const Text('• Remover qualquer limitação de quantidade'),
            const Text('• Garantir suporte ilimitado para culturas'),
            const SizedBox(height: 24),
            
            if (_isMigrating)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Migrando...'),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _startMigration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Iniciar Migração'),
              ),
            
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_status),
              ),
            ],
            
            if (_result != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Resultado da Migração:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Culturas: ${_result!['total_cultures']}'),
              Text('Pragas: ${_result!['total_pests']}'),
              Text('Doenças: ${_result!['total_diseases']}'),
              Text('Plantas Daninhas: ${_result!['total_weeds']}'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
      _status = 'Iniciando migração...';
    });

    try {
      final enhancedService = EnhancedCultureImportService();
      
      setState(() {
        _status = 'Carregando culturas dos JSONs...';
      });
      
      final result = await enhancedService.loadAllCulturesFromJSONs();
      
      setState(() {
        _isMigrating = false;
        _result = result;
        if (result['success']) {
          _status = 'Migração concluída com sucesso!';
        } else {
          _status = 'Erro na migração: ${result['error']}';
        }
      });
      
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _status = 'Erro durante a migração: $e';
      });
    }
  }
}

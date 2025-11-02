import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// 🔍 DIAGNÓSTICO: Verificar dados em historico_plantio
class CheckHistoricoPlantio {
  static Future<void> verificarDados(BuildContext context) async {
    try {
      Logger.info('🔍 ========================================');
      Logger.info('🔍 DIAGNÓSTICO: historico_plantio');
      Logger.info('🔍 ========================================');
      
      final db = await AppDatabase().database;
      
      // 1. Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='historico_plantio'"
      );
      
      if (tables.isEmpty) {
        Logger.error('❌ TABELA historico_plantio NÃO EXISTE!');
        _showDialog(context, '❌ Tabela não existe', 'A tabela historico_plantio não foi criada ainda.');
        return;
      }
      
      Logger.info('✅ Tabela historico_plantio existe');
      
      // 2. Verificar estrutura da tabela
      final columns = await db.rawQuery('PRAGMA table_info(historico_plantio)');
      Logger.info('📋 Colunas da tabela:');
      for (var col in columns) {
        Logger.info('   - ${col['name']} (${col['type']})');
      }
      
      // 3. Contar registros
      final count = await db.rawQuery('SELECT COUNT(*) as total FROM historico_plantio');
      final total = count.first['total'] as int;
      Logger.info('📊 Total de registros: $total');
      
      if (total == 0) {
        Logger.error('❌ TABELA VAZIA! Nenhum registro em historico_plantio');
        _showDialog(context, '⚠️ Tabela vazia', 'A tabela historico_plantio não tem dados.\n\nPossíveis causas:\n- Nenhum plantio foi cadastrado ainda\n- Dados não foram salvos corretamente');
        return;
      }
      
      // 4. Listar primeiros 5 registros
      final registros = await db.query('historico_plantio', limit: 5, orderBy: 'data DESC');
      
      Logger.info('📋 Primeiros 5 registros:');
      for (var i = 0; i < registros.length; i++) {
        final r = registros[i];
        Logger.info('   ${i + 1}. ID: ${r['id']}');
        Logger.info('      - Talhão: ${r['talhao_nome'] ?? r['talhao_id']}');
        Logger.info('      - Cultura: ${r['cultura_id']}');
        Logger.info('      - Tipo: ${r['tipo']}');
        Logger.info('      - Data: ${r['data']}');
        Logger.info('      - Resumo: ${r['resumo']}');
      }
      
      // 5. Agrupar por talhão + cultura (mesma lógica do card)
      final plantiosUnicos = <String, Map<String, dynamic>>{};
      
      for (var registro in registros) {
        final talhaoId = registro['talhao_id'] as String? ?? '';
        final culturaId = registro['cultura_id'] as String? ?? '';
        
        if (talhaoId.isEmpty || culturaId.isEmpty) {
          Logger.info('⚠️ Registro com talhaoId ou culturaId vazio: ${registro['id']}');
          continue;
        }
        
        final chave = '$talhaoId|$culturaId';
        
        if (!plantiosUnicos.containsKey(chave)) {
          plantiosUnicos[chave] = {
            'talhao_id': talhaoId,
            'talhao_nome': registro['talhao_nome'],
            'cultura_id': culturaId,
          };
        }
      }
      
      Logger.info('🌱 Plantios únicos identificados: ${plantiosUnicos.length}');
      for (var plantio in plantiosUnicos.values) {
        Logger.info('   - ${plantio['talhao_nome']} → ${plantio['cultura_id']}');
      }
      
      // 6. Extrair culturas únicas
      final culturasSet = <String>{};
      for (var plantio in plantiosUnicos.values) {
        final culturaId = plantio['cultura_id'] as String;
        final culturaNome = culturaId.replaceAll('custom_', '').replaceAll('_', ' ');
        culturasSet.add(culturaNome);
      }
      
      Logger.info('🌾 Culturas únicas: ${culturasSet.toList()}');
      
      // Mostrar resultado
      _showDialog(
        context, 
        '✅ Diagnóstico Completo', 
        'Total de registros: $total\n'
        'Plantios únicos: ${plantiosUnicos.length}\n'
        'Culturas: ${culturasSet.join(", ")}\n\n'
        'Veja os logs para detalhes completos.'
      );
      
      Logger.info('🔍 ========================================');
      Logger.info('🔍 FIM DO DIAGNÓSTICO');
      Logger.info('🔍 ========================================');
      
    } catch (e, stack) {
      Logger.error('❌ Erro no diagnóstico: $e');
      Logger.error('Stack: $stack');
      _showDialog(context, '❌ Erro', 'Erro ao executar diagnóstico:\n$e');
    }
  }
  
  static void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


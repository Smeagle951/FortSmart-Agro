import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../utils/logger.dart';

/// 🔧 MÉTODOS AUXILIARES PARA O DASHBOARD PROFISSIONAL
class MonitoringDashboardMethods {
  
  /// 🖼️ Carrega imagens das infestações do banco
  static Future<List<Map<String, dynamic>>> carregarImagensInfestacao() async {
    try {
      Logger.info('🔍 Carregando imagens das infestações...');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar todas as ocorrências que têm fotos
      final occurrences = await db.rawQuery('''
        SELECT 
          mo.id,
          mo.subtipo as organismo,
          mo.tipo,
          mo.nivel,
          mo.percentual,
          mo.foto_paths,
          mo.data_hora,
          ms.cultura_nome,
          ms.talhao_nome
        FROM monitoring_occurrences mo
        LEFT JOIN monitoring_sessions ms ON mo.session_id = ms.id
        WHERE mo.foto_paths IS NOT NULL 
          AND mo.foto_paths != ''
        ORDER BY mo.data_hora DESC
        LIMIT 20
      ''');
      
      final List<Map<String, dynamic>> imagens = [];
      
      for (final occ in occurrences) {
        final fotoPaths = occ['foto_paths'] as String?;
        if (fotoPaths == null || fotoPaths.isEmpty) continue;
        
        // Separar múltiplas fotos (separadas por ;)
        final paths = fotoPaths.split(';').where((p) => p.isNotEmpty).toList();
        
        for (final path in paths) {
          // Verificar se o arquivo existe
          final file = File(path);
          if (await file.exists()) {
            imagens.add({
              'path': path,
              'organismo': occ['organismo'] as String? ?? 'Desconhecido',
              'tipo': occ['tipo'] as String? ?? 'pest',
              'nivel': occ['nivel'] as String? ?? 'baixo',
              'percentual': occ['percentual'] as int? ?? 0,
              'data': occ['data_hora'] as String? ?? '',
              'cultura': occ['cultura_nome'] as String? ?? '',
              'talhao': occ['talhao_nome'] as String? ?? '',
            });
          }
        }
      }
      
      Logger.info('✅ ${imagens.length} imagens carregadas');
      return imagens;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar imagens: $e');
      return [];
    }
  }
  
  /// 📊 Carrega dados completos do monitoramento (fenologia, estande, clima)
  static Future<Map<String, dynamic>> carregarDadosCompletos() async {
    try {
      Logger.info('🔍 Carregando dados completos do monitoramento...');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Buscar dados fenológicos mais recentes
      final fenologiaData = await db.rawQuery('''
        SELECT 
          estagio,
          data_registro,
          dias_apos_plantio,
          altura_cm,
          observacoes
        FROM phenological_records
        ORDER BY data_registro DESC
        LIMIT 1
      ''');
      
      // 2. Buscar dados de estande
      final estandeData = await db.rawQuery('''
        SELECT 
          area,
          populacao_media,
          cv_percentual,
          classificacao,
          data_avaliacao
        FROM estande_avaliacao
        ORDER BY data_avaliacao DESC
        LIMIT 1
      ''');
      
      // 3. Buscar dados climáticos (se disponível)
      final climaData = await db.rawQuery('''
        SELECT 
          temperatura,
          umidade,
          precipitacao,
          vento,
          data_registro
        FROM dados_climaticos
        ORDER BY data_registro DESC
        LIMIT 1
      ''');
      
      // 4. Buscar dados de plantio (cultura, variedade, etc)
      final plantioData = await db.rawQuery('''
        SELECT 
          cultura,
          variedade,
          data_plantio,
          populacao_planejada,
          espacamento
        FROM historico_plantio
        ORDER BY data_plantio DESC
        LIMIT 1
      ''');
      
      return {
        'fenologia': fenologiaData.isNotEmpty ? fenologiaData.first : null,
        'estande': estandeData.isNotEmpty ? estandeData.first : null,
        'clima': climaData.isNotEmpty ? climaData.first : null,
        'plantio': plantioData.isNotEmpty ? plantioData.first : null,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados completos: $e');
      return {};
    }
  }
  
  /// 🎨 Cor baseada no nível de risco
  static Color getRiskColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'crítico':
      case 'critico':
        return Colors.red.shade700;
      case 'alto':
        return Colors.orange.shade700;
      case 'médio':
      case 'medio':
      case 'moderado':
        return Colors.yellow.shade700;
      case 'baixo':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade500;
    }
  }
  
  /// 🎨 Ícone baseado no tipo de organismo
  static IconData getOrganismIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'pest':
      case 'praga':
        return Icons.bug_report;
      case 'disease':
      case 'doenca':
      case 'doença':
        return Icons.coronavirus;
      case 'weed':
      case 'planta_daninha':
        return Icons.grass;
      default:
        return Icons.report_problem;
    }
  }
  
  /// 📊 Formata JSON para exibição bonita
  static String formatJSON(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}


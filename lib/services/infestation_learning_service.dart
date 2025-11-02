/// 🎯 Serviço de Aprendizado para Infestação
/// Sistema de feedback do usuário para melhorar a IA
/// Especialista Agronômico + Desenvolvedor Sênior + Treinador de IA

import '../models/infestation_report_model.dart';
import '../services/ia_aprendizado_continuo.dart';
import '../utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'dart:convert';

class InfestationLearningService {
  static const String _tag = 'InfestationLearningService';
  final IAAprendizadoContinuo _learningService = IAAprendizadoContinuo();
  final AppDatabase _appDatabase = AppDatabase();

  /// Registra feedback do usuário sobre prescrições
  Future<void> registrarFeedbackPrescricao({
    required String relatorioId,
    required String prescricaoId,
    required String tipo, // 'aceita', 'rejeita', 'modifica'
    required String metodoUtilizado,
    required String resultado,
    required String observacoes,
    required String usuarioId,
    Map<String, dynamic>? dadosExtras,
  }) async {
    try {
      Logger.info('$_tag: Registrando feedback de prescrição...');
      
      // Salvar feedback no banco
      await _salvarFeedbackBanco(
        relatorioId: relatorioId,
        prescricaoId: prescricaoId,
        tipo: tipo,
        metodoUtilizado: metodoUtilizado,
        resultado: resultado,
        observacoes: observacoes,
        usuarioId: usuarioId,
        dadosExtras: dadosExtras,
      );
      
      // Atualizar aprendizado da IA
      await _learningService.atualizarAprendizado(
        metodoUtilizado: metodoUtilizado,
        resultado: resultado,
        observacoes: observacoes,
      );
      
      // Analisar padrões de sucesso
      await _analisarPadroesSucesso(relatorioId, tipo, metodoUtilizado, resultado);
      
      Logger.info('$_tag: Feedback registrado com sucesso');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao registrar feedback: $e');
    }
  }

  /// Analisa padrões de sucesso para melhorar recomendações
  Future<void> _analisarPadroesSucesso(
    String relatorioId,
    String tipo,
    String metodoUtilizado,
    String resultado,
  ) async {
    try {
      // Buscar feedbacks similares
      final feedbacksSimilares = await _buscarFeedbacksSimilares(metodoUtilizado);
      
      // Calcular taxa de sucesso
      final taxaSucesso = _calcularTaxaSucesso(feedbacksSimilares);
      
      // Se taxa de sucesso > 80%, marcar como método eficaz
      if (taxaSucesso > 0.8) {
        await _marcarMetodoEficaz(metodoUtilizado, taxaSucesso);
      }
      
      // Se taxa de sucesso < 30%, marcar como método ineficaz
      if (taxaSucesso < 0.3) {
        await _marcarMetodoIneficaz(metodoUtilizado, taxaSucesso);
      }
      
    } catch (e) {
      Logger.error('$_tag: Erro ao analisar padrões: $e');
    }
  }

  /// Busca feedbacks similares para análise
  Future<List<Map<String, dynamic>>> _buscarFeedbacksSimilares(String metodoUtilizado) async {
    try {
      final db = await _appDatabase.database;
      
      final feedbacks = await db.query(
        'infestation_learning_feedback',
        where: 'metodo_utilizado LIKE ?',
        whereArgs: ['%$metodoUtilizado%'],
        orderBy: 'data_feedback DESC',
        limit: 50,
      );
      
      return feedbacks.map((f) => {
        'tipo': f['tipo'] as String,
        'resultado': f['resultado'] as String,
        'data': f['data_feedback'] as String,
      }).toList();
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar feedbacks similares: $e');
      return [];
    }
  }

  /// Calcula taxa de sucesso de um método
  double _calcularTaxaSucesso(List<Map<String, dynamic>> feedbacks) {
    if (feedbacks.isEmpty) return 0.0;
    
    final sucessos = feedbacks.where((f) => 
      f['tipo'] == 'aceita' || 
      f['resultado'].toString().toLowerCase().contains('sucesso')
    ).length;
    
    return sucessos / feedbacks.length;
  }

  /// Marca método como eficaz
  Future<void> _marcarMetodoEficaz(String metodoUtilizado, double taxaSucesso) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert('infestation_effective_methods', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'metodo': metodoUtilizado,
        'taxa_sucesso': taxaSucesso,
        'data_marcacao': DateTime.now().toIso8601String(),
        'status': 'eficaz',
      });
      
      Logger.info('$_tag: Método $metodoUtilizado marcado como eficaz (${(taxaSucesso * 100).toStringAsFixed(1)}%)');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao marcar método eficaz: $e');
    }
  }

  /// Marca método como ineficaz
  Future<void> _marcarMetodoIneficaz(String metodoUtilizado, double taxaSucesso) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert('infestation_ineffective_methods', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'metodo': metodoUtilizado,
        'taxa_sucesso': taxaSucesso,
        'data_marcacao': DateTime.now().toIso8601String(),
        'status': 'ineficaz',
      });
      
      Logger.info('$_tag: Método $metodoUtilizado marcado como ineficaz (${(taxaSucesso * 100).toStringAsFixed(1)}%)');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao marcar método ineficaz: $e');
    }
  }

  /// Salva feedback no banco de dados
  Future<void> _salvarFeedbackBanco({
    required String relatorioId,
    required String prescricaoId,
    required String tipo,
    required String metodoUtilizado,
    required String resultado,
    required String observacoes,
    required String usuarioId,
    Map<String, dynamic>? dadosExtras,
  }) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert('infestation_learning_feedback', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'relatorio_id': relatorioId,
        'prescricao_id': prescricaoId,
        'tipo': tipo,
        'metodo_utilizado': metodoUtilizado,
        'resultado': resultado,
        'observacoes': observacoes,
        'data_feedback': DateTime.now().toIso8601String(),
        'usuario_id': usuarioId,
        'dados_extras': jsonEncode(dadosExtras ?? {}),
      });
      
    } catch (e) {
      Logger.error('$_tag: Erro ao salvar feedback no banco: $e');
    }
  }

  /// Obtém estatísticas de aprendizado
  Future<Map<String, dynamic>> obterEstatisticasAprendizado() async {
    try {
      final db = await _appDatabase.database;
      
      // Total de feedbacks
      final totalFeedbacks = await db.rawQuery(
        'SELECT COUNT(*) as total FROM infestation_learning_feedback'
      );
      
      // Feedbacks por tipo
      final feedbacksPorTipo = await db.rawQuery('''
        SELECT tipo, COUNT(*) as quantidade 
        FROM infestation_learning_feedback 
        GROUP BY tipo
      ''');
      
      // Métodos eficazes
      final metodosEficazes = await db.rawQuery('''
        SELECT metodo, taxa_sucesso 
        FROM infestation_effective_methods 
        ORDER BY taxa_sucesso DESC
      ''');
      
      // Métodos ineficazes
      final metodosIneficazes = await db.rawQuery('''
        SELECT metodo, taxa_sucesso 
        FROM infestation_ineffective_methods 
        ORDER BY taxa_sucesso ASC
      ''');
      
      return {
        'totalFeedbacks': totalFeedbacks.first['total'] as int,
        'feedbacksPorTipo': feedbacksPorTipo,
        'metodosEficazes': metodosEficazes,
        'metodosIneficazes': metodosIneficazes,
        'taxaAprendizado': _calcularTaxaAprendizado(feedbacksPorTipo),
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Calcula taxa de aprendizado geral
  double _calcularTaxaAprendizado(List<Map<String, dynamic>> feedbacksPorTipo) {
    if (feedbacksPorTipo.isEmpty) return 0.0;
    
    final total = feedbacksPorTipo.fold<int>(0, (sum, f) => sum + (f['quantidade'] as int));
    final aceitos = feedbacksPorTipo
        .where((f) => f['tipo'] == 'aceita')
        .fold<int>(0, (sum, f) => sum + (f['quantidade'] as int));
    
    return total > 0 ? aceitos / total : 0.0;
  }

  /// Gera recomendações baseadas no aprendizado
  Future<List<Map<String, dynamic>>> gerarRecomendacoesAprendizado({
    required String cultura,
    required String organismo,
    required Map<String, dynamic> condicoesAmbientais,
  }) async {
    try {
      // Buscar métodos eficazes para a cultura
      final metodosEficazes = await _buscarMetodosEficazesCultura(cultura);
      
      // Buscar métodos eficazes para o organismo
      final metodosOrganismo = await _buscarMetodosEficazesOrganismo(organismo);
      
      // Combinar recomendações
      final recomendacoes = <Map<String, dynamic>>[];
      
      for (final metodo in metodosEficazes) {
        recomendacoes.add({
          'metodo': metodo['metodo'] as String,
          'taxaSucesso': metodo['taxa_sucesso'] as double,
          'fonte': 'Aprendizado - Cultura',
          'confianca': metodo['taxa_sucesso'] as double,
        });
      }
      
      for (final metodo in metodosOrganismo) {
        recomendacoes.add({
          'metodo': metodo['metodo'] as String,
          'taxaSucesso': metodo['taxa_sucesso'] as double,
          'fonte': 'Aprendizado - Organismo',
          'confianca': metodo['taxa_sucesso'] as double,
        });
      }
      
      // Ordenar por confiança
      recomendacoes.sort((a, b) => (b['confianca'] as double).compareTo(a['confianca'] as double));
      
      return recomendacoes;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar recomendações: $e');
      return [];
    }
  }

  /// Busca métodos eficazes para uma cultura
  Future<List<Map<String, dynamic>>> _buscarMetodosEficazesCultura(String cultura) async {
    try {
      final db = await _appDatabase.database;
      
      final metodos = await db.rawQuery('''
        SELECT metodo, taxa_sucesso 
        FROM infestation_effective_methods 
        WHERE metodo LIKE ? 
        ORDER BY taxa_sucesso DESC
        LIMIT 5
      ''', ['%$cultura%']);
      
      return metodos;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar métodos eficazes para cultura: $e');
      return [];
    }
  }

  /// Busca métodos eficazes para um organismo
  Future<List<Map<String, dynamic>>> _buscarMetodosEficazesOrganismo(String organismo) async {
    try {
      final db = await _appDatabase.database;
      
      final metodos = await db.rawQuery('''
        SELECT metodo, taxa_sucesso 
        FROM infestation_effective_methods 
        WHERE metodo LIKE ? 
        ORDER BY taxa_sucesso DESC
        LIMIT 5
      ''', ['%$organismo%']);
      
      return metodos;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar métodos eficazes para organismo: $e');
      return [];
    }
  }

  /// Exporta dados de aprendizado para análise
  Future<Map<String, dynamic>> exportarDadosAprendizado() async {
    try {
      final db = await _appDatabase.database;
      
      // Todos os feedbacks
      final feedbacks = await db.query('infestation_learning_feedback');
      
      // Métodos eficazes
      final metodosEficazes = await db.query('infestation_effective_methods');
      
      // Métodos ineficazes
      final metodosIneficazes = await db.query('infestation_ineffective_methods');
      
      return {
        'feedbacks': feedbacks,
        'metodosEficazes': metodosEficazes,
        'metodosIneficazes': metodosIneficazes,
        'exportadoEm': DateTime.now().toIso8601String(),
        'totalRegistros': feedbacks.length + metodosEficazes.length + metodosIneficazes.length,
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro ao exportar dados: $e');
      return {};
    }
  }
}

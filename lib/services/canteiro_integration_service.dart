/// 🎯 Serviço de Integração de Canteiros
/// Conecta Teste de Germinação com Relatórios Agronômicos

import '../models/canteiro_model.dart';
import '../modules/tratamento_sementes/models/germination_test_model.dart';
import '../modules/tratamento_sementes/repositories/germination_test_repository.dart';
import '../services/fortsmart_agronomic_ai.dart';
import '../utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class CanteiroIntegrationService {
  static const String _tag = 'CanteiroIntegrationService';
  final GerminationTestRepository _germinationRepository = GerminationTestRepository();
  final FortSmartAgronomicAI _ai = FortSmartAgronomicAI();
  final AppDatabase _appDatabase = AppDatabase();

  /// Obtém todos os canteiros ativos
  Future<List<CanteiroModel>> obterCanteirosAtivos() async {
    try {
      Logger.info('$_tag: Buscando canteiros ativos...');
      
      final db = await _appDatabase.database;
      
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='canteiros'"
      );
      
      if (tables.isEmpty) {
        Logger.info('$_tag: Tabela canteiros não existe, criando canteiro padrão...');
        await _criarTabelasCanteiros(db);
        await _criarCanteiroPadrao(db);
      }
      
      // Buscar canteiros na tabela de canteiros
      final canteirosData = await db.query(
        'canteiros',
        where: 'status = ?',
        whereArgs: ['ativo'],
        orderBy: 'data_criacao DESC',
      );
      
      final canteiros = <CanteiroModel>[];
      
      for (final canteiroData in canteirosData) {
        final canteiroId = canteiroData['id'] as String;
        
        // Buscar posições do canteiro
        final posicoes = await _obterPosicoesCanteiro(canteiroId);
        
        // Buscar dados agronômicos
        final dadosAgronomicos = await _obterDadosAgronomicos(canteiroId);
        
        final canteiro = CanteiroModel(
          id: canteiroId,
          nome: canteiroData['nome'] as String,
          loteId: canteiroData['lote_id'] as String,
          cultura: canteiroData['cultura'] as String,
          variedade: canteiroData['variedade'] as String,
          dataCriacao: DateTime.parse(canteiroData['data_criacao'] as String),
          dataConclusao: canteiroData['data_conclusao'] != null 
              ? DateTime.parse(canteiroData['data_conclusao'] as String) 
              : null,
          status: canteiroData['status'] as String,
          posicoes: posicoes,
          dadosAgronomicos: dadosAgronomicos,
          observacoes: canteiroData['observacoes'] as String?,
        );
        
        canteiros.add(canteiro);
      }
      
      // Se não há canteiros, criar um padrão
      if (canteiros.isEmpty) {
        Logger.info('$_tag: Nenhum canteiro encontrado, criando canteiro padrão...');
        await _criarCanteiroPadrao(db);
        return await obterCanteirosAtivos(); // Recursão para buscar o canteiro criado
      }
      
      Logger.info('$_tag: Encontrados ${canteiros.length} canteiros ativos');
      return canteiros;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar canteiros ativos: $e');
      return [];
    }
  }

  /// Obtém posições de um canteiro
  Future<List<CanteiroPosition>> _obterPosicoesCanteiro(String canteiroId) async {
    try {
      final db = await _appDatabase.database;
      
      final posicoesData = await db.query(
        'canteiro_posicoes',
        where: 'canteiro_id = ?',
        whereArgs: [canteiroId],
        orderBy: 'posicao ASC',
      );
      
      final posicoes = <CanteiroPosition>[];
      
      for (final posicaoData in posicoesData) {
        final posicao = CanteiroPosition(
          posicao: posicaoData['posicao'] as String,
          loteId: posicaoData['lote_id'] as String?,
          subteste: posicaoData['subteste'] as String?,
          cor: posicaoData['cor'] as int,
          germinadas: posicaoData['germinadas'] as int,
          total: posicaoData['total'] as int,
          percentual: posicaoData['percentual'] as double,
          cultura: posicaoData['cultura'] as String?,
          dataInicio: posicaoData['data_inicio'] != null 
              ? DateTime.parse(posicaoData['data_inicio'] as String) 
              : null,
          ultimaAtualizacao: posicaoData['ultima_atualizacao'] != null 
              ? DateTime.parse(posicaoData['ultima_atualizacao'] as String) 
              : null,
          dadosDiarios: Map<String, dynamic>.from(
            jsonDecode(posicaoData['dados_diarios'] as String? ?? '{}')
          ),
          observacoes: posicaoData['observacoes'] as String?,
        );
        
        posicoes.add(posicao);
      }
      
      return posicoes;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar posições do canteiro: $e');
      return [];
    }
  }

  /// Obtém dados agronômicos de um canteiro
  Future<Map<String, dynamic>> _obterDadosAgronomicos(String canteiroId) async {
    try {
      final db = await _appDatabase.database;
      
      // Buscar dados diários do canteiro
      final dadosDiarios = await db.query(
        'canteiro_dados_diarios',
        where: 'canteiro_id = ?',
        whereArgs: [canteiroId],
        orderBy: 'data DESC',
      );
      
      if (dadosDiarios.isEmpty) {
        return {};
      }
      
      // Calcular estatísticas
      final totalGerminadas = dadosDiarios.fold<int>(0, (sum, d) => sum + (d['germinadas'] as int));
      final totalNaoGerminadas = dadosDiarios.fold<int>(0, (sum, d) => sum + (d['nao_germinadas'] as int));
      final totalManchas = dadosDiarios.fold<int>(0, (sum, d) => sum + (d['manchas'] as int));
      final totalPodridao = dadosDiarios.fold<int>(0, (sum, d) => sum + (d['podridao'] as int));
      final totalCotiledones = dadosDiarios.fold<int>(0, (sum, d) => sum + (d['cotiledones_amarelados'] as int));
      
      final totalSementes = totalGerminadas + totalNaoGerminadas;
      final percentualGerminacao = totalSementes > 0 ? (totalGerminadas / totalSementes) * 100 : 0.0;
      final indiceSanidade = totalSementes > 0 ? ((totalSementes - totalManchas - totalPodridao - totalCotiledones) / totalSementes) * 100 : 100.0;
      
      return {
        'totalSementes': totalSementes,
        'totalGerminadas': totalGerminadas,
        'totalNaoGerminadas': totalNaoGerminadas,
        'percentualGerminacao': percentualGerminacao,
        'totalManchas': totalManchas,
        'totalPodridao': totalPodridao,
        'totalCotiledones': totalCotiledones,
        'indiceSanidade': indiceSanidade,
        'diasAtivo': dadosDiarios.isNotEmpty 
            ? DateTime.now().difference(DateTime.parse(dadosDiarios.last['data'] as String)).inDays 
            : 0,
        'ultimaAtualizacao': dadosDiarios.isNotEmpty 
            ? DateTime.parse(dadosDiarios.first['data'] as String) 
            : null,
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar dados agronômicos: $e');
      return {};
    }
  }

  /// Atualiza dados de uma posição do canteiro
  Future<void> atualizarPosicaoCanteiro({
    required String canteiroId,
    required String posicao,
    required Map<String, dynamic> dadosDiarios,
  }) async {
    try {
      Logger.info('$_tag: Atualizando posição $posicao do canteiro $canteiroId');
      
      final db = await _appDatabase.database;
      
      // Calcular percentual de germinação
      final germinadas = dadosDiarios['germinadas'] as int;
      final naoGerminadas = dadosDiarios['nao_germinadas'] as int;
      final total = germinadas + naoGerminadas;
      final percentual = total > 0 ? (germinadas / total) * 100 : 0.0;
      
      // Atualizar posição
      await db.update(
        'canteiro_posicoes',
        {
          'germinadas': germinadas,
          'total': total,
          'percentual': percentual,
          'ultima_atualizacao': DateTime.now().toIso8601String(),
          'dados_diarios': jsonEncode(dadosDiarios),
        },
        where: 'canteiro_id = ? AND posicao = ?',
        whereArgs: [canteiroId, posicao],
      );
      
      // Inserir dados diários
      await db.insert(
        'canteiro_dados_diarios',
        {
          'canteiro_id': canteiroId,
          'posicao': posicao,
          'data': DateTime.now().toIso8601String(),
          'germinadas': germinadas,
          'nao_germinadas': naoGerminadas,
          'manchas': dadosDiarios['manchas'] as int,
          'podridao': dadosDiarios['podridao'] as int,
          'cotiledones_amarelados': dadosDiarios['cotiledones_amarelados'] as int,
          'umidade_substrato': dadosDiarios['umidade_substrato'] as double,
          'temperatura': dadosDiarios['temperatura'] as double,
          'observacoes': dadosDiarios['observacoes'] as String?,
        },
      );
      
      Logger.info('$_tag: Posição $posicao atualizada com sucesso');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao atualizar posição: $e');
    }
  }

  /// Gera relatório profissional da IA para um canteiro
  Future<Map<String, dynamic>> gerarRelatorioProfissional(String canteiroId) async {
    try {
      Logger.info('$_tag: Gerando relatório profissional para canteiro $canteiroId');
      
      final canteiros = await obterCanteirosAtivos();
      final canteiro = canteiros.firstWhere((c) => c.id == canteiroId);
      
      if (canteiro == null) {
        throw Exception('Canteiro não encontrado');
      }
      
      // Preparar dados para IA
      final dadosParaIA = {
        'canteiro': {
          'id': canteiro.id,
          'nome': canteiro.nome,
          'loteId': canteiro.loteId,
          'cultura': canteiro.cultura,
          'variedade': canteiro.variedade,
          'status': canteiro.status,
          'diasAtivo': canteiro.estatisticas['diasAtivo'],
        },
        'posicoes': canteiro.posicoes.map((p) => {
          'posicao': p.posicao,
          'loteId': p.loteId,
          'subteste': p.subteste,
          'germinadas': p.germinadas,
          'total': p.total,
          'percentual': p.percentual,
          'cultura': p.cultura,
          'diasDesdeInicio': p.diasDesdeInicio,
          'qualidade': p.qualidadeDescricao,
        }).toList(),
        'dadosAgronomicos': canteiro.dadosAgronomicos,
      };
      
      // Análise com IA FortSmart
      final analiseIA = await _ai.analyzeGermination(
        contagensPorDia: _extrairContagensPorDia(canteiro),
        sementesTotais: canteiro.dadosAgronomicos['totalSementes'] as int? ?? 0,
        germinadasFinal: canteiro.dadosAgronomicos['totalGerminadas'] as int? ?? 0,
        manchas: canteiro.dadosAgronomicos['totalManchas'] as int? ?? 0,
        podridao: canteiro.dadosAgronomicos['totalPodridao'] as int? ?? 0,
        cotiledonesAmarelados: canteiro.dadosAgronomicos['totalCotiledones'] as int? ?? 0,
        pureza: 98.0, // TODO: Calcular baseado nos dados
        cultura: canteiro.cultura,
      );
      
      // Combinar dados do canteiro com análise da IA
      final relatorio = {
        'canteiro': dadosParaIA['canteiro'],
        'posicoes': dadosParaIA['posicoes'],
        'dadosAgronomicos': dadosParaIA['dadosAgronomicos'],
        'analiseIA': analiseIA,
        'recomendacoes': _gerarRecomendacoes(canteiro, analiseIA),
        'prescricoes': _gerarPrescricoes(canteiro, analiseIA),
        'geradoEm': DateTime.now().toIso8601String(),
      };
      
      Logger.info('$_tag: Relatório profissional gerado com sucesso');
      return relatorio;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar relatório profissional: $e');
      return {
        'erro': e.toString(),
        'geradoEm': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Extrai contagens por dia dos dados do canteiro
  Map<int, int> _extrairContagensPorDia(CanteiroModel canteiro) {
    final contagens = <int, int>{};
    
    // Simular contagens por dia baseadas nos dados
    final diasAtivo = canteiro.estatisticas['diasAtivo'] as int;
    for (int dia = 1; dia <= diasAtivo; dia++) {
      contagens[dia] = (canteiro.dadosAgronomicos['totalGerminadas'] as int? ?? 0) ~/ diasAtivo;
    }
    
    return contagens;
  }

  /// Gera recomendações baseadas na análise
  List<String> _gerarRecomendacoes(CanteiroModel canteiro, Map<String, dynamic> analiseIA) {
    final recomendacoes = <String>[];
    
    final percentualGerminacao = canteiro.dadosAgronomicos['percentualGerminacao'] as double? ?? 0.0;
    final indiceSanidade = canteiro.dadosAgronomicos['indiceSanidade'] as double? ?? 100.0;
    
    if (percentualGerminacao >= 90) {
      recomendacoes.add('✅ Germinação excelente - Sementes de alta qualidade');
    } else if (percentualGerminacao >= 80) {
      recomendacoes.add('✅ Germinação boa - Considerar aumento da densidade de semeadura');
    } else if (percentualGerminacao >= 70) {
      recomendacoes.add('⚠️ Germinação regular - Aumentar significativamente a densidade');
    } else {
      recomendacoes.add('❌ Germinação baixa - Considerar descarte ou tratamento especial');
    }
    
    if (indiceSanidade >= 95) {
      recomendacoes.add('✅ Sanidade excelente - Baixo risco fitossanitário');
    } else if (indiceSanidade >= 85) {
      recomendacoes.add('⚠️ Sanidade boa - Monitorar desenvolvimento');
    } else {
      recomendacoes.add('❌ Sanidade comprometida - Aplicar tratamento fungicida');
    }
    
    return recomendacoes;
  }

  /// Gera prescrições baseadas na análise
  List<Map<String, dynamic>> _gerarPrescricoes(CanteiroModel canteiro, Map<String, dynamic> analiseIA) {
    final prescricoes = <Map<String, dynamic>>[];
    
    final percentualGerminacao = canteiro.dadosAgronomicos['percentualGerminacao'] as double? ?? 0.0;
    final indiceSanidade = canteiro.dadosAgronomicos['indiceSanidade'] as double? ?? 100.0;
    
    if (percentualGerminacao < 80) {
      prescricoes.add({
        'tipo': 'Tratamento de Sementes',
        'status': 'Recomendado',
        'descricao': 'Fungicida + Inseticida para melhorar germinação',
        'cor': 0xFF2196F3,
        'prioridade': 'media',
      });
    }
    
    if (indiceSanidade < 90) {
      prescricoes.add({
        'tipo': 'Tratamento Fungicida',
        'status': 'Necessário',
        'descricao': 'Controle de patógenos baseado no catálogo de organismos',
        'cor': 0xFFF44336,
        'prioridade': 'alta',
      });
    }
    
    if (percentualGerminacao >= 80 && indiceSanidade >= 90) {
      prescricoes.add({
        'tipo': 'Sementes Premium',
        'status': 'Aprovadas',
        'descricao': 'Sem necessidade de tratamento adicional',
        'cor': 0xFF4CAF50,
        'prioridade': 'baixa',
      });
    }
    
    return prescricoes;
  }

  /// Cria as tabelas necessárias para canteiros
  Future<void> _criarTabelasCanteiros(Database db) async {
    try {
      Logger.info('$_tag: Criando tabelas de canteiros...');
      
      // Criar tabela de canteiros
      await db.execute('''
        CREATE TABLE IF NOT EXISTS canteiros (
          id TEXT PRIMARY KEY,
          nome TEXT NOT NULL,
          lote_id TEXT NOT NULL,
          cultura TEXT NOT NULL,
          variedade TEXT NOT NULL,
          data_criacao TEXT NOT NULL,
          data_conclusao TEXT,
          status TEXT NOT NULL DEFAULT 'ativo',
          observacoes TEXT
        )
      ''');
      
      // Criar tabela de posições do canteiro
      await db.execute('''
        CREATE TABLE IF NOT EXISTS canteiro_posicoes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          canteiro_id TEXT NOT NULL,
          posicao TEXT NOT NULL,
          lote_id TEXT,
          subteste TEXT,
          cor INTEGER NOT NULL DEFAULT 0xFF4CAF50,
          germinadas INTEGER NOT NULL DEFAULT 0,
          total INTEGER NOT NULL DEFAULT 0,
          percentual REAL NOT NULL DEFAULT 0.0,
          cultura TEXT,
          data_inicio TEXT,
          ultima_atualizacao TEXT,
          dados_diarios TEXT NOT NULL DEFAULT '{}',
          observacoes TEXT,
          FOREIGN KEY (canteiro_id) REFERENCES canteiros (id) ON DELETE CASCADE
        )
      ''');
      
      // Criar tabela de dados diários do canteiro
      await db.execute('''
        CREATE TABLE IF NOT EXISTS canteiro_dados_diarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          canteiro_id TEXT NOT NULL,
          posicao TEXT NOT NULL,
          data TEXT NOT NULL,
          germinadas INTEGER NOT NULL DEFAULT 0,
          nao_germinadas INTEGER NOT NULL DEFAULT 0,
          manchas INTEGER NOT NULL DEFAULT 0,
          podridao INTEGER NOT NULL DEFAULT 0,
          cotiledones_amarelados INTEGER NOT NULL DEFAULT 0,
          umidade_substrato REAL,
          temperatura REAL,
          observacoes TEXT,
          FOREIGN KEY (canteiro_id) REFERENCES canteiros (id) ON DELETE CASCADE
        )
      ''');
      
      Logger.info('$_tag: Tabelas de canteiros criadas com sucesso');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao criar tabelas de canteiros: $e');
      rethrow;
    }
  }

  /// Cria um canteiro padrão com 21 posições (7x3)
  Future<void> _criarCanteiroPadrao(Database db) async {
    try {
      Logger.info('$_tag: Criando canteiro padrão...');
      
      final canteiroId = 'canteiro_padrao_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().toIso8601String();
      
      // Inserir canteiro
      await db.insert('canteiros', {
        'id': canteiroId,
        'nome': 'Canteiro Padrão',
        'lote_id': 'lote_padrao',
        'cultura': 'Soja',
        'variedade': 'Padrão',
        'data_criacao': now,
        'status': 'ativo',
        'observacoes': 'Canteiro padrão criado automaticamente para testes de germinação',
      });
      
      // Criar posições (7x3 = 21 posições)
      final posicoes = <String>[];
      for (int row = 1; row <= 3; row++) {
        for (int col = 1; col <= 7; col++) {
          final letra = String.fromCharCode(64 + col); // A, B, C, D, E, F, G
          posicoes.add('$letra$row');
        }
      }
      
      // Inserir posições
      for (final posicao in posicoes) {
        await db.insert('canteiro_posicoes', {
          'canteiro_id': canteiroId,
          'posicao': posicao,
          'cor': 0xFF4CAF50, // Verde
          'germinadas': 0,
          'total': 0,
          'percentual': 0.0,
          'dados_diarios': '{}',
        });
      }
      
      Logger.info('$_tag: Canteiro padrão criado com ${posicoes.length} posições');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao criar canteiro padrão: $e');
      rethrow;
    }
  }

}

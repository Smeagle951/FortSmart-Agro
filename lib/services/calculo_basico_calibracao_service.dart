import 'dart:convert';
import '../models/calculo_basico_calibracao_model.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar cálculos básicos de calibração
/// Implementa persistência e operações CRUD
class CalculoBasicoCalibracaoService {
  static final CalculoBasicoCalibracaoService _instance = CalculoBasicoCalibracaoService._internal();
  factory CalculoBasicoCalibracaoService() => _instance;
  CalculoBasicoCalibracaoService._internal();

  // Lista em memória para simular banco de dados
  // Em implementação real, usar SQLite ou outro banco
  final List<CalculoBasicoCalibracaoModel> _calibracoes = [];

  /// Salva uma nova calibração
  Future<String> salvar(CalculoBasicoCalibracaoModel calibracao) async {
    try {
      // Validar dados antes de salvar
      _validarCalibracao(calibracao);
      
      // Verificar se já existe (por ID)
      final index = _calibracoes.indexWhere((c) => c.id == calibracao.id);
      
      if (index >= 0) {
        // Atualizar existente
        _calibracoes[index] = calibracao;
        Logger.info('Calibração atualizada: ${calibracao.id}');
      } else {
        // Adicionar nova
        _calibracoes.add(calibracao);
        Logger.info('Nova calibração salva: ${calibracao.id}');
      }
      
      return calibracao.id;
    } catch (e) {
      Logger.error('Erro ao salvar calibração: $e');
      rethrow;
    }
  }

  /// Busca todas as calibrações
  Future<List<CalculoBasicoCalibracaoModel>> buscarTodas() async {
    try {
      // Ordenar por data de criação (mais recente primeiro)
      final calibracoesOrdenadas = List<CalculoBasicoCalibracaoModel>.from(_calibracoes);
      calibracoesOrdenadas.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      
      return calibracoesOrdenadas;
    } catch (e) {
      Logger.error('Erro ao buscar calibrações: $e');
      return [];
    }
  }

  /// Busca calibração por ID
  Future<CalculoBasicoCalibracaoModel?> buscarPorId(String id) async {
    try {
      return _calibracoes.firstWhere(
        (calibracao) => calibracao.id == id,
        orElse: () => throw Exception('Calibração não encontrada'),
      );
    } catch (e) {
      Logger.error('Erro ao buscar calibração por ID $id: $e');
      return null;
    }
  }

  /// Exclui uma calibração
  Future<bool> excluir(String id) async {
    try {
      final index = _calibracoes.indexWhere((c) => c.id == id);
      if (index >= 0) {
        _calibracoes.removeAt(index);
        Logger.info('Calibração excluída: $id');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erro ao excluir calibração $id: $e');
      return false;
    }
  }

  /// Busca calibrações por período
  Future<List<CalculoBasicoCalibracaoModel>> buscarPorPeriodo(
    DateTime dataInicio,
    DateTime dataFim,
  ) async {
    try {
      return _calibracoes.where((calibracao) {
        return calibracao.dataCriacao.isAfter(dataInicio.subtract(const Duration(days: 1))) &&
               calibracao.dataCriacao.isBefore(dataFim.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      Logger.error('Erro ao buscar calibrações por período: $e');
      return [];
    }
  }

  /// Busca calibrações por operador
  Future<List<CalculoBasicoCalibracaoModel>> buscarPorOperador(String operador) async {
    try {
      return _calibracoes.where((calibracao) {
        return calibracao.operador?.toLowerCase().contains(operador.toLowerCase()) ?? false;
      }).toList();
    } catch (e) {
      Logger.error('Erro ao buscar calibrações por operador: $e');
      return [];
    }
  }

  /// Exporta dados para JSON
  Future<String> exportarParaJson() async {
    try {
      final dados = _calibracoes.map((calibracao) => calibracao.toMap()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(dados);
      return jsonString;
    } catch (e) {
      Logger.error('Erro ao exportar dados: $e');
      rethrow;
    }
  }

  /// Importa dados de JSON
  Future<int> importarDeJson(String jsonString) async {
    try {
      final dados = json.decode(jsonString) as List<dynamic>;
      int importados = 0;
      
      for (final item in dados) {
        try {
          final calibracao = CalculoBasicoCalibracaoModel.fromMap(item as Map<String, dynamic>);
          await salvar(calibracao);
          importados++;
        } catch (e) {
          Logger.warning('Erro ao importar item: $e');
        }
      }
      
      Logger.info('Importados $importados calibrações');
      return importados;
    } catch (e) {
      Logger.error('Erro ao importar dados: $e');
      rethrow;
    }
  }

  /// Gera relatório de calibração
  String gerarRelatorio(CalculoBasicoCalibracaoModel calibracao) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== RELATÓRIO DE CALIBRAÇÃO ===');
    buffer.writeln();
    buffer.writeln('Data: ${_formatarData(calibracao.dataCriacao)}');
    buffer.writeln('Versão do Cálculo: ${calibracao.calcVersion}');
    buffer.writeln();
    
    // Dados de entrada
    buffer.writeln('--- ENTRADAS ---');
    buffer.writeln('Modo de Coleta: ${calibracao.rawInputs.mode == InputMode.time ? "Por Tempo" : "Por Distância"}');
    
    if (calibracao.rawInputs.mode == InputMode.time) {
      buffer.writeln('Tempo: ${calibracao.rawInputs.timeSeconds} s');
    } else {
      buffer.writeln('Distância: ${calibracao.rawInputs.distanceMeters} m');
    }
    
    buffer.writeln('Largura da Faixa: ${calibracao.rawInputs.widthMeters} m');
    buffer.writeln('Velocidade: ${calibracao.rawInputs.speedKmh} km/h');
    buffer.writeln('Valor Coletado: ${calibracao.rawInputs.collectedKg} kg');
    buffer.writeln('Taxa Desejada: ${calibracao.rawInputs.desiredKgHa} kg/ha');
    buffer.writeln();
    
    // Resultados
    buffer.writeln('--- RESULTADOS ---');
    buffer.writeln('Distância Percorrida: ${calibracao.computedResults.distanceMeters.toStringAsFixed(2)} m');
    buffer.writeln('Área Percorrida: ${calibracao.computedResults.areaM2.toStringAsFixed(2)} m² (${calibracao.computedResults.areaHa.toStringAsFixed(4)} ha)');
    buffer.writeln('Taxa Real Aplicada: ${calibracao.computedResults.taxaKgHa.toStringAsFixed(2)} kg/ha');
    buffer.writeln('Erro vs Meta: ${calibracao.computedResults.erroPercent.toStringAsFixed(2)}%');
    buffer.writeln('Sugestão de Ajuste: ${_getSugestaoTexto(calibracao.computedResults.ajustePercent)}');
    buffer.writeln();
    
    // Campos adicionais
    if (calibracao.operador != null) buffer.writeln('Operador: ${calibracao.operador}');
    if (calibracao.maquina != null) buffer.writeln('Máquina: ${calibracao.maquina}');
    if (calibracao.fertilizante != null) buffer.writeln('Fertilizante: ${calibracao.fertilizante}');
    if (calibracao.observacoes != null) buffer.writeln('Observações: ${calibracao.observacoes}');
    
    buffer.writeln();
    buffer.writeln('=== FIM DO RELATÓRIO ===');
    
    return buffer.toString();
  }

  /// Gera estatísticas gerais
  Map<String, dynamic> gerarEstatisticas() {
    if (_calibracoes.isEmpty) {
      return {
        'total': 0,
        'porModo': {'tempo': 0, 'distancia': 0},
        'mediaErro': 0.0,
        'calibracoesPrecisas': 0,
        'periodo': null,
      };
    }
    
    final total = _calibracoes.length;
    final porTempo = _calibracoes.where((c) => c.rawInputs.mode == InputMode.time).length;
    final porDistancia = _calibracoes.where((c) => c.rawInputs.mode == InputMode.distance).length;
    
    final somaErro = _calibracoes.fold<double>(0, (soma, c) => soma + c.computedResults.erroPercent.abs());
    final mediaErro = somaErro / total;
    
    final precisas = _calibracoes.where((c) => c.computedResults.erroPercent.abs() <= 2).length;
    
    final datas = _calibracoes.map((c) => c.dataCriacao).toList();
    datas.sort();
    
    return {
      'total': total,
      'porModo': {'tempo': porTempo, 'distancia': porDistancia},
      'mediaErro': mediaErro,
      'calibracoesPrecisas': precisas,
      'periodo': datas.isNotEmpty ? {
        'inicio': _formatarData(datas.first),
        'fim': _formatarData(datas.last),
      } : null,
    };
  }

  /// Valida uma calibração antes de salvar
  void _validarCalibracao(CalculoBasicoCalibracaoModel calibracao) {
    if (calibracao.id.isEmpty) {
      throw ArgumentError('ID da calibração não pode estar vazio');
    }
    
    if (calibracao.rawInputs.widthMeters <= 0) {
      throw ArgumentError('Largura da faixa deve ser maior que zero');
    }
    
    if (calibracao.rawInputs.speedKmh <= 0) {
      throw ArgumentError('Velocidade deve ser maior que zero');
    }
    
    if (calibracao.rawInputs.collectedKg <= 0) {
      throw ArgumentError('Valor coletado deve ser maior que zero');
    }
    
    if (calibracao.rawInputs.desiredKgHa <= 0) {
      throw ArgumentError('Taxa desejada deve ser maior que zero');
    }
    
    if (calibracao.rawInputs.mode == InputMode.time && calibracao.rawInputs.timeSeconds <= 0) {
      throw ArgumentError('Tempo deve ser maior que zero');
    }
    
    if (calibracao.rawInputs.mode == InputMode.distance && 
        (calibracao.rawInputs.distanceMeters == null || calibracao.rawInputs.distanceMeters! <= 0)) {
      throw ArgumentError('Distância deve ser maior que zero');
    }
  }

  /// Formata data para exibição
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  /// Gera texto de sugestão
  String _getSugestaoTexto(double ajuste) {
    if (ajuste > 0) {
      return 'Aumentar dosador ≈ ${ajuste.toStringAsFixed(1)}%';
    } else if (ajuste < 0) {
      return 'Reduzir dosador ≈ ${ajuste.abs().toStringAsFixed(1)}%';
    } else {
      return 'Sem ajuste necessário';
    }
  }
}

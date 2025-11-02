import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';
import 'package:fortsmart_agro/modules/planting/repositories/plantio_repository.dart';
import 'package:uuid/uuid.dart';

/// Serviço para gerenciar operações relacionadas ao plantio
class PlantioService {
  static final PlantioService _instance = PlantioService._internal();
  final PlantioRepository _repository = PlantioRepository();

  factory PlantioService() => _instance;
  PlantioService._internal();

  /// Obtém um registro de plantio pelo ID
  Future<PlantioModel?> obterPorId(String id) async {
    try {
      return await _repository.obterPorId(id);
    } catch (e) {
      debugPrint('Erro ao obter plantio por ID: $e');
      return null;
    }
  }

  /// Inicializa a tabela de plantio no banco de dados
  Future<void> inicializarTabela() async {
    try {
      // A inicialização da tabela é feita pelo AppDatabase
      debugPrint('Tabela de plantio inicializada com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar tabela de plantio: $e');
    }
  }

  /// Cadastra um novo registro de plantio
  Future<bool> cadastrar(PlantioModel plantio) async {
    try {
      final id = await _repository.inserir(plantio);
      return id > 0;
    } catch (e) {
      debugPrint('Erro ao cadastrar plantio: $e');
      return false;
    }
  }

  /// Atualiza um registro de plantio existente
  Future<bool> atualizar(PlantioModel plantio) async {
    try {
      final result = await _repository.atualizar(plantio);
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao atualizar plantio: $e');
      return false;
    }
  }

  /// Exclui um registro de plantio
  Future<bool> excluir(String id) async {
    try {
      final result = await _repository.excluir(id);
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao excluir plantio: $e');
      return false;
    }
  }

  /// Lista todos os registros de plantio
  Future<List<PlantioModel>> listar() async {
    try {
      return await _repository.listar();
    } catch (e) {
      debugPrint('Erro ao listar plantios: $e');
      return [];
    }
  }

  /// Lista plantios por talhão
  Future<List<PlantioModel>> listarPorTalhao(String talhaoId) async {
    try {
      return await _repository.listarPorTalhao(talhaoId);
    } catch (e) {
      debugPrint('Erro ao listar plantios por talhão: $e');
      return [];
    }
  }

  /// Lista plantios por cultura
  Future<List<PlantioModel>> listarPorCultura(String culturaId) async {
    try {
      return await _repository.listarPorCultura(culturaId);
    } catch (e) {
      debugPrint('Erro ao listar plantios por cultura: $e');
      return [];
    }
  }

  /// Calcula o número de sementes por hectare
  int calcularSementesHa(double espacamento, int densidade) {
    // Fórmula: (10000 / (espacamento / 100)) * densidade
    return ((10000 / (espacamento / 100)) * densidade).round();
  }

  /// Calcula a quantidade em kg por hectare
  double calcularKgHa(int sementesHa, double pesoMedioSemente) {
    // Fórmula: (sementesHa * pesoMedioSemente) / 1000
    return (sementesHa * pesoMedioSemente) / 1000;
  }

  /// Calcula a quantidade em sacas por hectare
  double calcularSacasHa(double kgHa) {
    // Considerando sacas de 60kg
    return kgHa / 60;
  }

  /// Calcula o número de sementes por metro linear
  double calcularSementesMetroLinear(double densidade, double germinacao) {
    // Fórmula: densidade / germinacao
    return densidade / (germinacao / 100);
  }

  /// Gera um novo ID para plantio
  String gerarId() {
    return const Uuid().v4();
  }
}

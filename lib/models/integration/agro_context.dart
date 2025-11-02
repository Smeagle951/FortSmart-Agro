import '../agricultural_product.dart';
import '../talhao_model_new.dart';
import '../safra_model.dart';
import '../../repositories/talhao_repository_new.dart';
import '../../repositories/agricultural_product_repository.dart';

/// Classe que representa um contexto agrícola completo (Talhão + Safra + Cultura)
/// Usado como base para todas as operações entre módulos
class AgroContext {
  final String talhaoId;
  final String safraId;
  final String culturaId;
  
  // Repositórios
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final AgriculturalProductRepository _culturasRepository = AgriculturalProductRepository();
  
  // Cache
  TalhaoModel? _talhao;
  SafraModel? _safra;
  AgriculturalProduct? _cultura;
  
  AgroContext({
    required this.talhaoId,
    required this.safraId,
    required this.culturaId,
  });
  
  /// Retorna uma descrição resumida do contexto
  String get descricao {
    return 'Talhão: ${_talhao?.nome ?? "Carregando..."} | '
           'Safra: ${_safra?.safra ?? "Carregando..."} | '
           'Cultura: ${_cultura?.name ?? "Carregando..."}';
  }
  
  /// Carrega o talhão associado a este contexto
  Future<TalhaoModel> getTalhao() async {
    if (_talhao != null) return _talhao!;
    
    _talhao = await _talhaoRepository.obterPorId(talhaoId);
    return _talhao!;
  }
  
  /// Carrega a safra associada a este contexto
  Future<SafraModel> getSafra() async {
    if (_safra != null) return _safra!;
    
    final talhao = await getTalhao();
    _safra = talhao.safras.firstWhere(
      (safra) => safra.id == safraId,
      orElse: () => throw Exception('Safra não encontrada: $safraId')
    );
    
    return _safra!;
  }
  
  /// Carrega a cultura associada a este contexto
  Future<AgriculturalProduct> getCultura() async {
    if (_cultura != null) return _cultura!;
    
    _cultura = await _culturasRepository.getById(culturaId);
    return _cultura!;
  }
  
  /// Cria uma cópia deste contexto com os valores opcionalmente alterados
  AgroContext copyWith({
    String? talhaoId,
    String? safraId,
    String? culturaId,
  }) {
    return AgroContext(
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
    );
  }
  
  /// Converte o contexto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'safraId': safraId,
      'culturaId': culturaId,
    };
  }
  
  /// Cria um contexto a partir de um mapa
  factory AgroContext.fromMap(Map<String, dynamic> map) {
    return AgroContext(
      talhaoId: map['talhaoId'] as String,
      safraId: map['safraId'] as String,
      culturaId: map['culturaId'] as String,
    );
  }
  
  @override
  String toString() => 'AgroContext(talhaoId: $talhaoId, safraId: $safraId, culturaId: $culturaId)';
}

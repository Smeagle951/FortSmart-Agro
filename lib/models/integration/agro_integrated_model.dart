import 'agro_context.dart';

/// Interface base para modelos que implementam integração com o contexto agrícola
/// Todos os módulos que precisam se integrar ao contexto de talhão, safra e cultura
/// devem implementar esta interface
abstract class AgroIntegratedModel {
  /// ID único do objeto
  String get id;
  
  /// ID do talhão associado
  String get talhaoId;
  
  /// Nome do talhão associado
  String get talhaoNome;
  
  /// ID da safra associada
  String get safraId;
  
  /// Nome/descrição da safra (ex: "2024/2025")
  String get safraNome;
  
  /// ID da cultura associada
  String get culturaId;
  
  /// Nome da cultura associada
  String get culturaNome;
  
  /// Converte o modelo para um contexto agrícola
  AgroContext toAgroContext() {
    return AgroContext(
      talhaoId: talhaoId,
      safraId: safraId,
      culturaId: culturaId,
    );
  }
}

// REMOVIDO: import '../models/machine.dart'; - arquivo não existe

/// ARQUIVO COMENTADO: Extensão removida pois arquivo machine.dart não existe
/// 
/// Este arquivo continha extensões para o enum MachineType, mas foi comentado
/// porque o arquivo machine.dart foi removido do projeto.
/// 
/// Se necessário reimplementar funcionalidades de máquinas, criar novos arquivos:
/// - lib/models/machine_model.dart
/// - lib/repositories/machine_repository.dart
/// - lib/utils/machine_type_extension.dart (este arquivo)

/*
import '../models/machine.dart';

/// Extensão para o enum MachineType para adicionar funcionalidades úteis
extension MachineTypeExtension on MachineType {
  /// Retorna o nome do tipo de máquina em formato string
  String get name {
    switch (this) {
      case MachineType.tractor:
        return 'tractor';
      case MachineType.planter:
        return 'planter';
      case MachineType.harvester:
        return 'harvester';
      case MachineType.sprayer:
        return 'sprayer';
      case MachineType.other:
        return 'other';
      default:
        return 'unknown';
    }
  }
  
  /// Retorna o nome do tipo de máquina em português
  String get displayName {
    switch (this) {
      case MachineType.tractor:
        return 'Trator';
      case MachineType.planter:
        return 'Plantadeira';
      case MachineType.harvester:
        return 'Colheitadeira';
      case MachineType.sprayer:
        return 'Pulverizador';
      case MachineType.other:
        return 'Outro';
      default:
        return 'Desconhecido';
    }
  }
  
  /// Converte uma string para o enum MachineType
  static MachineType fromString(String value) {
    final lowerValue = value.toLowerCase();
    
    if (lowerValue == 'tractor') return MachineType.tractor;
    if (lowerValue == 'planter') return MachineType.planter;
    if (lowerValue == 'harvester') return MachineType.harvester;
    if (lowerValue == 'sprayer') return MachineType.sprayer;
    
    return MachineType.other;
  }
}
*/

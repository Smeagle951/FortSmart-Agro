import '../models/farm.dart';

/// Adaptador para garantir compatibilidade entre diferentes modelos de fazenda
class FarmAdapter {
  /// Garante que todos os campos obrigatórios estejam preenchidos
  static Farm ensureValidFarm(Farm farm) {
    return Farm(
      id: farm.id,
      name: farm.name,
      logoUrl: farm.logoUrl,
      // Garantir que campos obrigatórios tenham valores padrão se forem nulos
      responsiblePerson: farm.responsiblePerson ?? 'Não informado',
      documentNumber: farm.documentNumber ?? 'Não informado',
      phone: farm.phone ?? 'Não informado',
      email: farm.email ?? 'contato@fortsmartagro.com',
      address: farm.address,
      totalArea: farm.totalArea,
      plotsCount: farm.plotsCount,
      crops: farm.crops,
      hasIrrigation: farm.hasIrrigation,
      irrigationType: farm.irrigationType ?? 'Não informado',
      mechanizationLevel: farm.mechanizationLevel ?? 'Médio',
      municipality: farm.municipality ?? 'Não informado',
      state: farm.state ?? 'Não informado',
      ownerName: farm.ownerName ?? 'Não informado',
    );
  }
  
  /// Cria uma fazenda padrão quando nenhuma fazenda estiver disponível
  static Farm createDefaultFarm() {
    return Farm(
      id: 'default_farm_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Fazenda Padrão',
      logoUrl: null,
      responsiblePerson: 'Usuário FortSmart',
      documentNumber: '000.000.000-00',
      phone: '(00) 00000-0000',
      email: 'contato@fortsmartagro.com',
      address: 'Endereço não cadastrado',
      totalArea: 0.0,
      plotsCount: 0,
      crops: [],
      hasIrrigation: false,
      irrigationType: 'Não informado',
      mechanizationLevel: 'Médio',
      municipality: 'Não informado',
      state: 'Não informado',
      ownerName: 'Usuário FortSmart',
    );
  }
}

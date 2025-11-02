import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/cultura_model.dart';
import 'package:fortsmart_agro/services/cultura_talhao_service.dart';
import 'package:fortsmart_agro/services/culture_import_service.dart';
import 'package:fortsmart_agro/utils/cultura_colors.dart';
import 'package:fortsmart_agro/screens/talhoes_com_safras/providers/talhao_provider.dart';

// Removido o modelo CulturaModel duplicado, agora usando o modelo do pacote models

class CulturaProvider with ChangeNotifier {
  final List<CulturaModel> _culturas = [];
  CulturaTalhaoService? _culturaService;
  bool _isLoading = false;
  
  /// Obtém a instância do CulturaTalhaoService de forma lazy
  CulturaTalhaoService get culturaService {
    _culturaService ??= CulturaTalhaoService();
    return _culturaService!;
  }
  
  // Lista de cores para novas culturas em formato hexadecimal
  final List<String> _coresPadrao = [
    '#F44336', // Red
    '#2196F3', // Blue
    '#9C27B0', // Purple
    '#FF9800', // Orange
    '#009688', // Teal
    '#E91E63', // Pink
    '#3F51B5', // Indigo
    '#FFC107', // Amber
    '#00BCD4', // Cyan
    '#FFC107', // Deep Orange
    '#CDDC39', // Lime
    '#673AB7', // Deep Purple
  ];
  
  // Método para obter uma cor para nova cultura
  String getProximaCor() {
    // Verifica quais cores já estão em uso
    final coresEmUso = _culturas.map((c) => c.color).toList();
    
    // Procura por uma cor não utilizada
    for (var cor in _coresPadrao) {
      if (!coresEmUso.contains(cor)) {
        return cor;
      }
    }
    
    // Se todas as cores estiverem em uso, gera uma cor aleatória
    final random = (DateTime.now().millisecondsSinceEpoch & 0xFFFFFF).toInt();
    return '#${random.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  List<CulturaModel> get culturas => [..._culturas];
  bool get isLoading => _isLoading;

  CulturaModel? findById(String id) {
    try {
      return _culturas.firstWhere((cultura) => cultura.id == id);
    } catch (e) {
      return null;
    }
  }

  void addCultura(CulturaModel cultura) {
    _culturas.add(cultura);
    notifyListeners();
  }

  void updateCultura(CulturaModel cultura) {
    final index = _culturas.indexWhere((c) => c.id == cultura.id);
    if (index >= 0) {
      _culturas[index] = cultura;
      notifyListeners();
    }
  }

  void removeCultura(String id) {
    _culturas.removeWhere((cultura) => cultura.id == id);
    notifyListeners();
  }

  CulturaModel? obterCulturaPorId(String id) {
    return findById(id);
  }

  /// Obtém todas as culturas (alias para carregarCulturas)
  Future<List<CulturaModel>> getAllCulturas() async {
    await carregarCulturas();
    return List.from(_culturas);
  }
  
  /// Força o recarregamento das culturas (útil após criar talhão)
  Future<void> forceReloadCultures() async {
    print('🔄 CulturaProvider: Forçando recarregamento de culturas...');
    _isLoading = false; // Reset loading state
    await carregarCulturas();
    print('✅ CulturaProvider: Culturas recarregadas com sucesso');
  }
  
  /// Carrega culturas personalizadas dos talhões existentes
  Future<void> _carregarCulturasPersonalizadas() async {
    try {
      print('🔄 CulturaProvider: Carregando culturas personalizadas dos talhões...');
      
      // Carregar talhões diretamente do banco de dados
      final talhoes = await _carregarTalhoesDoBanco();
      
      print('📊 Encontrados ${talhoes.length} talhões para verificar culturas personalizadas');
      
      final culturasPersonalizadas = <String, CulturaModel>{};
      
      for (final talhao in talhoes) {
        for (final safra in talhao.safras) {
          // Verificar se é uma cultura personalizada (com prefixo custom_)
          if (safra.idCultura.startsWith('custom_')) {
            final nomeCultura = safra.culturaNome;
            final idCultura = safra.idCultura;
            
            // Verificar se já não existe na lista de culturas padrão
            final jaExiste = _culturas.any((c) => c.name.toLowerCase() == nomeCultura.toLowerCase());
            
            if (!jaExiste && !culturasPersonalizadas.containsKey(idCultura)) {
              final culturaPersonalizada = CulturaModel(
                id: idCultura,
                name: nomeCultura,
                color: _obterCorPorNome(nomeCultura),
                description: 'Cultura personalizada do talhão ${talhao.name}',
              );
              
              culturasPersonalizadas[idCultura] = culturaPersonalizada;
              print('  - Cultura personalizada: ${nomeCultura} (ID: ${idCultura})');
            }
          }
        }
      }
      
      // Adicionar culturas personalizadas à lista
      _culturas.addAll(culturasPersonalizadas.values);
      
      print('✅ CulturaProvider: ${culturasPersonalizadas.length} culturas personalizadas adicionadas');
    } catch (e) {
      print('⚠️ Erro ao carregar culturas personalizadas: $e');
    }
  }
  
  /// Método público para obter culturas para uso em submódulos de plantio
  Future<List<CulturaModel>> getCulturasParaPlantio() async {
    print('🔄 CulturaProvider: Obtendo culturas para submódulos de plantio...');
    
    // Garantir que as culturas estão carregadas
    if (_culturas.isEmpty || _isLoading) {
      await carregarCulturas();
    }
    
    print('✅ CulturaProvider: Retornando ${_culturas.length} culturas para plantio');
    return List.from(_culturas);
  }

  Future<void> carregarCulturas() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      print('🔄 CulturaProvider: Iniciando carregamento de culturas...');
      
      // Primeiro, inicializar o CultureImportService para garantir que o banco está pronto
      try {
        final cultureImportService = CultureImportService();
        await cultureImportService.initialize();
        print('✅ CultureImportService inicializado');
        
        // Tentar carregar diretamente do CultureImportService
        final culturasImport = await cultureImportService.getAllCrops();
        print('📊 CultureImportService retornou: ${culturasImport.length} culturas');
        
        if (culturasImport.isNotEmpty) {
          _culturas.clear();
          for (var cultura in culturasImport) {
            final culturaModel = CulturaModel(
              id: cultura['id']?.toString() ?? '0',
              name: cultura['name'] ?? '',
              color: _obterCorPorNome(cultura['name'] ?? ''),
              description: cultura['description'] ?? '',
            );
            _culturas.add(culturaModel);
            print('  - ${culturaModel.name} (ID: ${culturaModel.id})');
          }
          
          // Carregar culturas personalizadas dos talhões
          await _carregarCulturasPersonalizadas();
          
          print('✅ CulturaProvider: ${_culturas.length} culturas carregadas (padrão + personalizadas)');
          _isLoading = false;
          notifyListeners();
          return; // Sair se conseguiu carregar do CultureImportService
        }
      } catch (e) {
        print('❌ Erro ao carregar do CultureImportService: $e');
      }
      
      // Se não conseguiu do CultureImportService, tentar do CulturaTalhaoService
      try {
        final culturasData = await culturaService.listarCulturas();
        print('📊 CulturaProvider: ${culturasData.length} culturas carregadas do serviço');
        
        if (culturasData.isNotEmpty) {
          // Converter para CulturaModel
          _culturas.clear();
          for (var culturaData in culturasData) {
            final cultura = CulturaModel(
              id: culturaData['id'].toString(),
              name: culturaData['nome'],
              color: culturaData['cor'] ?? '#4CAF50',
            );
            _culturas.add(cultura);
            print('  - ${cultura.name} (ID: ${cultura.id})');
          }
          
          print('✅ CulturaProvider: ${_culturas.length} culturas carregadas do CulturaTalhaoService');
          _isLoading = false;
          notifyListeners();
          return; // Sair se conseguiu carregar do CulturaTalhaoService
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaTalhaoService: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar nenhuma cultura real
      print('❌ Nenhuma cultura real encontrada em nenhuma fonte');
      _culturas.clear();
      
    } catch (e) {
      print('❌ Erro geral ao carregar culturas no CulturaProvider: $e');
      _culturas.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retorna cor específica para cada cultura com bom contraste
  Color _obterCorPorNome(String nome) {
    return CulturaColorsUtils.getColorForName(nome);
  }

  /// Carrega talhões diretamente do banco de dados
  Future<List<dynamic>> _carregarTalhoesDoBanco() async {
    try {
      // Implementação simplificada - retorna lista vazia por enquanto
      // Isso evita dependências circulares
      print('⚠️ CulturaProvider: Carregamento de talhões simplificado');
      return [];
    } catch (e) {
      print('❌ Erro ao carregar talhões: $e');
      return [];
    }
  }
}

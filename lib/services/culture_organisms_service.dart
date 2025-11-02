import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../repositories/talhoes/cultura_fazenda_repository.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../database/app_database.dart';
import 'dart:convert';

class CultureOrganismsService {
  final PestDao _pestDao = PestDao();
  final DiseaseDao _diseaseDao = DiseaseDao();
  final WeedDao _weedDao = WeedDao();
  final CulturaFazendaRepository _culturaFazendaRepository = CulturaFazendaRepository();

  /// Busca pragas por cultura
  Future<List<String>> getPestsByCropId(int cropId) async {
    try {
      final pests = await _pestDao.getByCropId(cropId);
      return pests.map((pest) => pest.name).toList();
    } catch (e) {
      print('❌ Erro ao buscar pragas para cultura $cropId: $e');
      return [];
    }
  }

  /// Busca doenças por cultura
  Future<List<String>> getDiseasesByCropId(int cropId) async {
    try {
      final diseases = await _diseaseDao.getByCropId(cropId);
      return diseases.map((disease) => disease.name).toList();
    } catch (e) {
      print('❌ Erro ao buscar doenças para cultura $cropId: $e');
      return [];
    }
  }

  /// Busca plantas daninhas por cultura
  Future<List<String>> getWeedsByCropId(int cropId) async {
    try {
      final weeds = await _weedDao.getByCropId(cropId);
      return weeds.map((weed) => weed.name).toList();
    } catch (e) {
      print('❌ Erro ao buscar plantas daninhas para cultura $cropId: $e');
      return [];
    }
  }

  /// Busca organismos por tipo e cultura
  Future<List<String>> getOrganismsByTypeAndCrop(String type, int cropId) async {
    switch (type.toLowerCase()) {
      case 'praga':
        return await getPestsByCropId(cropId);
      case 'doença':
        return await getDiseasesByCropId(cropId);
      case 'daninha':
        return await getWeedsByCropId(cropId);
      case 'outro':
        return []; // Para "Outro", retorna lista vazia para permitir entrada manual
      default:
        return [];
    }
  }

  /// Inicializa dados padrão se necessário
  Future<void> initializeDefaultData() async {
    try {
      await _pestDao.insertDefaultPests();
      await _diseaseDao.insertDefaultDiseases();
      await _weedDao.insertDefaultWeeds();
      print('✅ Dados padrão de organismos inicializados');
    } catch (e) {
      print('❌ Erro ao inicializar dados padrão: $e');
    }
  }

  /// Busca organismos baseados na cultura real da fazenda
  Future<List<String>> getOrganismsByFazendaCulture(int talhaoId, String type) async {
    try {
      // Primeiro, tentar obter a cultura real do talhão
      final culturaReal = await _getCulturaRealDoTalhao(talhaoId);
      
      if (culturaReal != null) {
        print('🌱 Cultura real encontrada: ${culturaReal.name}');
        return await _getOrganismsByCultureName(culturaReal.name, type);
      }
      
      // Se não encontrar cultura real, usar dados padrão
      print('⚠️ Cultura real não encontrada, usando dados padrão');
      return await getOrganismsByTypeAndCrop(type, talhaoId);
      
    } catch (e) {
      print('❌ Erro ao buscar organismos por cultura da fazenda: $e');
      // Fallback para dados padrão
      return await getOrganismsByTypeAndCrop(type, talhaoId);
    }
  }

  /// Obtém a cultura real do talhão
  Future<CulturaFazendaModel?> _getCulturaRealDoTalhao(int talhaoId) async {
    try {
      final db = await AppDatabase().database;
      
      // Buscar na tabela de safras do talhão
      final safras = await db.query(
        'talhao_safras',
        where: 'idTalhao = ?',
        whereArgs: [talhaoId.toString()],
        orderBy: 'dataCadastro DESC',
        limit: 1,
      );
      
      if (safras.isNotEmpty) {
        final safra = safras.first;
        final culturaNome = safra['culturaNome'] as String?;
        
        if (culturaNome != null && culturaNome.isNotEmpty) {
          print('🌱 Cultura encontrada na safra: $culturaNome');
          
          // Buscar a cultura na tabela de culturas da fazenda
          final culturas = await _culturaFazendaRepository.buscarCulturasPorFazenda();
          
          // Tentar encontrar correspondência exata primeiro
          try {
            return culturas.firstWhere(
              (c) => c.name.toLowerCase() == culturaNome.toLowerCase(),
            );
          } catch (e) {
            // Se não encontrar correspondência exata, tentar correspondência parcial
            try {
              return culturas.firstWhere(
                (c) => c.name.toLowerCase().contains(culturaNome.toLowerCase()) ||
                       culturaNome.toLowerCase().contains(c.name.toLowerCase()),
              );
            } catch (e) {
              // Se ainda não encontrar, criar cultura temporária
              print('⚠️ Cultura não encontrada na fazenda, criando temporária: $culturaNome');
              return _createCulturaFromName(culturaNome);
            }
          }
        }
      }
      
      // Tentar buscar diretamente na tabela de talhões
      final talhoes = await db.query(
        'talhoes',
        where: 'id = ?',
        whereArgs: [talhaoId.toString()],
        limit: 1,
      );
      
      if (talhoes.isNotEmpty) {
        final talhao = talhoes.first;
        final safrasJson = talhao['safras'] as String?;
        
        if (safrasJson != null && safrasJson.isNotEmpty) {
          try {
            final safrasList = jsonDecode(safrasJson) as List;
            if (safrasList.isNotEmpty) {
              final safraAtual = safrasList.first as Map<String, dynamic>;
              final culturaNome = safraAtual['culturaNome'] as String?;
              
              if (culturaNome != null && culturaNome.isNotEmpty) {
                print('🌱 Cultura encontrada no talhão: $culturaNome');
                return _createCulturaFromName(culturaNome);
              }
            }
          } catch (e) {
            print('❌ Erro ao decodificar safras do talhão: $e');
          }
        }
      }
      
      print('⚠️ Nenhuma cultura encontrada para o talhão $talhaoId');
      return null;
    } catch (e) {
      print('❌ Erro ao obter cultura real do talhão: $e');
      return null;
    }
  }

  /// Cria uma cultura temporária baseada no nome
  CulturaFazendaModel _createCulturaFromName(String nome) {
    return CulturaFazendaModel(
      id: 'temp_${nome.toLowerCase().replaceAll(' ', '_')}',
      idFazenda: 'temp_fazenda',
      name: nome,
      corHex: '#4CAF50', // Verde padrão
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
    );
  }

  /// Busca organismos por nome da cultura
  Future<List<String>> _getOrganismsByCultureName(String culturaNome, String type) async {
    try {
      // Mapear nomes de culturas para IDs padrão
      final culturaLower = culturaNome.toLowerCase();
      int cropId;
      
      if (culturaLower.contains('soja')) {
        cropId = 2;
      } else if (culturaLower.contains('milho')) {
        cropId = 3;
      } else if (culturaLower.contains('algodão') || culturaLower.contains('algodao')) {
        cropId = 4;
      } else if (culturaLower.contains('feijão') || culturaLower.contains('feijao')) {
        cropId = 5;
      } else if (culturaLower.contains('girassol')) {
        cropId = 6;
      } else if (culturaLower.contains('arroz')) {
        cropId = 7;
      } else if (culturaLower.contains('sorgo')) {
        cropId = 8;
      } else if (culturaLower.contains('gergelim')) {
        cropId = 1;
      } else if (culturaLower.contains('trigo')) {
        cropId = 9;
      } else if (culturaLower.contains('aveia')) {
        cropId = 10;
      } else if (culturaLower.contains('café') || culturaLower.contains('cafe')) {
        cropId = 11;
      } else if (culturaLower.contains('cana')) {
        cropId = 12;
      } else if (culturaLower.contains('tomate')) {
        cropId = 13;
      } else if (culturaLower.contains('batata')) {
        cropId = 14;
      } else if (culturaLower.contains('mandioca')) {
        cropId = 15;
      } else {
        // Cultura não reconhecida, usar soja como padrão
        cropId = 2;
        print('⚠️ Cultura não reconhecida: $culturaNome, usando Soja como padrão');
      }
      
      print('🔍 Buscando organismos para $type da cultura $culturaNome (cropId: $cropId)');
      return await getOrganismsByTypeAndCrop(type, cropId);
      
    } catch (e) {
      print('❌ Erro ao buscar organismos por nome da cultura: $e');
      return [];
    }
  }

  /// Busca organismos por ID do talhão (método principal para o monitoramento)
  Future<List<String>> getOrganismsByTalhaoId(int talhaoId, String type) async {
    try {
      print('🔍 Buscando organismos para talhão $talhaoId, tipo: $type');
      
      // Primeiro tentar cultura real da fazenda
      final organismos = await getOrganismsByFazendaCulture(talhaoId, type);
      
      if (organismos.isNotEmpty) {
        print('✅ Encontrados ${organismos.length} organismos da cultura real');
        return organismos;
      }
      
      // Fallback: usar ID do talhão como cropId
      print('⚠️ Usando fallback: ID do talhão como cropId');
      return await getOrganismsByTypeAndCrop(type, talhaoId);
      
    } catch (e) {
      print('❌ Erro ao buscar organismos por ID do talhão: $e');
      return [];
    }
  }

  /// Adiciona organismos personalizados da fazenda
  Future<void> addCustomOrganism(String nome, String tipo, String culturaNome) async {
    try {
      final db = await AppDatabase().database;
      
      // Mapear tipo para tabela
      String tableName;
      String tipoDb;
      switch (tipo.toLowerCase()) {
        case 'praga':
          tableName = 'pests';
          tipoDb = 'Praga';
          break;
        case 'doença':
          tableName = 'diseases';
          tipoDb = 'Doença';
          break;
        case 'daninha':
          tableName = 'weeds';
          tipoDb = 'Daninha';
          break;
        default:
          print('❌ Tipo de organismo não reconhecido: $tipo');
          return;
      }
      
      // Mapear cultura para cropId
      final cropId = _getCropIdFromCultureName(culturaNome);
      
      // Verificar se já existe
      final existing = await db.query(
        tableName,
        where: 'name = ? AND crop_id = ?',
        whereArgs: [nome, cropId],
      );
      
      if (existing.isEmpty) {
        // Inserir novo organismo
        await db.insert(tableName, {
          'name': nome,
          'scientific_name': nome, // Usar nome como científico se não especificado
          'crop_id': cropId,
          'description': 'Organismo personalizado adicionado pelo usuário',
          'is_default': 0, // Marcar como não padrão
          'sync_status': 0,
        });
        
        print('✅ Organismo personalizado adicionado: $nome ($tipoDb) para $culturaNome');
      } else {
        print('⚠️ Organismo já existe: $nome ($tipoDb) para $culturaNome');
      }
    } catch (e) {
      print('❌ Erro ao adicionar organismo personalizado: $e');
    }
  }

  /// Obtém cropId a partir do nome da cultura
  int _getCropIdFromCultureName(String culturaNome) {
    final culturaLower = culturaNome.toLowerCase();
    
    if (culturaLower.contains('soja')) return 2;
    if (culturaLower.contains('milho')) return 3;
    if (culturaLower.contains('algodão') || culturaLower.contains('algodao')) return 4;
    if (culturaLower.contains('feijão') || culturaLower.contains('feijao')) return 5;
    if (culturaLower.contains('girassol')) return 6;
    if (culturaLower.contains('arroz')) return 7;
    if (culturaLower.contains('sorgo')) return 8;
    if (culturaLower.contains('gergelim')) return 1;
    if (culturaLower.contains('trigo')) return 9;
    if (culturaLower.contains('aveia')) return 10;
    if (culturaLower.contains('café') || culturaLower.contains('cafe')) return 11;
    if (culturaLower.contains('cana')) return 12;
    if (culturaLower.contains('tomate')) return 13;
    if (culturaLower.contains('batata')) return 14;
    if (culturaLower.contains('mandioca')) return 15;
    
    return 2; // Soja como padrão
  }
}

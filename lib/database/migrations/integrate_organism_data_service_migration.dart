import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../services/organism_data_service.dart';
import '../../utils/logger.dart';

/// Migração para integrar o novo OrganismDataService com o banco de dados
/// 
/// Esta migração:
/// 1. Atualiza a tabela organism_catalog com novos campos
/// 2. Sincroniza dados do OrganismDataService para o banco
/// 3. Cria índices para performance
/// 4. Valida integridade dos dados
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

class IntegrateOrganismDataServiceMigration {
  static const String _tag = 'IntegrateOrganismDataServiceMigration';
  static const int _version = 1;

  /// Executa a migração completa
  static Future<void> execute(Database db) async {
    Logger.info('$_tag: Iniciando migração para integrar OrganismDataService...');
    
    try {
      // 1. Atualizar estrutura da tabela
      await _updateOrganismCatalogTable(db);
      
      // 2. Sincronizar dados do OrganismDataService
      await _syncOrganismDataService(db);
      
      // 3. Criar índices para performance
      await _createPerformanceIndexes(db);
      
      // 4. Validar integridade
      await _validateDataIntegrity(db);
      
      Logger.info('$_tag: ✅ Migração concluída com sucesso');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na migração: $e');
      rethrow;
    }
  }

  /// Atualiza a estrutura da tabela organism_catalog
  static Future<void> _updateOrganismCatalogTable(Database db) async {
    Logger.info('$_tag: Atualizando estrutura da tabela organism_catalog...');
    
    try {
      // Verificar se a tabela existe
      final tableInfo = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='organism_catalog'"
      );
      
      if (tableInfo.isEmpty) {
        Logger.info('$_tag: Tabela organism_catalog não existe, criando...');
        await _createOrganismCatalogTable(db);
        return;
      }
      
      // Verificar colunas existentes
      final columns = await db.rawQuery("PRAGMA table_info(organism_catalog)");
      final existingColumns = columns.map((col) => col['name'] as String).toSet();
      
      // Adicionar novas colunas se não existirem
      final newColumns = [
        'sintomas TEXT',
        'dano_economico TEXT',
        'partes_afetadas TEXT',
        'fenologia TEXT',
        'nivel_acao TEXT',
        'fases_fenologicas_detalhadas TEXT',
        'severidade TEXT',
        'niveis_infestacao TEXT',
        'manejo_quimico TEXT',
        'manejo_biologico TEXT',
        'manejo_cultural TEXT',
        'condicoes_favoraveis TEXT',
        'limiares_especificos TEXT',
        'manejo_avancado TEXT',
        'sintomas_detalhados TEXT',
        'fases TEXT',
        'codigos_resistencia TEXT',
        'periodo_carencia TEXT',
        'eficacia_por_fase TEXT',
        'metodo_monitoramento TEXT',
        'observacoes TEXT',
        'icone TEXT',
        'data_criacao DATETIME',
        'data_atualizacao DATETIME',
      ];
      
      for (final columnDef in newColumns) {
        final columnName = columnDef.split(' ')[0];
        if (!existingColumns.contains(columnName)) {
          Logger.info('$_tag: Adicionando coluna $columnName...');
          await db.execute('ALTER TABLE organism_catalog ADD COLUMN $columnDef');
        }
      }
      
      Logger.info('$_tag: ✅ Estrutura da tabela atualizada');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao atualizar tabela: $e');
      rethrow;
    }
  }

  /// Cria a tabela organism_catalog do zero
  static Future<void> _createOrganismCatalogTable(Database db) async {
    await db.execute('''
      CREATE TABLE organism_catalog (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        nome_cientifico TEXT,
        tipo TEXT NOT NULL CHECK (tipo IN ('pest', 'disease', 'weed', 'deficiency', 'other')),
        categoria TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        cultura_nome TEXT NOT NULL,
        unidade TEXT NOT NULL,
        base_denominador INTEGER DEFAULT 1,
        limiar_baixo REAL DEFAULT 0,
        limiar_medio REAL DEFAULT 0,
        limiar_alto REAL DEFAULT 0,
        limiar_critico REAL DEFAULT 0,
        descricao TEXT,
        imagem_url TEXT,
        ativo INTEGER DEFAULT 1,
        version TEXT NOT NULL,
        
        -- Novos campos do OrganismDataService
        sintomas TEXT,
        dano_economico TEXT,
        partes_afetadas TEXT,
        fenologia TEXT,
        nivel_acao TEXT,
        fases_fenologicas_detalhadas TEXT,
        severidade TEXT,
        niveis_infestacao TEXT,
        manejo_quimico TEXT,
        manejo_biologico TEXT,
        manejo_cultural TEXT,
        condicoes_favoraveis TEXT,
        limiares_especificos TEXT,
        manejo_avancado TEXT,
        sintomas_detalhados TEXT,
        fases TEXT,
        codigos_resistencia TEXT,
        periodo_carencia TEXT,
        eficacia_por_fase TEXT,
        metodo_monitoramento TEXT,
        observacoes TEXT,
        icone TEXT,
        data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
        data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP,
        
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(nome, cultura_id, version)
      )
    ''');
  }

  /// Sincroniza dados do OrganismDataService para o banco
  static Future<void> _syncOrganismDataService(Database db) async {
    Logger.info('$_tag: Sincronizando dados do OrganismDataService...');
    
    try {
      final service = OrganismDataService();
      await service.initialize();
      
      final cultures = service.getAllCultures();
      int totalSynced = 0;
      
      for (final culture in cultures) {
        Logger.info('$_tag: Sincronizando cultura ${culture.name}...');
        
        for (final organism in culture.organisms) {
          await _syncOrganismToDatabase(db, organism);
          totalSynced++;
        }
      }
      
      Logger.info('$_tag: ✅ Sincronizados $totalSynced organismos');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao sincronizar dados: $e');
      rethrow;
    }
  }

  /// Sincroniza um organismo específico para o banco
  static Future<void> _syncOrganismToDatabase(Database db, OrganismData organism) async {
    try {
      // Verificar se o organismo já existe
      final existing = await db.query(
        'organism_catalog',
        where: 'id = ?',
        whereArgs: [organism.id],
      );
      
      final organismData = {
        'id': organism.id,
        'nome': organism.name,
        'nome_cientifico': organism.scientificName,
        'tipo': _getOrganismType(organism.category),
        'categoria': organism.category,
        'cultura_id': organism.cultureId,
        'cultura_nome': organism.cultureName,
        'unidade': _getDefaultUnit(organism.category),
        'base_denominador': 1,
        'limiar_baixo': _extractThreshold(organism.actionThreshold, 'baixo'),
        'limiar_medio': _extractThreshold(organism.actionThreshold, 'medio'),
        'limiar_alto': _extractThreshold(organism.actionThreshold, 'alto'),
        'limiar_critico': _extractThreshold(organism.actionThreshold, 'critico'),
        'descricao': organism.economicDamage,
        'ativo': organism.active ? 1 : 0,
        'version': '4.0',
        
        // Novos campos
        'sintomas': organism.symptoms.join('; '),
        'dano_economico': organism.economicDamage,
        'partes_afetadas': organism.affectedParts.join('; '),
        'fenologia': organism.phenology.join('; '),
        'nivel_acao': organism.actionThreshold,
        'fases_fenologicas_detalhadas': organism.detailedPhenology != null 
            ? _jsonEncode(organism.detailedPhenology!) : null,
        'severidade': organism.severityLevels != null 
            ? _jsonEncode(organism.severityLevels!) : null,
        'niveis_infestacao': organism.infestationLevels != null 
            ? _jsonEncode(organism.infestationLevels!) : null,
        'manejo_quimico': organism.chemicalManagement.join('; '),
        'manejo_biologico': organism.biologicalManagement.join('; '),
        'manejo_cultural': organism.culturalManagement.join('; '),
        'condicoes_favoraveis': organism.favorableConditions != null 
            ? _jsonEncode(organism.favorableConditions!) : null,
        'limiares_especificos': organism.specificThresholds != null 
            ? _jsonEncode(organism.specificThresholds!) : null,
        'manejo_avancado': organism.advancedManagement != null 
            ? _jsonEncode(organism.advancedManagement!) : null,
        'sintomas_detalhados': organism.detailedSymptoms != null 
            ? _jsonEncode(organism.detailedSymptoms!) : null,
        'fases': organism.lifeStages != null 
            ? _jsonEncode(organism.lifeStages!) : null,
        'codigos_resistencia': organism.resistanceCodes != null 
            ? _jsonEncode(organism.resistanceCodes!) : null,
        'periodo_carencia': organism.safetyPeriod,
        'eficacia_por_fase': organism.efficacyByPhase != null 
            ? _jsonEncode(organism.efficacyByPhase!) : null,
        'metodo_monitoramento': organism.monitoringMethod,
        'observacoes': organism.observations,
        'icone': organism.icon,
        'data_criacao': organism.createdAt.toIso8601String(),
        'data_atualizacao': organism.updatedAt.toIso8601String(),
        
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (existing.isEmpty) {
        // Inserir novo organismo
        organismData['created_at'] = DateTime.now().toIso8601String();
        await db.insert('organism_catalog', organismData);
      } else {
        // Atualizar organismo existente
        await db.update(
          'organism_catalog',
          organismData,
          where: 'id = ?',
          whereArgs: [organism.id],
        );
      }
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao sincronizar organismo ${organism.id}: $e');
      rethrow;
    }
  }

  /// Cria índices para performance
  static Future<void> _createPerformanceIndexes(Database db) async {
    Logger.info('$_tag: Criando índices para performance...');
    
    try {
      final indexes = [
        'CREATE INDEX IF NOT EXISTS idx_catalog_cultura ON organism_catalog(cultura_id)',
        'CREATE INDEX IF NOT EXISTS idx_catalog_tipo ON organism_catalog(tipo)',
        'CREATE INDEX IF NOT EXISTS idx_catalog_categoria ON organism_catalog(categoria)',
        'CREATE INDEX IF NOT EXISTS idx_catalog_version ON organism_catalog(version)',
        'CREATE INDEX IF NOT EXISTS idx_catalog_ativo ON organism_catalog(ativo)',
        'CREATE INDEX IF NOT EXISTS idx_catalog_nome ON organism_catalog(nome)',
        'CREATE INDEX IF NOT EXISTS idx_catalog_nome_cientifico ON organism_catalog(nome_cientifico)',
        'CREATE INDEX IF NOT EXISTS idx_catalog_data_atualizacao ON organism_catalog(data_atualizacao)',
      ];
      
      for (final index in indexes) {
        await db.execute(index);
      }
      
      Logger.info('$_tag: ✅ Índices criados');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao criar índices: $e');
      rethrow;
    }
  }

  /// Valida integridade dos dados
  static Future<void> _validateDataIntegrity(Database db) async {
    Logger.info('$_tag: Validando integridade dos dados...');
    
    try {
      // Verificar organismos duplicados
      final duplicates = await db.rawQuery('''
        SELECT id, COUNT(*) as count 
        FROM organism_catalog 
        GROUP BY id 
        HAVING COUNT(*) > 1
      ''');
      
      if (duplicates.isNotEmpty) {
        Logger.warning('$_tag: ⚠️ Encontrados ${duplicates.length} organismos duplicados');
        for (final duplicate in duplicates) {
          Logger.warning('$_tag:   - ${duplicate['id']}: ${duplicate['count']} ocorrências');
        }
      }
      
      // Verificar organismos sem nome
      final noName = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM organism_catalog 
        WHERE nome IS NULL OR nome = ''
      ''');
      
      if (noName.first['count'] as int > 0) {
        Logger.warning('$_tag: ⚠️ Encontrados ${noName.first['count']} organismos sem nome');
      }
      
      // Verificar organismos sem cultura
      final noCulture = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM organism_catalog 
        WHERE cultura_id IS NULL OR cultura_id = ''
      ''');
      
      if (noCulture.first['count'] as int > 0) {
        Logger.warning('$_tag: ⚠️ Encontrados ${noCulture.first['count']} organismos sem cultura');
      }
      
      // Estatísticas finais
      final totalOrganisms = await db.rawQuery('SELECT COUNT(*) as count FROM organism_catalog');
      final activeOrganisms = await db.rawQuery('SELECT COUNT(*) as count FROM organism_catalog WHERE ativo = 1');
      
      Logger.info('$_tag: 📊 Estatísticas finais:');
      Logger.info('$_tag:   Total de organismos: ${totalOrganisms.first['count']}');
      Logger.info('$_tag:   Organismos ativos: ${activeOrganisms.first['count']}');
      
      Logger.info('$_tag: ✅ Validação de integridade concluída');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na validação: $e');
      rethrow;
    }
  }

  /// Determina tipo de organismo
  static String _getOrganismType(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'pest';
    if (cat.contains('doença') || cat.contains('doenca')) return 'disease';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return 'deficiency';
    return 'other';
  }

  /// Obtém unidade padrão para categoria
  static String _getDefaultUnit(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'unidades/ponto';
    if (cat.contains('doença') || cat.contains('doenca')) return '% de incidência';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return '% de severidade';
    return 'unidades';
  }

  /// Extrai limiar específico do texto
  static double _extractThreshold(String? thresholdText, String level) {
    if (thresholdText == null || thresholdText.isEmpty) return 0.0;
    
    // Implementar lógica para extrair limiares específicos
    // Por enquanto, retorna valores padrão
    switch (level) {
      case 'baixo': return 1.0;
      case 'medio': return 3.0;
      case 'alto': return 5.0;
      case 'critico': return 10.0;
      default: return 0.0;
    }
  }

  /// Codifica objeto para JSON
  static String? _jsonEncode(dynamic obj) {
    try {
      return obj.toString(); // Simplificado para este exemplo
    } catch (e) {
      return null;
    }
  }
}

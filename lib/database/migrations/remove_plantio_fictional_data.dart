import 'package:sqflite/sqflite.dart';

/// 🔧 MIGRAÇÃO CRÍTICA - Remove dados fictícios da tabela plantio
/// 
/// ❌ PROBLEMA IDENTIFICADO:
/// A tabela plantio estava salvando dados FICTÍCIOS de:
/// - populacao_por_m (população por metro)
/// - espacamento_cm (espaçamento)
/// 
/// ✅ SOLUÇÃO:
/// Esses dados agora vêm APENAS do submódulo "Novo Estande de Plantas"
/// O plantio registra APENAS:
/// - Talhão
/// - Cultura
/// - Variedade
/// - Data de plantio
/// - Hectares (opcional, quando tiver múltiplas variedades)
/// 
/// 📊 DADOS REAIS agora vêm de:
/// - População Real → estande_plantas (plantasPorHectare)
/// - Espaçamento → estande_plantas (espacamento)
/// - CV% → planting_cv (coeficienteVariacao)
/// - Profundidade → (será adicionada no CV%)

class RemovePlantioFictionalData {
  static Future<void> migrate(Database db) async {
    print('🔄 MIGRAÇÃO: Removendo dados fictícios da tabela plantio...');
    
    try {
      // 1️⃣ Verificar se as colunas existem
      final tableInfo = await db.rawQuery('PRAGMA table_info(plantio)');
      final colunas = tableInfo.map((row) => row['name'] as String).toList();
      
      print('📋 Colunas atuais da tabela plantio: $colunas');
      
      final temPopulacao = colunas.contains('populacao_por_m');
      final temEspacamento = colunas.contains('espacamento_cm');
      
      if (!temPopulacao && !temEspacamento) {
        print('✅ Tabela plantio já está correta (sem dados fictícios)');
        return;
      }
      
      print('⚠️ Encontradas colunas fictícias:');
      if (temPopulacao) print('   - populacao_por_m');
      if (temEspacamento) print('   - espacamento_cm');
      
      // 2️⃣ Criar tabela temporária com estrutura correta
      await db.execute('''
        CREATE TABLE IF NOT EXISTS plantio_new (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          subarea_id TEXT,
          cultura TEXT NOT NULL,
          variedade TEXT NOT NULL,
          data_plantio TEXT NOT NULL,
          hectares REAL,
          observacao TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT
        )
      ''');
      
      print('✅ Tabela plantio_new criada');
      
      // 3️⃣ Copiar dados (apenas campos válidos)
      await db.execute('''
        INSERT INTO plantio_new (
          id, talhao_id, subarea_id, cultura, variedade, 
          data_plantio, observacao, created_at, updated_at, deleted_at
        )
        SELECT 
          id, talhao_id, subarea_id, cultura, variedade,
          data_plantio, observacao, created_at, updated_at, deleted_at
        FROM plantio
      ''');
      
      print('✅ Dados copiados (${await db.rawQuery('SELECT COUNT(*) as count FROM plantio_new')})');
      
      // 4️⃣ Remover tabela antiga
      await db.execute('DROP TABLE IF EXISTS plantio');
      print('✅ Tabela antiga removida');
      
      // 5️⃣ Renomear nova tabela
      await db.execute('ALTER TABLE plantio_new RENAME TO plantio');
      print('✅ Tabela renomeada');
      
      // 6️⃣ Recriar índices
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_talhao_id ON plantio (talhao_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_cultura ON plantio (cultura)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_data_plantio ON plantio (data_plantio)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_deleted_at ON plantio (deleted_at)');
      
      print('✅ Índices recriados');
      
      // 7️⃣ Verificar estrutura final
      final newTableInfo = await db.rawQuery('PRAGMA table_info(plantio)');
      final newColunas = newTableInfo.map((row) => row['name'] as String).toList();
      
      print('📋 Nova estrutura da tabela plantio: $newColunas');
      print('✅ MIGRAÇÃO CONCLUÍDA: Dados fictícios removidos!');
      print('');
      print('🎯 AGORA OS DADOS REAIS VÊM DE:');
      print('   📊 População → estande_plantas.plantasPorHectare');
      print('   📏 Espaçamento → estande_plantas.espacamento');
      print('   📈 CV% → planting_cv.coeficienteVariacao');
      print('');
      
    } catch (e) {
      print('❌ ERRO na migração: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}


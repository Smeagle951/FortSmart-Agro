import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../repositories/talhoes/talhao_safra_repository.dart';
import '../services/talhao_unified_service.dart';
import '../utils/logger.dart';

/// Serviço específico para diagnosticar problemas com a área dos talhões
class TalhaoAreaDiagnosticService {
  final AppDatabase _appDatabase = AppDatabase();
  final TalhaoSafraRepository _talhaoSafraRepository = TalhaoSafraRepository();
  final TalhaoUnifiedService _talhaoUnifiedService = TalhaoUnifiedService();

  /// Executa diagnóstico específico da área dos talhões
  Future<Map<String, dynamic>> executarDiagnosticoArea() async {
    Logger.info('🔍 Iniciando diagnóstico específico da área dos talhões...');
    
    final resultado = <String, dynamic>{};
    
    try {
      // 1. Verificar dados brutos no banco
      resultado['dados_brutos'] = await _verificarDadosBrutos();
      
      // 2. Verificar conversão via serviço unificado
      resultado['servico_unificado'] = await _verificarServicoUnificado();
      
      // 3. Verificar conversão via repositório direto
      resultado['repositorio_direto'] = await _verificarRepositorioDireto();
      
      // 4. Verificar estrutura dos modelos
      resultado['estrutura_modelos'] = await _verificarEstruturaModelos();
      
      Logger.info('✅ Diagnóstico da área concluído');
    } catch (e) {
      Logger.error('❌ Erro durante diagnóstico da área: $e');
      resultado['erro'] = e.toString();
    }
    
    return resultado;
  }

  /// Verifica dados brutos no banco de dados
  Future<Map<String, dynamic>> _verificarDadosBrutos() async {
    Logger.info('🔍 Verificando dados brutos no banco...');
    
    try {
      final db = await _appDatabase.database;
      final resultado = <String, dynamic>{};
      
      // Verificar tabela talhao_safra
      try {
        final talhoes = await db.query('talhao_safra');
        resultado['talhao_safra'] = {
          'total': talhoes.length,
          'campos_area': talhoes.map((t) => {
            'id': t['id'],
            'nome': t['name'],
            'area': t['area'],
            'tipo_area': t['area']?.runtimeType.toString(),
          }).toList(),
        };
        Logger.info('📊 Tabela talhao_safra: ${talhoes.length} registros');
      } catch (e) {
        resultado['talhao_safra'] = {'erro': e.toString()};
        Logger.warning('⚠️ Erro ao consultar talhao_safra: $e');
      }
      
      // Verificar tabela safra_talhao
      try {
        final safras = await db.query('safra_talhao');
        resultado['safra_talhao'] = {
          'total': safras.length,
          'campos_area': safras.map((s) => {
            'id': s['id'],
            'talhao_id': s['idTalhao'],
            'area': s['area'],
            'tipo_area': s['area']?.runtimeType.toString(),
          }).toList(),
        };
        Logger.info('📊 Tabela safra_talhao: ${safras.length} registros');
      } catch (e) {
        resultado['safra_talhao'] = {'erro': e.toString()};
        Logger.warning('⚠️ Erro ao consultar safra_talhao: $e');
      }
      
      // Verificar tabela talhao_poligono
      try {
        final poligonos = await db.query('talhao_poligono');
        resultado['talhao_poligono'] = {
          'total': poligonos.length,
          'campos_area': poligonos.map((p) => {
            'id': p['id'],
            'talhao_id': p['idTalhao'],
            'area': p['area'],
            'tipo_area': p['area']?.runtimeType.toString(),
          }).toList(),
        };
        Logger.info('📊 Tabela talhao_poligono: ${poligonos.length} registros');
      } catch (e) {
        resultado['talhao_poligono'] = {'erro': e.toString()};
        Logger.warning('⚠️ Erro ao consultar talhao_poligono: $e');
      }
      
      return resultado;
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados brutos: $e');
      return {'erro': e.toString()};
    }
  }

  /// Verifica o serviço unificado
  Future<Map<String, dynamic>> _verificarServicoUnificado() async {
    Logger.info('🔍 Verificando serviço unificado...');
    
    try {
      final resultado = <String, dynamic>{};
      
      // Tentar carregar talhões via serviço unificado
      try {
        final talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
          nomeModulo: 'DIAGNOSTICO_AREA',
          forceRefresh: true,
        );
        
        resultado['talhoes_carregados'] = {
          'total': talhoes.length,
          'detalhes_area': talhoes.map((t) => {
            'id': t.id,
            'nome': t.name,
            'area': t.area,
            'tipo_area': t.area.runtimeType.toString(),
            'poligonos': t.poligonos.map((p) => {
              'id': p.id,
              'area': p.area,
              'tipo_area': p.area.runtimeType.toString(),
            }).toList(),
            'safras': t.safras.map((s) => {
              'id': s.id,
              'nome': s.nome,
              'area': s.dataInicio != null ? 'N/A' : 'N/A',
            }).toList(),
          }).toList(),
        };
        
        Logger.info('📊 Talhões carregados via serviço unificado: ${talhoes.length}');
      } catch (e) {
        resultado['erro_carregamento'] = e.toString();
        Logger.error('❌ Erro ao carregar talhões via serviço unificado: $e');
      }
      
      return resultado;
    } catch (e) {
      Logger.error('❌ Erro ao verificar serviço unificado: $e');
      return {'erro': e.toString()};
    }
  }

  /// Verifica o repositório direto
  Future<Map<String, dynamic>> _verificarRepositorioDireto() async {
    Logger.info('🔍 Verificando repositório direto...');
    
    try {
      final resultado = <String, dynamic>{};
      
      // Tentar carregar via repositório direto
      try {
        final talhoesSafra = await _talhaoSafraRepository.forcarAtualizacaoTalhoes();
        
        resultado['talhoes_repositorio'] = {
          'total': talhoesSafra.length,
          'detalhes_area': talhoesSafra.map((t) => {
            'id': t.id,
            'nome': t.name,
            'area': t.area,
            'tipo_area': t.area?.runtimeType.toString(),
            'poligonos': t.poligonos.map((p) => {
              'id': p.id,
              'area': p.area,
              'tipo_area': p.area.runtimeType.toString(),
            }).toList(),
            'safras': t.safras.map((s) => {
              'id': s.id,
              'area': s.area,
              'tipo_area': s.area.runtimeType.toString(),
            }).toList(),
          }).toList(),
        };
        
        Logger.info('📊 Talhões carregados via repositório direto: ${talhoesSafra.length}');
      } catch (e) {
        resultado['erro_repositorio'] = e.toString();
        Logger.error('❌ Erro ao carregar via repositório direto: $e');
      }
      
      return resultado;
    } catch (e) {
      Logger.error('❌ Erro ao verificar repositório direto: $e');
      return {'erro': e.toString()};
    }
  }

  /// Verifica a estrutura dos modelos
  Future<Map<String, dynamic>> _verificarEstruturaModelos() async {
    Logger.info('🔍 Verificando estrutura dos modelos...');
    
    try {
      final resultado = <String, dynamic>{};
      
      // Verificar estrutura do TalhaoModel
      resultado['talhao_model'] = {
        'campos_area': [
          'area (double?)',
          'poligonos[].area (double)',
        ],
        'exemplo': {
          'area': 0.0,
          'poligonos_area': [0.0],
        },
      };
      
      // Verificar estrutura do TalhaoSafraModel
      resultado['talhao_safra_model'] = {
        'campos_area': [
          'area (double?)',
          'poligonos[].area (double)',
          'safras[].area (double)',
        ],
        'exemplo': {
          'area': 0.0,
          'poligonos_area': [0.0],
          'safras_area': [0.0],
        },
      };
      
      // Verificar estrutura do SafraModel
      resultado['safra_model'] = {
        'campos_area': [
          'dataInicio (DateTime) - usado para área',
        ],
        'exemplo': {
          'dataInicio': DateTime.now(),
        },
      };
      
      return resultado;
    } catch (e) {
      Logger.error('❌ Erro ao verificar estrutura dos modelos: $e');
      return {'erro': e.toString()};
    }
  }

  /// Gera relatório específico da área
  Future<String> gerarRelatorioArea() async {
    Logger.info('📋 Gerando relatório específico da área...');
    
    try {
      final diagnostico = await executarDiagnosticoArea();
      
      final buffer = StringBuffer();
      buffer.writeln('🔍 RELATÓRIO DE DIAGNÓSTICO DA ÁREA DOS TALHÕES');
      buffer.writeln('==================================================');
      buffer.writeln('Data: ${DateTime.now()}');
      buffer.writeln('');
      
      // Dados brutos
      buffer.writeln('💾 DADOS BRUTOS NO BANCO:');
      if (diagnostico['dados_brutos'] != null) {
        final dados = diagnostico['dados_brutos'] as Map<String, dynamic>;
        for (final entry in dados.entries) {
          if (entry.value is Map<String, dynamic>) {
            final info = entry.value as Map<String, dynamic>;
            if (info.containsKey('total')) {
              buffer.writeln('  ${entry.key}: ${info['total']} registros');
              
              if (info.containsKey('campos_area')) {
                final camposArea = info['campos_area'] as List;
                for (int i = 0; i < camposArea.length && i < 3; i++) {
                  final campo = camposArea[i] as Map<String, dynamic>;
                  buffer.writeln('    ${i + 1}. ID: ${campo['id']} - Área: ${campo['area']} (${campo['tipo_area']})');
                }
              }
            } else if (info.containsKey('erro')) {
              buffer.writeln('  ${entry.key}: ❌ ${info['erro']}');
            }
          }
        }
      }
      buffer.writeln('');
      
      // Serviço unificado
      buffer.writeln('🔄 SERVIÇO UNIFICADO:');
      if (diagnostico['servico_unificado'] != null) {
        final servico = diagnostico['servico_unificado'] as Map<String, dynamic>;
        
        if (servico['talhoes_carregados'] != null) {
          final talhoes = servico['talhoes_carregados'] as Map<String, dynamic>;
          buffer.writeln('  Talhões carregados: ${talhoes['total']}');
          
          if (talhoes.containsKey('detalhes_area')) {
            final detalhes = talhoes['detalhes_area'] as List;
            for (int i = 0; i < detalhes.length && i < 3; i++) {
              final talhao = detalhes[i] as Map<String, dynamic>;
              buffer.writeln('    ${i + 1}. ${talhao['nome']} - Área: ${talhao['area']} (${talhao['tipo_area']})');
            }
          }
        }
      }
      buffer.writeln('');
      
      // Repositório direto
      buffer.writeln('🔄 REPOSITÓRIO DIRETO:');
      if (diagnostico['repositorio_direto'] != null) {
        final repositorio = diagnostico['repositorio_direto'] as Map<String, dynamic>;
        
        if (repositorio['talhoes_repositorio'] != null) {
          final talhoes = repositorio['talhoes_repositorio'] as Map<String, dynamic>;
          buffer.writeln('  Talhões carregados: ${talhoes['total']}');
          
          if (talhoes.containsKey('detalhes_area')) {
            final detalhes = talhoes['detalhes_area'] as List;
            for (int i = 0; i < detalhes.length && i < 3; i++) {
              final talhao = detalhes[i] as Map<String, dynamic>;
              buffer.writeln('    ${i + 1}. ${talhao['nome']} - Área: ${talhao['area']} (${talhao['tipo_area']})');
            }
          }
        }
      }
      buffer.writeln('');
      
      // Estrutura dos modelos
      buffer.writeln('🏗️ ESTRUTURA DOS MODELOS:');
      if (diagnostico['estrutura_modelos'] != null) {
        final estrutura = diagnostico['estrutura_modelos'] as Map<String, dynamic>;
        
        for (final entry in estrutura.entries) {
          buffer.writeln('  ${entry.key}:');
          if (entry.value is Map<String, dynamic>) {
            final modelo = entry.value as Map<String, dynamic>;
            if (modelo.containsKey('campos_area')) {
              final campos = modelo['campos_area'] as List;
              for (final campo in campos) {
                buffer.writeln('    - $campo');
              }
            }
          }
        }
      }
      
      final relatorio = buffer.toString();
      Logger.info('✅ Relatório da área gerado com sucesso');
      
      return relatorio;
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório da área: $e');
      return '❌ Erro ao gerar relatório da área: $e';
    }
  }
}

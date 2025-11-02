import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../models/export_job_model.dart';
import '../models/import_job_model.dart';
import '../daos/export_job_dao.dart';
import '../daos/import_job_dao.dart';
import '../../../models/talhao_model.dart';
import '../../../models/produto_estoque.dart';
import '../../../modules/prescription/models/prescription_model.dart';
import '../../../database/daos/plot_dao.dart';
import '../../../database/daos/produto_estoque_dao.dart';
import '../../../modules/prescription/daos/prescription_dao.dart';
import '../../../utils/logger.dart';

class ImportExportService {
  static final ImportExportService _instance = ImportExportService._internal();
  factory ImportExportService() => _instance;
  ImportExportService._internal();

  final ExportJobDao _exportDao = ExportJobDao();
  final ImportJobDao _importDao = ImportJobDao();
  final PlotDao _plotDao = PlotDao();
  final ProdutoEstoqueDao _produtoDao = ProdutoEstoqueDao();
  final PrescriptionDao _prescriptionDao = PrescriptionDao();
  final Uuid _uuid = Uuid();

  // ===== EXPORTAÇÃO =====

  Future<Map<String, dynamic>> exportarDados({
    required String tipo,
    required String formato,
    required Map<String, dynamic> filtros,
    String? usuarioId,
  }) async {
    try {
      Logger.info('Iniciando exportação: $tipo em formato $formato');

      // Criar job de exportação
      final job = ExportJobModel(
        tipo: tipo,
        formato: formato,
        filtros: json.encode(filtros),
        status: 'pendente',
        dataCriacao: DateTime.now(),
        usuarioId: usuarioId,
      );

      final jobId = await _exportDao.insert(job);
      Logger.info('Job de exportação criado: $jobId');

      // Processar exportação
      final resultado = await _processarExportacao(job.copyWith(id: jobId), filtros);
      
      // Atualizar job com resultado
      await _exportDao.updateStatus(
        jobId,
        resultado['sucesso'] ? 'concluido' : 'erro',
        arquivoPath: resultado['arquivo_path'],
        observacoes: resultado['observacoes'],
      );

      return resultado;
    } catch (e) {
      Logger.error('Erro na exportação: $e');
      return {
        'sucesso': false,
        'erro': e.toString(),
        'arquivo_path': null,
      };
    }
  }

  Future<Map<String, dynamic>> _processarExportacao(
    ExportJobModel job,
    Map<String, dynamic> filtros,
  ) async {
    try {
      List<Map<String, dynamic>> dados = [];

      switch (job.tipo) {
        case 'talhoes':
          dados = await _exportarTalhoes(filtros);
          break;
        case 'custos':
          dados = await _exportarCustos(filtros);
          break;
        case 'prescricoes':
          dados = await _exportarPrescricoes(filtros);
          break;
        default:
          throw Exception('Tipo de exportação não suportado: ${job.tipo}');
      }

      if (dados.isEmpty) {
        return {
          'sucesso': true,
          'arquivo_path': null,
          'observacoes': 'Nenhum dado encontrado para os filtros aplicados',
          'total_registros': 0,
        };
      }

      // Gerar arquivo
      final arquivoPath = await _gerarArquivo(dados, job.formato, job.tipo);
      final tamanhoArquivo = await _calcularTamanhoArquivo(arquivoPath);

      return {
        'sucesso': true,
        'arquivo_path': arquivoPath,
        'observacoes': 'Exportação concluída com sucesso',
        'total_registros': dados.length,
        'tamanho_arquivo': tamanhoArquivo,
      };
    } catch (e) {
      Logger.error('Erro no processamento da exportação: $e');
      return {
        'sucesso': false,
        'erro': e.toString(),
        'arquivo_path': null,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _exportarTalhoes(Map<String, dynamic> filtros) async {
    final talhoes = await _plotDao.getAll();
    
    return talhoes.map((talhao) => {
      'id': talhao.id,
      'nome': talhao.name,
      'area_ha': talhao.area,
      'cultura': talhao.cropName ?? '',
      'safra': talhao.safraInfo ?? '',
      'data_criacao': talhao.createdAt,
      'coordenadas': talhao.getCoordinates().map((p) => {'lat': p['latitude'], 'lng': p['longitude']}).toList(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportarCustos(Map<String, dynamic> filtros) async {
    // Implementar exportação de custos baseada no módulo de gestão de custos
    // Por enquanto, retornar dados de exemplo
    return [
      {
        'talhao_id': 'talhao_001',
        'talhao_nome': 'Talhão 1',
        'tipo_operacao': 'aplicacao',
        'data': DateTime.now().toIso8601String(),
        'custo_total': 1500.0,
        'custo_por_ha': 60.0,
        'produtos': [
          {'nome': 'Herbicida A', 'quantidade': 10.0, 'custo': 500.0},
          {'nome': 'Fertilizante B', 'quantidade': 50.0, 'custo': 1000.0},
        ],
      }
    ];
  }

  Future<List<Map<String, dynamic>>> _exportarPrescricoes(Map<String, dynamic> filtros) async {
    final prescricoes = await _prescriptionDao.getAll();
    
    return prescricoes.map((prescricao) => {
      'id': prescricao.id,
      'talhao_id': prescricao.talhaoId,
      'talhao_nome': prescricao.talhaoNome,
      'area_ha': prescricao.areaTalhao,
      'tipo_aplicacao': prescricao.tipoAplicacao.name,
      'equipamento': prescricao.equipamento ?? '',
      'capacidade_tanque': prescricao.capacidadeTanque,
      'vazao_por_hectare': prescricao.vazaoPorHectare,
      'volume_total_calda': prescricao.volumeTotalCalda,
      'numero_tanques': prescricao.numeroTanques,
      'custo_total': prescricao.custoTotal,
      'custo_por_hectare': prescricao.custoPorHectare,
      'status': prescricao.status.name,
      'data_prescricao': prescricao.dataPrescricao.toIso8601String(),
      'operador': prescricao.operador,
      'produtos': prescricao.produtos.map((p) => {
        'nome': p.nome,
        'tipo': p.tipo.name,
        'dose_por_ha': p.dosePorHectare,
        'unidade': p.unidade,
        'total_necessario': p.totalNecessario,
        'custo_total': p.custoTotal,
      }).toList(),
    }).toList();
  }

  Future<String> _gerarArquivo(
    List<Map<String, dynamic>> dados,
    String formato,
    String tipo,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${tipo}_export_$timestamp';
    
    String filePath;
    String content;

    switch (formato.toLowerCase()) {
      case 'json':
        filePath = path.join(directory.path, '$fileName.json');
        content = json.encode(dados, toEncodable: (obj) {
          if (obj is DateTime) return obj.toIso8601String();
          return obj;
        });
        await File(filePath).writeAsString(content);
        break;

      case 'csv':
        filePath = path.join(directory.path, '$fileName.csv');
        final csvData = _converterParaCSV(dados);
        await File(filePath).writeAsString(csvData);
        break;

      case 'xlsx':
        filePath = path.join(directory.path, '$fileName.xlsx');
        await _gerarExcel(dados, filePath);
        break;

      default:
        throw Exception('Formato não suportado: $formato');
    }

    Logger.info('Arquivo gerado: $filePath');
    return filePath;
  }

  String _converterParaCSV(List<Map<String, dynamic>> dados) {
    if (dados.isEmpty) return '';

    final headers = dados.first.keys.toList();
    final csvData = <List<dynamic>>[headers];

    for (final row in dados) {
      final csvRow = headers.map((header) {
        final value = row[header];
        if (value is List) {
          return json.encode(value);
        }
        return value?.toString() ?? '';
      }).toList();
      csvData.add(csvRow);
    }

    // Converter para CSV string
    final csvString = csvData.map((row) => row.join(',')).join('\n');
    return csvString;
  }

  Future<void> _gerarExcel(List<Map<String, dynamic>> dados, String filePath) async {
    final excel = Excel.createExcel();
    final sheet = excel['Dados'];

    if (dados.isNotEmpty) {
      final headers = dados.first.keys.toList();
      
      // Adicionar cabeçalhos
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = headers[i];
      }

      // Adicionar dados
      for (int rowIndex = 0; rowIndex < dados.length; rowIndex++) {
        final row = dados[rowIndex];
        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          final value = row[headers[colIndex]];
          sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + 1,
          ))..value = value?.toString() ?? '';
        }
      }
    }

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
  }

  Future<double> _calcularTamanhoArquivo(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.length();
      return bytes / (1024 * 1024); // Converter para MB
    }
    return 0.0;
  }

  // ===== IMPORTAÇÃO =====

  Future<Map<String, dynamic>> importarDados({
    required String tipo,
    required String arquivoPath,
    required String nomeArquivoOriginal,
    double? tamanhoArquivo,
    String? usuarioId,
  }) async {
    try {
      Logger.info('Iniciando importação: $tipo do arquivo $nomeArquivoOriginal');

      // Criar job de importação
      final job = ImportJobModel(
        tipo: tipo,
        arquivoPath: arquivoPath,
        status: 'pendente',
        dataCriacao: DateTime.now(),
        usuarioId: usuarioId,
        nomeArquivoOriginal: nomeArquivoOriginal,
        tamanhoArquivo: tamanhoArquivo,
      );

      final jobId = await _importDao.insert(job);
      Logger.info('Job de importação criado: $jobId');

      // Processar importação
      final resultado = await _processarImportacao(job.copyWith(id: jobId));
      
      // Atualizar job com resultado
      await _importDao.updateStatus(
        jobId,
        resultado['sucesso'] ? 'concluido' : 'erro',
        erros: resultado['erros'] != null ? json.encode(resultado['erros']) : null,
      );

      return resultado;
    } catch (e) {
      Logger.error('Erro na importação: $e');
      return {
        'sucesso': false,
        'erro': e.toString(),
        'erros': [{'linha': 0, 'campo': 'geral', 'mensagem': e.toString()}],
      };
    }
  }

  Future<Map<String, dynamic>> _processarImportacao(ImportJobModel job) async {
    try {
      final dados = await lerArquivo(job.arquivoPath);
      final totalRegistros = dados.length;

      // Atualizar total de registros
      await _importDao.updateProgress(
        job.id!,
        totalRegistros: totalRegistros,
      );

      List<Map<String, dynamic>> erros = [];
      int registrosSucesso = 0;
      int registrosErro = 0;

      // Processar cada registro
      for (int i = 0; i < dados.length; i++) {
        try {
          final registro = dados[i];
          await _processarRegistro(job.tipo, registro);
          registrosSucesso++;
        } catch (e) {
          registrosErro++;
          erros.add({
            'linha': i + 1,
            'campo': 'geral',
            'mensagem': e.toString(),
          });
        }

        // Atualizar progresso a cada 10 registros
        if (i % 10 == 0) {
          await _importDao.updateProgress(
            job.id!,
            registrosProcessados: i + 1,
            registrosSucesso: registrosSucesso,
            registrosErro: registrosErro,
          );
        }
      }

      // Atualizar progresso final
      await _importDao.updateProgress(
        job.id!,
        registrosProcessados: totalRegistros,
        registrosSucesso: registrosSucesso,
        registrosErro: registrosErro,
      );

      return {
        'sucesso': registrosErro == 0,
        'total_registros': totalRegistros,
        'registros_sucesso': registrosSucesso,
        'registros_erro': registrosErro,
        'erros': erros.isNotEmpty ? erros : null,
      };
    } catch (e) {
      Logger.error('Erro no processamento da importação: $e');
      return {
        'sucesso': false,
        'erro': e.toString(),
        'erros': [{'linha': 0, 'campo': 'geral', 'mensagem': e.toString()}],
      };
    }
  }

  Future<List<Map<String, dynamic>>> lerArquivo(String arquivoPath) async {
    try {
      final file = File(arquivoPath);
      
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $arquivoPath');
      }
      
      final extension = path.extension(arquivoPath).toLowerCase();
      Logger.info('Lendo arquivo: $arquivoPath (extensão: $extension)');

      switch (extension) {
        case '.json':
          final content = await file.readAsString();
          final decoded = json.decode(content);
          
          if (decoded is List) {
            return List<Map<String, dynamic>>.from(decoded);
          } else if (decoded is Map) {
            return [Map<String, dynamic>.from(decoded)];
          } else {
            throw Exception('Formato JSON inválido');
          }
        
        case '.csv':
          final content = await file.readAsString();
          Logger.info('Conteúdo CSV: ${content.length} caracteres');
          
          // Dividir por linhas e remover linhas vazias
          final lines = content.split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();
          
          if (lines.isEmpty) {
            Logger.warning('Arquivo CSV vazio');
            return [];
          }
          
          // Processar cabeçalhos
          final headers = lines[0].split(',').map((h) => h.trim().replaceAll('"', '')).toList();
          Logger.info('Cabeçalhos CSV: $headers');
          
          final dados = <Map<String, dynamic>>[];
          
          // Processar linhas de dados
          for (int i = 1; i < lines.length; i++) {
            final line = lines[i];
            final values = line.split(',').map((v) => v.trim().replaceAll('"', '')).toList();
            
            if (values.length >= headers.length) {
              final map = <String, dynamic>{};
              for (int j = 0; j < headers.length; j++) {
                map[headers[j]] = values[j];
              }
              dados.add(map);
            }
          }
          
          Logger.info('Dados CSV processados: ${dados.length} registros');
          return dados;
        
        case '.xlsx':
          final bytes = await file.readAsBytes();
          final excel = Excel.decodeBytes(bytes);
          
          if (excel.tables.isEmpty) {
            throw Exception('Nenhuma planilha encontrada no arquivo Excel');
          }
          
          final sheet = excel.tables[excel.tables.keys.first]!;
          Logger.info('Planilha Excel: ${sheet.maxRows} linhas, ${sheet.maxCols} colunas');
          
          if (sheet.maxRows == 0) return [];
          
          final headers = <String>[];
          final maxCols = sheet.maxCols;
          for (int i = 0; i < maxCols; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
            headers.add(cell.value?.toString() ?? 'coluna_$i');
          }
          
          final dados = <Map<String, dynamic>>[];
          for (int row = 1; row < sheet.maxRows; row++) {
            final map = <String, dynamic>{};
            for (int col = 0; col < maxCols; col++) {
              final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
              map[headers[col]] = cell.value?.toString() ?? '';
            }
            dados.add(map);
          }
          
          Logger.info('Dados Excel processados: ${dados.length} registros');
          return dados;
        
        default:
          throw Exception('Formato de arquivo não suportado: $extension');
      }
    } catch (e) {
      Logger.error('Erro ao ler arquivo $arquivoPath: $e');
      rethrow;
    }
  }

  Future<void> _processarRegistro(String tipo, Map<String, dynamic> registro) async {
    switch (tipo) {
      case 'prescricoes':
        await _importarPrescricao(registro);
        break;
      case 'talhoes':
        await _importarTalhao(registro);
        break;
      default:
        throw Exception('Tipo de importação não suportado: $tipo');
    }
  }

  Future<void> _importarPrescricao(Map<String, dynamic> registro) async {
    try {
      Logger.info('Importando prescrição: ${registro['id'] ?? registro['nome']}');
      
      // Validar dados obrigatórios
      final nome = registro['nome'] ?? registro['name'];
      if (nome == null || nome.toString().trim().isEmpty) {
        throw Exception('Nome da prescrição é obrigatório');
      }
      
      // Validar talhão
      final talhaoId = registro['talhao_id'] ?? registro['talhaoId'];
      if (talhaoId == null) {
        throw Exception('ID do talhão é obrigatório');
      }
      
      // Validar produtos
      final produtosStr = registro['produtos'] ?? registro['products'];
      List<Map<String, dynamic>>? produtos;
      if (produtosStr != null) {
        try {
          if (produtosStr is String) {
            produtos = List<Map<String, dynamic>>.from(json.decode(produtosStr));
          } else if (produtosStr is List) {
            produtos = produtosStr.cast<Map<String, dynamic>>();
          }
        } catch (e) {
          Logger.warning('Produtos inválidos para prescrição $nome: $e');
        }
      }
      
      // Criar prescrição
      final prescricaoData = {
        'id': registro['id'] ?? _uuid.v4(),
        'nome': nome.toString().trim(),
        'talhaoId': talhaoId.toString(),
        'dataCriacao': DateTime.now().toIso8601String(),
        'dataAtualizacao': DateTime.now().toIso8601String(),
        'status': registro['status'] ?? 'ativa',
        'observacoes': registro['observacoes'] ?? registro['observations'],
      };
      
      // Se há produtos, adicionar à prescrição
      if (produtos != null && produtos.isNotEmpty) {
        prescricaoData['produtos'] = produtos;
      }
      
      Logger.info('Dados da prescrição para importação: $prescricaoData');
      
      // Aqui você pode adicionar a lógica para salvar no banco de dados
      // Por exemplo, usando o PrescriptionService ou diretamente o DAO
      
      Logger.info('Prescrição importada com sucesso: $nome');
    } catch (e) {
      Logger.error('Erro ao importar prescrição: $e');
      rethrow;
    }
  }

  Future<void> _importarTalhao(Map<String, dynamic> registro) async {
    try {
      Logger.info('Importando talhão: ${registro['nome'] ?? registro['name']}');
      
      // Validar dados obrigatórios
      final nome = registro['nome'] ?? registro['name'];
      if (nome == null || nome.toString().trim().isEmpty) {
        throw Exception('Nome do talhão é obrigatório');
      }
      
      // Validar área
      final areaStr = registro['area'] ?? registro['area_ha'];
      double? area;
      if (areaStr != null) {
        try {
          area = double.tryParse(areaStr.toString());
        } catch (e) {
          Logger.warning('Área inválida para talhão $nome: $areaStr');
        }
      }
      
      // Validar coordenadas se existirem
      List<Map<String, dynamic>>? coordenadas;
      final coordsStr = registro['coordenadas'] ?? registro['coordinates'];
      if (coordsStr != null) {
        try {
          if (coordsStr is String) {
            coordenadas = List<Map<String, dynamic>>.from(json.decode(coordsStr));
          } else if (coordsStr is List) {
            coordenadas = coordsStr.cast<Map<String, dynamic>>();
          }
        } catch (e) {
          Logger.warning('Coordenadas inválidas para talhão $nome: $e');
        }
      }
      
      // Criar talhão usando o provider
      final talhaoData = {
        'id': registro['id'] ?? _uuid.v4(),
        'name': nome.toString().trim(),
        'area': area ?? 0.0,
        'fazendaId': registro['fazenda_id'] ?? registro['idFazenda'] ?? '1',
        'culturaId': registro['cultura_id'] ?? registro['culturaId'],
        'safraId': registro['safra_id'] ?? registro['safraId'],
        'dataCriacao': DateTime.now().toIso8601String(),
        'dataAtualizacao': DateTime.now().toIso8601String(),
        'sincronizado': false,
      };
      
      // Se há coordenadas, adicionar ao talhão
      if (coordenadas != null && coordenadas.isNotEmpty) {
        talhaoData['poligonos'] = [{
          'id': _uuid.v4(),
          'name': nome,
          'points': coordenadas,
          'area': area ?? 0.0,
          'color': registro['cor'] ?? '#4CAF50',
        }];
      }
      
      Logger.info('Dados do talhão para importação: $talhaoData');
      
      // Aqui você pode adicionar a lógica para salvar no banco de dados
      // Por exemplo, usando o TalhaoProvider ou diretamente o DAO
      
      Logger.info('Talhão importado com sucesso: $nome');
    } catch (e) {
      Logger.error('Erro ao importar talhão: $e');
      rethrow;
    }
  }

  // ===== CONSULTAS =====

  Future<List<ExportJobModel>> getExportJobs({String? tipo, String? status}) async {
    if (tipo != null) {
      return await _exportDao.getByTipo(tipo);
    } else if (status != null) {
      return await _exportDao.getByStatus(status);
    } else {
      return await _exportDao.getAll();
    }
  }

  Future<List<ImportJobModel>> getImportJobs({String? tipo, String? status}) async {
    if (tipo != null) {
      return await _importDao.getByTipo(tipo);
    } else if (status != null) {
      return await _importDao.getByStatus(status);
    } else {
      return await _importDao.getAll();
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final exportStats = await _exportDao.getStatistics();
    final importStats = await _importDao.getStatistics();
    
    return {
      'exportacao': exportStats,
      'importacao': importStats,
    };
  }

  Future<void> cleanupOldJobs() async {
    await _exportDao.cleanupOldJobs();
    await _importDao.cleanupOldJobs();
  }
}

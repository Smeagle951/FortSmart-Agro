/// 📦 Provider: Gerenciamento de Estado Fenológico
/// 
/// Provider para gerenciamento centralizado do estado
/// dos dados fenológicos usando ChangeNotifier.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:flutter/foundation.dart';
import '../models/phenological_record_model.dart';
import '../models/phenological_alert_model.dart';
import '../database/phenological_database.dart';
import '../database/daos/phenological_record_dao.dart';
import '../database/daos/phenological_alert_dao.dart';

class PhenologicalProvider extends ChangeNotifier {
  final PhenologicalDatabase _database = PhenologicalDatabase();
  
  // DAOs
  PhenologicalRecordDAO? _recordDAO;
  PhenologicalAlertDAO? _alertDAO;
  
  // Estado
  List<PhenologicalRecordModel> _registros = [];
  List<PhenologicalAlertModel> _alertas = [];
  bool _isLoading = false;
  String? _erro;
  
  // Filtros atuais
  String? _talhaoIdFiltro;
  String? _culturaIdFiltro;

  // Getters
  List<PhenologicalRecordModel> get registros => _registros;
  List<PhenologicalAlertModel> get alertas => _alertas;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  
  // Alertas ativos
  List<PhenologicalAlertModel> get alertasAtivos =>
      _alertas.where((a) => a.status == AlertStatus.ativo).toList();
  
  // Alertas críticos
  List<PhenologicalAlertModel> get alertasCriticos =>
      _alertas.where((a) => 
        a.status == AlertStatus.ativo && 
        a.severidade == AlertSeverity.critica
      ).toList();

  /// Inicializar provider
  Future<void> inicializar() async {
    try {
      print('🔄 Inicializando PhenologicalProvider...');
      final db = await _database.database;
      print('📊 Banco de dados obtido: ${db.path}');
      
      _recordDAO = PhenologicalRecordDAO(db);
      _alertDAO = PhenologicalAlertDAO(db);
      
      print('✅ PhenologicalProvider inicializado com sucesso');
      print('   - RecordDAO: ${_recordDAO != null ? "OK" : "FALHOU"}');
      print('   - AlertDAO: ${_alertDAO != null ? "OK" : "FALHOU"}');
    } catch (e, stackTrace) {
      print('❌ Erro ao inicializar PhenologicalProvider: $e');
      print('Stack trace: $stackTrace');
      _erro = 'Erro ao inicializar: ${e.toString()}';
      notifyListeners();
      rethrow; // Re-lançar para que possamos capturar o erro
    }
  }

  /// Carregar registros de um talhão/cultura
  Future<void> carregarRegistros(String talhaoId, String culturaId) async {
    try {
      _setLoading(true);
      _talhaoIdFiltro = talhaoId;
      _culturaIdFiltro = culturaId;
      
      if (_recordDAO == null) await inicializar();
      
      _registros = await _recordDAO!.listarPorTalhaoECultura(
        talhaoId,
        culturaId,
      );
      
      _erro = null;
      print('✅ ${_registros.length} registros carregados');
    } catch (e) {
      print('❌ Erro ao carregar registros: $e');
      _erro = e.toString();
      _registros = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Carregar alertas de um talhão/cultura
  Future<void> carregarAlertas(String talhaoId, String culturaId) async {
    try {
      if (_alertDAO == null) await inicializar();
      
      _alertas = await _alertDAO!.listarPorTalhaoECultura(
        talhaoId,
        culturaId,
      );
      
      print('✅ ${_alertas.length} alertas carregados');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar alertas: $e');
      _erro = e.toString();
      _alertas = [];
      notifyListeners();
    }
  }

  /// Adicionar novo registro
  Future<void> adicionarRegistro(PhenologicalRecordModel registro) async {
    try {
      _setLoading(true);
      _erro = null;
      
      // Garantir que o DAO está inicializado
      if (_recordDAO == null) {
        print('⚠️ DAO não inicializado, inicializando...');
        await inicializar();
      }
      
      if (_recordDAO == null) {
        throw Exception('Erro ao inicializar banco de dados. DAO ainda está nulo.');
      }
      
      print('💾 Inserindo registro no banco...');
      await _recordDAO!.inserir(registro);
      print('✅ Registro inserido no banco com sucesso!');
      
      // Recarregar lista
      if (_talhaoIdFiltro != null && _culturaIdFiltro != null) {
        print('🔄 Recarregando lista de registros...');
        await carregarRegistros(_talhaoIdFiltro!, _culturaIdFiltro!);
      }
      
      print('✅ Registro adicionado com sucesso');
    } catch (e, stackTrace) {
      print('❌ Erro ao adicionar registro: $e');
      print('Stack trace: $stackTrace');
      _erro = 'Erro ao salvar registro: ${e.toString()}';
      rethrow; // Re-lançar para que a tela possa capturar
    } finally {
      _setLoading(false);
    }
  }

  /// Atualizar registro existente
  Future<void> atualizarRegistro(PhenologicalRecordModel registro) async {
    try {
      _setLoading(true);
      
      if (_recordDAO == null) await inicializar();
      
      await _recordDAO!.atualizar(registro);
      
      // Atualizar na lista local
      final index = _registros.indexWhere((r) => r.id == registro.id);
      if (index != -1) {
        _registros[index] = registro;
      }
      
      print('✅ Registro atualizado com sucesso');
    } catch (e) {
      print('❌ Erro ao atualizar registro: $e');
      _erro = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Deletar registro
  Future<void> deletarRegistro(String id) async {
    try {
      _setLoading(true);
      
      if (_recordDAO == null) await inicializar();
      
      await _recordDAO!.deletar(id);
      
      // Remover da lista local
      _registros.removeWhere((r) => r.id == id);
      
      print('✅ Registro deletado com sucesso');
    } catch (e) {
      print('❌ Erro ao deletar registro: $e');
      _erro = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Adicionar alerta
  Future<void> adicionarAlerta(PhenologicalAlertModel alerta) async {
    try {
      if (_alertDAO == null) await inicializar();
      
      await _alertDAO!.inserir(alerta);
      _alertas.add(alerta);
      
      print('✅ Alerta adicionado com sucesso');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao adicionar alerta: $e');
      _erro = e.toString();
    }
  }

  /// Resolver alerta
  Future<void> resolverAlerta(String id, String? observacoes) async {
    try {
      if (_alertDAO == null) await inicializar();
      
      await _alertDAO!.resolverAlerta(id, observacoes);
      
      // Atualizar na lista local
      final index = _alertas.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alertas[index] = _alertas[index].copyWith(
          status: AlertStatus.resolvido,
          resolvidoEm: DateTime.now(),
          observacoesResolucao: observacoes,
        );
      }
      
      print('✅ Alerta resolvido com sucesso');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao resolver alerta: $e');
      _erro = e.toString();
    }
  }

  /// Ignorar alerta
  Future<void> ignorarAlerta(String id, String? observacoes) async {
    try {
      if (_alertDAO == null) await inicializar();
      
      await _alertDAO!.ignorarAlerta(id, observacoes);
      
      // Atualizar na lista local
      final index = _alertas.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alertas[index] = _alertas[index].copyWith(
          status: AlertStatus.ignorado,
          resolvidoEm: DateTime.now(),
          observacoesResolucao: observacoes,
        );
      }
      
      print('✅ Alerta ignorado com sucesso');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao ignorar alerta: $e');
      _erro = e.toString();
    }
  }

  /// Buscar último registro
  Future<PhenologicalRecordModel?> buscarUltimoRegistro(
    String talhaoId,
    String culturaId,
  ) async {
    try {
      if (_recordDAO == null) await inicializar();
      return await _recordDAO!.buscarUltimoRegistro(talhaoId, culturaId);
    } catch (e) {
      print('❌ Erro ao buscar último registro: $e');
      return null;
    }
  }

  /// Obter registros ordenados por data (para gráficos)
  Future<List<PhenologicalRecordModel>> obterRegistrosParaGraficos(
    String talhaoId,
    String culturaId,
  ) async {
    try {
      if (_recordDAO == null) await inicializar();
      return await _recordDAO!.listarOrdenadoPorData(talhaoId, culturaId);
    } catch (e) {
      print('❌ Erro ao obter registros para gráficos: $e');
      return [];
    }
  }

  /// Contar registros
  Future<int> contarRegistros(String talhaoId, String culturaId) async {
    try {
      if (_recordDAO == null) await inicializar();
      return await _recordDAO!.contarRegistros(talhaoId, culturaId);
    } catch (e) {
      print('❌ Erro ao contar registros: $e');
      return 0;
    }
  }

  /// Contar alertas ativos
  Future<int> contarAlertasAtivos(String talhaoId) async {
    try {
      if (_alertDAO == null) await inicializar();
      return await _alertDAO!.contarAtivos(talhaoId);
    } catch (e) {
      print('❌ Erro ao contar alertas ativos: $e');
      return 0;
    }
  }

  /// Limpar dados
  void limpar() {
    _registros = [];
    _alertas = [];
    _erro = null;
    _talhaoIdFiltro = null;
    _culturaIdFiltro = null;
    notifyListeners();
  }

  /// Helper: Definir estado de loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    limpar();
    super.dispose();
  }
}


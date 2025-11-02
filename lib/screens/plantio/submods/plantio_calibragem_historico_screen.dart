import 'package:flutter/material.dart';
import '../../../models/calibration_history_model.dart';
import '../../../database/daos/calibration_history_dao.dart';
import '../../../database/app_database.dart';
import '../../../utils/snackbar_utils.dart';

class PlantioCalibragemHistoricoScreen extends StatefulWidget {
  const PlantioCalibragemHistoricoScreen({Key? key}) : super(key: key);

  @override
  State<PlantioCalibragemHistoricoScreen> createState() => _PlantioCalibragemHistoricoScreenState();
}

class _PlantioCalibragemHistoricoScreenState extends State<PlantioCalibragemHistoricoScreen> {
  
  List<CalibrationHistoryModel> _calibracoes = [];
  List<CalibrationHistoryModel> _calibracoesFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtros
  String? _filtroStatus;
  String? _filtroTalhao;
  String? _filtroCultura;
  String? _filtroTipoCalibracao;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  
  // Listas para filtros
  List<String> _talhoesDisponiveis = [];
  List<String> _culturasDisponiveis = [];
  
  final List<String> _statusOptions = [
    'Todos',
    'dentro_esperado',
    'normal',
    'fora_esperado',
  ];

  final List<String> _tipoCalibracaoOptions = [
    'Todos os Tipos',
    'Calibragem de Plantadeira',
    'Cálculo de Sementes',
    'Calibragem de Adubo',
    'Calibragem de Disco',
    'Estande de Plantas',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testarBanco();
    });
  }

  Future<void> _testarBanco() async {
    try {
      print('🔧 Testando acesso ao banco de dados...');
      
      // Aguardar a inicialização completa do AppDatabase
      await AppDatabase.instance.initDatabase();
      print('✅ AppDatabase inicializado');
      
      final database = await AppDatabase.instance.database;
      print('✅ Banco de dados acessado com sucesso: ${database.isOpen}');
      
      _carregarDados();
    } catch (e) {
      print('❌ Erro ao acessar banco de dados: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao acessar banco de dados: $e';
      });
    }
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Garantir que o banco esteja inicializado
      await AppDatabase.instance.initDatabase();
      
      final database = await AppDatabase.instance.database;
      final dao = CalibrationHistoryDao(database);
      
      _calibracoes = await dao.getAllCalibrations();
      
      // Extrair talhões e culturas únicos para filtros
      final talhoesSet = <String>{};
      final culturasSet = <String>{};
      
      for (final calibracao in _calibracoes) {
        talhoesSet.add(calibracao.talhaoName);
        culturasSet.add(calibracao.culturaName);
      }
      
      _talhoesDisponiveis = ['Todos', ...talhoesSet.toList()..sort()];
      _culturasDisponiveis = ['Todos', ...culturasSet.toList()..sort()];
      
      _aplicarFiltros();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados do histórico: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar histórico: $e';
        });
      }
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _calibracoesFiltradas = _calibracoes.where((calibracao) {
        // Filtro por status
        if (_filtroStatus != null && _filtroStatus != 'Todos') {
          if (calibracao.statusCalibracao != _filtroStatus) return false;
        }
        
        // Filtro por talhão
        if (_filtroTalhao != null && _filtroTalhao != 'Todos') {
          if (calibracao.talhaoName != _filtroTalhao) return false;
        }
        
        // Filtro por cultura
        if (_filtroCultura != null && _filtroCultura != 'Todos') {
          if (calibracao.culturaName != _filtroCultura) return false;
        }
        
        // Filtro por tipo de calibração
        if (_filtroTipoCalibracao != null && _filtroTipoCalibracao != 'Todos os Tipos') {
          if (calibracao.culturaName != _filtroTipoCalibracao) return false;
        }
        
        // Filtro por data
        if (_dataInicio != null) {
          if (calibracao.dataCalibracao.isBefore(_dataInicio!)) return false;
        }
        
        if (_dataFim != null) {
          final dataFimComHora = DateTime(
            _dataFim!.year,
            _dataFim!.month,
            _dataFim!.day,
            23,
            59,
            59,
          );
          if (calibracao.dataCalibracao.isAfter(dataFimComHora)) return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _limparFiltros() {
    setState(() {
      _filtroStatus = null;
      _filtroTalhao = null;
      _filtroCultura = null;
      _filtroTipoCalibracao = null;
      _dataInicio = null;
      _dataFim = null;
    });
    _aplicarFiltros();
  }

  Future<void> _excluirCalibracao(CalibrationHistoryModel calibracao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir a calibração de ${calibracao.culturaName} no talhão ${calibracao.talhaoName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await AppDatabase.instance.initDatabase();
        final database = await AppDatabase.instance.database;
        final dao = CalibrationHistoryDao(database);
        
        await dao.deleteCalibration(calibracao.id!);
        SnackbarUtils.showSuccessSnackBar(context, 'Calibração excluída com sucesso!');
        _carregarDados();
      } catch (e) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao excluir calibração: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Calibrações'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _calibracoesFiltradas.isEmpty
                  ? _buildEmptyWidget()
                  : Column(
                      children: [
                        _buildEstatisticas(),
                        Expanded(
                          child: _buildListaCalibracoes(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar histórico',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregarDados,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _calibracoes.isEmpty ? 'Nenhuma calibração encontrada' : 'Nenhuma calibração corresponde aos filtros',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _calibracoes.isEmpty 
                  ? 'Realize algumas calibrações para ver o histórico aqui'
                  : 'Tente ajustar os filtros para ver mais resultados',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_calibracoes.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.clear),
                label: const Text('Limpar Filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticas() {
    final total = _calibracoesFiltradas.length;
    final dentroEsperado = _calibracoesFiltradas.where((c) => c.statusCalibracao == 'dentro_esperado').length;
    final normal = _calibracoesFiltradas.where((c) => c.statusCalibracao == 'normal').length;
    final foraEsperado = _calibracoesFiltradas.where((c) => c.statusCalibracao == 'fora_esperado').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEstatisticaItem('Total', total.toString(), Colors.blue),
          _buildEstatisticaItem('Dentro', dentroEsperado.toString(), Colors.green),
          _buildEstatisticaItem('Normal', normal.toString(), Colors.orange),
          _buildEstatisticaItem('Fora', foraEsperado.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildEstatisticaItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildListaCalibracoes() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _calibracoesFiltradas.length,
      itemBuilder: (context, index) {
        final calibracao = _calibracoesFiltradas[index];
        return _buildCalibracaoCard(calibracao);
      },
    );
  }

  Widget _buildCalibracaoCard(CalibrationHistoryModel calibracao) {
    final statusColor = CalibrationHistoryModel.getStatusColor(calibracao.statusCalibracao);
    final statusText = CalibrationHistoryModel.getStatusText(calibracao.statusCalibracao);
    final statusIcon = CalibrationHistoryModel.getStatusIcon(calibracao.statusCalibracao);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com status
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${calibracao.culturaName} - ${calibracao.talhaoName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'excluir') {
                      _excluirCalibracao(calibracao);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações principais
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Sementes/ha', '${calibracao.sementesPorHectare ?? 0}'),
                ),
                Expanded(
                  child: _buildInfoItem('Meta', '${calibracao.metaSementesHectare ?? 0}'),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Diferença', 
                    '${calibracao.diferencaMetaPercentual?.toStringAsFixed(1) ?? '0.0'}%',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Data
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${calibracao.dataCalibracao.day}/${calibracao.dataCalibracao.month}/${calibracao.dataCalibracao.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '${calibracao.dataCalibracao.hour.toString().padLeft(2, '0')}:${calibracao.dataCalibracao.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _filtroStatus = null;
                        _filtroTalhao = null;
                        _filtroCultura = null;
                        _filtroTipoCalibracao = null;
                        _dataInicio = null;
                        _dataFim = null;
                      });
                    },
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Filtro por status
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _filtroStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _statusOptions.map((status) {
                  String displayText;
                  switch (status) {
                    case 'Todos':
                      displayText = 'Todos';
                      break;
                    case 'dentro_esperado':
                      displayText = 'Dentro do Esperado';
                      break;
                    case 'normal':
                      displayText = 'Normal';
                      break;
                    case 'fora_esperado':
                      displayText = 'Fora do Esperado';
                      break;
                    default:
                      displayText = status;
                  }
                  return DropdownMenuItem(
                    value: status,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _filtroStatus = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Filtro por talhão
              const Text('Talhão:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _filtroTalhao,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _talhoesDisponiveis.map((talhao) {
                  return DropdownMenuItem(
                    value: talhao,
                    child: Text(talhao),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _filtroTalhao = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Filtro por cultura
              const Text('Cultura:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _filtroCultura,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _culturasDisponiveis.map((cultura) {
                  return DropdownMenuItem(
                    value: cultura,
                    child: Text(cultura),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _filtroCultura = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Filtro por tipo de calibração
              const Text('Tipo de Calibração:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _filtroTipoCalibracao,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _tipoCalibracaoOptions.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _filtroTipoCalibracao = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Filtro por data
              const Text('Período:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dataInicio ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() {
                            _dataInicio = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dataInicio != null 
                          ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
                          : 'Data Início'),
                    ),
                  ),
                  const Text(' até '),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dataFim ?? DateTime.now(),
                          firstDate: _dataInicio ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() {
                            _dataFim = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dataFim != null 
                          ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
                          : 'Data Fim'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        _aplicarFiltros();
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar Filtros'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

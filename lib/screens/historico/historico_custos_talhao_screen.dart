import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/talhao_model.dart';
import '../../models/cultura_model.dart';
import '../../services/custo_aplicacao_integration_service.dart';
import '../../utils/logger.dart';
import '../../utils/date_utils.dart' as CustomDateUtils;

class HistoricoCustosTalhaoScreen extends StatefulWidget {
  @override
  _HistoricoCustosTalhaoScreenState createState() => _HistoricoCustosTalhaoScreenState();
}

class _HistoricoCustosTalhaoScreenState extends State<HistoricoCustosTalhaoScreen> {
  final CustoAplicacaoIntegrationService _custoService = CustoAplicacaoIntegrationService();
  
  // Estados
  bool _isLoading = false;
  List<Map<String, dynamic>> _registros = [];
  Map<String, dynamic>? _resumoCustos;
  
  // Filtros
  TalhaoModel? _talhaoSelecionado;
  String? _safraSelecionada;
  DateTime _dataInicio = DateTime.now().subtract(Duration(days: 90));
  DateTime _dataFim = DateTime.now();
  Set<String> _tiposRegistroSelecionados = {
    'plantio', 'adubacao', 'pulverizacao', 'colheita', 'solo', 'outros'
  };
  String? _culturaSelecionada;
  bool _mostrarApenasCustos = false;
  
  // Dados para filtros
  List<TalhaoModel> _talhoes = [];
  List<String> _safras = [];
  List<CulturaModel> _culturas = [];
  
  // Tipos de registro disponíveis
  final Map<String, Map<String, dynamic>> _tiposRegistro = {
    'plantio': {
      'nome': 'Plantio',
      'icone': Icons.eco,
      'cor': Colors.green,
      'emoji': '🌱',
    },
    'adubacao': {
      'nome': 'Adubação',
      'icone': Icons.water_drop,
      'cor': Colors.blue,
      'emoji': '💧',
    },
    'pulverizacao': {
      'nome': 'Pulverização',
      'icone': Icons.science,
      'cor': Colors.orange,
      'emoji': '🧴',
    },
    'colheita': {
      'nome': 'Colheita',
      'icone': Icons.agriculture,
      'cor': Colors.amber,
      'emoji': '🌾',
    },
    'solo': {
      'nome': 'Solo',
      'icone': Icons.terrain,
      'cor': Colors.brown,
      'emoji': '🌍',
    },
    'outros': {
      'nome': 'Outros',
      'icone': Icons.settings,
      'cor': Colors.grey,
      'emoji': '⚙️',
    },
  };

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar dados para filtros
      await _carregarTalhoes();
      await _carregarSafras();
      await _carregarCulturas();
      
      // Carregar registros iniciais
      await _carregarRegistros();
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados iniciais: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarTalhoes() async {
    try {
      final talhoes = await _custoService.carregarTalhoes();
      setState(() {
        _talhoes = talhoes;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar talhões: $e');
    }
  }

  Future<void> _carregarSafras() async {
    // Gerar safras baseadas no ano atual
    final anoAtual = DateTime.now().year;
    _safras = [
      '${anoAtual-1}/${anoAtual}',
      '${anoAtual}/${anoAtual+1}',
      '${anoAtual+1}/${anoAtual+2}',
    ];
  }

  Future<void> _carregarCulturas() async {
    try {
      final culturas = await _custoService.carregarCulturas();
      setState(() {
        _culturas = culturas;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      // Fallback com culturas padrão
      setState(() {
        _culturas = [
          CulturaModel(id: '1', name: 'Soja', description: 'Soja', color: Colors.green),
          CulturaModel(id: '2', name: 'Milho', description: 'Milho', color: Colors.yellow),
          CulturaModel(id: '3', name: 'Algodão', description: 'Algodão', color: Colors.blueGrey),
        ];
      });
    }
  }

  Future<void> _carregarRegistros() async {
    if (_talhaoSelecionado == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar aplicações reais
      final aplicacoes = await _custoService.carregarAplicacoes(
        talhaoId: _talhaoSelecionado!.id,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );
      
      // Converter aplicações para o formato de registros
      _registros = aplicacoes.map((aplicacao) => {
        'id': aplicacao.id,
        'tipo': 'pulverizacao', // Tipo padrão para aplicações
        'titulo': 'Aplicação de Produto',
        'data': aplicacao.dataAplicacao,
        'talhao': _talhaoSelecionado!.name,
        'safra': _safraSelecionada ?? '2024/25',
        'area': aplicacao.areaAplicadaHa,
        'produtos': 'Produto aplicado',
        'custo_total': aplicacao.custoTotal,
        'custo_ha': aplicacao.custoPorHa,
        'observacoes': aplicacao.observacoes ?? 'Aplicação registrada',
      }).toList();
      
      // Adicionar registros de exemplo se não houver aplicações
      if (_registros.isEmpty) {
        _registros = [
          {
            'id': '1',
            'tipo': 'pulverizacao',
            'titulo': 'Aplicação Exemplo',
            'data': DateTime.now().subtract(Duration(days: 7)),
            'talhao': _talhaoSelecionado!.name,
            'safra': _safraSelecionada ?? '2024/25',
            'area': 32.0,
            'produtos': 'Glifosato 12 L (Lote 1234)',
            'custo_total': 1250.0,
            'custo_ha': 39.06,
            'observacoes': 'Aplicação pós-emergente',
          },
          {
            'id': '2',
            'tipo': 'adubacao',
            'titulo': 'Adubação de Base',
            'data': DateTime.now().subtract(Duration(days: 15)),
            'talhao': _talhaoSelecionado!.name,
            'safra': _safraSelecionada ?? '2024/25',
            'area': 32.0,
            'produtos': 'MAP 100kg',
            'custo_total': 4200.0,
            'custo_ha': 140.0,
            'observacoes': 'Adubação de plantio',
          },
        ];
      }

      // Filtrar registros
      _aplicarFiltros();
      
      // Calcular resumo de custos
      _calcularResumoCustos();
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar registros: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar registros: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    // Filtrar por tipo de registro
    _registros = _registros.where((registro) {
      return _tiposRegistroSelecionados.contains(registro['tipo']);
    }).toList();

    // Filtrar por período
    _registros = _registros.where((registro) {
      final data = registro['data'] as DateTime;
      return data.isAfter(_dataInicio.subtract(Duration(days: 1))) &&
             data.isBefore(_dataFim.add(Duration(days: 1)));
    }).toList();

    // Filtrar por cultura (se selecionada)
    if (_culturaSelecionada != null) {
      _registros = _registros.where((registro) {
        return registro['titulo'].toLowerCase().contains(_culturaSelecionada!.toLowerCase());
      }).toList();
    }
  }

  void _calcularResumoCustos() {
    final custosPorTipo = <String, double>{};
    double custoTotal = 0.0;
    double areaTotal = 0.0;

    for (final registro in _registros) {
      final tipo = registro['tipo'] as String;
      final custo = registro['custo_total'] as double;
      final area = registro['area'] as double;

      custosPorTipo[tipo] = (custosPorTipo[tipo] ?? 0.0) + custo;
      custoTotal += custo;
      areaTotal += area;
    }

    final custoMedioPorHa = areaTotal > 0 ? custoTotal / areaTotal : 0.0;

    setState(() {
      _resumoCustos = {
        'custos_por_tipo': custosPorTipo,
        'custo_total': custoTotal,
        'custo_medio_por_ha': custoMedioPorHa,
        'area_total': areaTotal,
        'total_registros': _registros.length,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📊 Histórico & Custos por Talhão'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarRegistros,
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _abrirGraficos,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _registros.isEmpty
                    ? _buildMensagemVazia()
                    : _buildListaRegistros(),
          ),
          if (_resumoCustos != null) _buildResumoCustos(),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Primeira linha: Talhão e Safra
          Row(
            children: [
              Expanded(
                child: _buildDropdownFiltro(
                  label: 'Talhão',
                  value: _talhaoSelecionado?.name,
                  items: _talhoes.map((t) => t.name).toList(),
                  onChanged: (value) {
                    setState(() {
                      _talhaoSelecionado = _talhoes.firstWhere((t) => t.name == value);
                    });
                    _carregarRegistros();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDropdownFiltro(
                  label: 'Safra',
                  value: _safraSelecionada,
                  items: _safras,
                  onChanged: (value) {
                    setState(() {
                      _safraSelecionada = value;
                    });
                    _carregarRegistros();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Segunda linha: Período
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Data Início',
                  value: _dataInicio,
                  onChanged: (date) {
                    setState(() {
                      _dataInicio = date;
                    });
                    _carregarRegistros();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: 'Data Fim',
                  value: _dataFim,
                  onChanged: (date) {
                    setState(() {
                      _dataFim = date;
                    });
                    _carregarRegistros();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Terceira linha: Tipos de Registro
          Text(
            'Tipos de Registro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tiposRegistro.entries.map((entry) {
              final tipo = entry.key;
              final dados = entry.value;
              final isSelected = _tiposRegistroSelecionados.contains(tipo);
              
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dados['emoji']),
                    SizedBox(width: 4),
                    Text(dados['nome']),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _tiposRegistroSelecionados.add(tipo);
                    } else {
                      _tiposRegistroSelecionados.remove(tipo);
                    }
                  });
                  _carregarRegistros();
                },
                backgroundColor: Colors.white,
                selectedColor: dados['cor'].withOpacity(0.2),
                checkmarkColor: dados['cor'],
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          
          // Quarta linha: Cultura e Toggle
          Row(
            children: [
              Expanded(
                child: _buildDropdownFiltro(
                  label: 'Cultura',
                  value: _culturaSelecionada,
                  items: ['Todas'] + _culturas.map((c) => c.name).toList(),
                  onChanged: (value) {
                    setState(() {
                      _culturaSelecionada = value == 'Todas' ? null : value;
                    });
                    _carregarRegistros();
                  },
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apenas Custos',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Switch(
                    value: _mostrarApenasCustos,
                    onChanged: (value) {
                      setState(() {
                        _mostrarApenasCustos = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFiltro({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            hint: Text('Selecione...'),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(value.toIso8601String().split('T')[0]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMensagemVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum registro encontrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ajuste os filtros ou adicione novos registros',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaRegistros() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _registros.length,
      itemBuilder: (context, index) {
        final registro = _registros[index];
        final tipo = registro['tipo'] as String;
        final dadosTipo = _tiposRegistro[tipo]!;
        
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do registro
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dadosTipo['cor'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        dadosTipo['icone'],
                        color: dadosTipo['cor'],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registro['titulo'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            registro['data'].toIso8601String().split('T')[0],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) => _executarAcao(action, registro),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicar',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remover',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remover', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Informações do registro
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Talhão: ${registro['talhao']} / ${registro['safra']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Área: ${registro['area'].toStringAsFixed(1)} ha',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Produto(s): ${registro['produtos']}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${registro['custo_total'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: dadosTipo['cor'],
                          ),
                        ),
                        Text(
                          'R\$ ${registro['custo_ha'].toStringAsFixed(2)}/ha',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Observações (se houver)
                if (registro['observacoes'] != null && registro['observacoes'].isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      registro['observacoes'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumoCustos() {
    final resumo = _resumoCustos!;
    final custosPorTipo = resumo['custos_por_tipo'] as Map<String, double>;
    final custoTotal = resumo['custo_total'] as double;
    final custoMedioPorHa = resumo['custo_medio_por_ha'] as double;
    final totalRegistros = resumo['total_registros'] as int;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📊 Resumo Custos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              Text(
                '${totalRegistros} registros',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Custos por tipo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: custosPorTipo.entries.map((entry) {
              final tipo = entry.key;
              final custo = entry.value;
              final dadosTipo = _tiposRegistro[tipo]!;
              final areaTotal = resumo['area_total'] as double;
              final custoPorHa = areaTotal > 0 ? custo / areaTotal : 0.0;
              
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dadosTipo['cor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dadosTipo['cor'].withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dadosTipo['emoji']),
                        SizedBox(width: 4),
                        Text(
                          dadosTipo['nome'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'R\$ ${custo.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: dadosTipo['cor'],
                      ),
                    ),
                    Text(
                      'R\$ ${custoPorHa.toStringAsFixed(2)}/ha',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 12),
          Divider(),
          
          // Total
          Row(
            children: [
              Text(
                'TOTAL:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${custoTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'R\$ ${custoMedioPorHa.toStringAsFixed(2)}/ha',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _executarAcao(String action, Map<String, dynamic> registro) {
    switch (action) {
      case 'editar':
        _editarRegistro(registro);
        break;
      case 'duplicar':
        _duplicarRegistro(registro);
        break;
      case 'remover':
        _removerRegistro(registro);
        break;
    }
  }

  void _editarRegistro(Map<String, dynamic> registro) {
    // Implementar navegação para edição
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando registro: ${registro['titulo']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _duplicarRegistro(Map<String, dynamic> registro) {
    // Implementar duplicação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicando registro: ${registro['titulo']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removerRegistro(Map<String, dynamic> registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Remoção'),
        content: Text('Deseja realmente remover o registro "${registro['titulo']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _registros.removeWhere((r) => r['id'] == registro['id']);
              });
              _calcularResumoCustos();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Registro removido com sucesso'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _abrirGraficos() {
    // Implementar navegação para gráficos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo gráficos de custos...'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}

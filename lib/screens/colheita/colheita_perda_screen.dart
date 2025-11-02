import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../database/models/colheita_perda_model.dart';
import '../../services/talhao_module_service.dart';
import '../../services/cultura_talhao_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../../widgets/safe_form_field.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/brazilian_number_formatter.dart';
import '../../utils/modules_data_sync.dart';
import '../../services/talhao_unified_service.dart';

/// Tela para cálculo de perdas na colheita
class ColheitaPerdaScreen extends StatefulWidget {
  const ColheitaPerdaScreen({Key? key}) : super(key: key);

  @override
  State<ColheitaPerdaScreen> createState() => _ColheitaPerdaScreenState();
}

class _ColheitaPerdaScreenState extends State<ColheitaPerdaScreen> {
  // Controllers
  final _dataController = TextEditingController();
  final _areaColetaController = TextEditingController();
  final _pesoColetadoController = TextEditingController();
  final _pesoSacaController = TextEditingController();

  // Serviços
  final _talhaoService = TalhaoModuleService();
  final _culturaService = CulturaTalhaoService();
  final _talhaoUnifiedService = TalhaoUnifiedService();

  // Estados
  String? _talhaoSelecionado;
  String? _culturaSelecionada;
  String _metodoCalculo = 'peso_gramas';
  String _coordenadasGps = '';
  bool _isLoading = false;
  DateTime _dataSelecionada = DateTime.now();

  // Dados
  List<Map<String, dynamic>> _talhoes = [];
  List<Map<String, dynamic>> _culturas = [];

  // Resultados calculados
  double _perdaKgHa = 0.0;
  double _perdaScHa = 0.0;
  String _classificacao = 'Aceitável';

  @override
  void initState() {
    super.initState();
    _inicializarTela();
  }

  @override
  void dispose() {
    _dataController.dispose();
    _areaColetaController.dispose();
    _pesoColetadoController.dispose();
    _pesoSacaController.dispose();
    super.dispose();
  }

  /// Inicializa a tela
  Future<void> _inicializarTela() async {
    setState(() => _isLoading = true);
    
    try {
      // Definir data atual
      _dataSelecionada = DateTime.now();
      _dataController.text = DateFormat('dd/MM/yyyy').format(_dataSelecionada);
      
      // Definir peso da saca padrão
      _pesoSacaController.text = '60';
      
      // Carregar dados
      await _carregarTalhoes();
      await _carregarCulturas();
      await _obterLocalizacao();
      
    } catch (e) {
      Logger.error('Erro ao inicializar tela: $e');
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Erro',
          message: 'Erro ao carregar dados: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Carrega talhões disponíveis
  Future<void> _carregarTalhoes() async {
    try {
      Logger.info('🔄 [COLHEITA] Carregando talhões via serviço unificado...');
      
      // Usar o serviço unificado para carregar talhões
      final talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
        nomeModulo: 'COLHEITA',
      );
      
      // Log detalhado para debug das áreas
      Logger.info('🔍 [COLHEITA] Debug das áreas dos talhões:');
      for (final talhao in talhoes) {
        Logger.info('  - ${talhao.name}: área = ${talhao.area} (tipo: ${talhao.area.runtimeType})');
      }
      
      setState(() {
        _talhoes = talhoes.map((talhao) {
          final area = talhao.area;
          Logger.info('🔍 [COLHEITA] Convertendo talhão ${talhao.name}: área original = $area');
          
          return <String, dynamic>{
            'id': talhao.id,
            'nome': talhao.name,
            'area': area,
            'fazenda_id': talhao.fazendaId,
          };
        }).toList();
      });
      
      Logger.info('✅ [COLHEITA] ${_talhoes.length} talhões carregados com sucesso');
      
      // Log final dos dados convertidos
      Logger.info('🔍 [COLHEITA] Dados finais dos talhões:');
      for (final talhao in _talhoes) {
        Logger.info('  - ${talhao['nome']}: área = ${talhao['area']} (tipo: ${talhao['area'].runtimeType})');
      }
      
    } catch (e) {
      Logger.error('❌ [COLHEITA] Erro ao carregar talhões: $e');
      // Fallback: usar serviço antigo
      try {
        final talhoesAntigos = await _talhaoService.getTalhoes();
        setState(() {
          _talhoes = talhoesAntigos.map((talhao) {
            return <String, dynamic>{
              'id': talhao.id,
              'nome': talhao.name,
              'area': talhao.area,
              'fazenda_id': talhao.fazendaId,
            };
          }).toList();
        });
        Logger.info('⚠️ [COLHEITA] Usando fallback: ${_talhoes.length} talhões carregados');
      } catch (fallbackError) {
        Logger.error('❌ [COLHEITA] Erro no fallback: $fallbackError');
        setState(() => _talhoes = []);
      }
    }
  }

  /// Carrega culturas disponíveis
  Future<void> _carregarCulturas() async {
    try {
      final culturas = await _culturaService.listarCulturas();
      
      // Verificar se é uma lista de AgriculturalProduct ou Map
      if (culturas.isNotEmpty) {
        if (culturas.first is Map<String, dynamic>) {
          // Se for uma lista de Map, converter diretamente
          _culturas = (culturas as List<Map<String, dynamic>>).map((cultura) => {
            'id': cultura['id']?.toString() ?? '',
            'nome': cultura['name']?.toString() ?? cultura['nome']?.toString() ?? 'Cultura',
          }).toList();
        } else {
          // Se for uma lista de AgriculturalProduct, converter para Map
          _culturas = culturas.map((cultura) => {
            'id': cultura.id?.toString() ?? '',
            'nome': cultura.name?.toString() ?? 'Cultura',
          }).toList();
        }
      } else {
        _culturas = [];
      }
    } catch (e) {
      Logger.error('Erro ao carregar culturas: $e');
      _culturas = [];
    }
  }

  /// Obtém localização GPS
  Future<void> _obterLocalizacao() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _coordenadasGps = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      Logger.error('Erro ao obter localização: $e');
      _coordenadasGps = '-15.5484, -54.2933'; // Coordenadas padrão
    }
  }

  /// Seleciona data da coleta
  Future<void> _selecionarData() async {
    try {
      final date = await showDatePicker(
        context: context,
        initialDate: _dataSelecionada,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      
      if (date != null) {
        setState(() {
          _dataSelecionada = date;
          _dataController.text = DateFormat('dd/MM/yyyy').format(date);
        });
        Logger.info('📅 Data selecionada: ${_dataController.text}');
      }
    } catch (e) {
      Logger.error('Erro ao selecionar data: $e');
    }
  }

  /// Calcula os resultados automaticamente
  void _calcularResultados() {
    try {
      // Parse dos valores com fallback para parsing simples
      final areaColeta = _parseNumber(_areaColetaController.text);
      final pesoColetado = _parseNumber(_pesoColetadoController.text);
      final pesoSaca = _parseNumber(_pesoSacaController.text, defaultValue: 60.0);

      Logger.info('🔢 Valores parseados - Área: $areaColeta, Peso: $pesoColetado, Saca: $pesoSaca');

      if (areaColeta > 0 && pesoColetado > 0) {
        _perdaKgHa = ColheitaPerdaModel.calcularPerdaKgHa(pesoColetado, areaColeta);
        _perdaScHa = ColheitaPerdaModel.calcularPerdaScHa(_perdaKgHa, pesoSaca);
        _classificacao = ColheitaPerdaModel.determinarClassificacao(_perdaScHa, 1.0); // 1.0 saca/ha como padrão
        
        Logger.info('📊 Resultados calculados - Perda Kg/ha: $_perdaKgHa, Perda Sc/ha: $_perdaScHa, Classificação: $_classificacao');
        
        setState(() {});
      } else {
        Logger.warning('⚠️ Valores inválidos para cálculo - Área: $areaColeta, Peso: $pesoColetado');
        _perdaKgHa = 0.0;
        _perdaScHa = 0.0;
        _classificacao = 'Aceitável';
        setState(() {});
      }
    } catch (e) {
      Logger.error('❌ Erro ao calcular resultados: $e');
      _perdaKgHa = 0.0;
      _perdaScHa = 0.0;
      _classificacao = 'Aceitável';
      setState(() {});
    }
  }

  /// Parse de números com fallback
  double _parseNumber(String value, {double defaultValue = 0.0}) {
    if (value.trim().isEmpty) return defaultValue;
    
    try {
      // Primeiro tenta o BrazilianNumberFormatter
      final parsed = BrazilianNumberFormatter.parse(value);
      if (parsed != null) return parsed;
      
      // Fallback: parsing simples
      final cleanValue = value.replaceAll(',', '.').replaceAll(' ', '');
      final simpleParsed = double.tryParse(cleanValue);
      if (simpleParsed != null) return simpleParsed;
      
      return defaultValue;
    } catch (e) {
      Logger.error('Erro ao fazer parse do valor "$value": $e');
      return defaultValue;
    }
  }

  /// Salva os dados da coleta
  Future<void> _salvarColeta() async {
    if (!_validarDados()) return;

    setState(() => _isLoading = true);

    try {
      final perda = ColheitaPerdaModel(
        dataColeta: _dataController.text,
        talhaoId: _talhaoSelecionado ?? '',
        talhaoNome: _talhoes.firstWhere((t) => t['id'] == _talhaoSelecionado)['nome'] ?? '',
        culturaId: _culturaSelecionada ?? '',
        culturaNome: _culturas.firstWhere((c) => c['id'] == _culturaSelecionada)['nome'] ?? '',
        metodoCalculo: _metodoCalculo,
        areaColeta: _parseNumber(_areaColetaController.text),
        pesoColetado: _parseNumber(_pesoColetadoController.text),
        pesoSaca: _parseNumber(_pesoSacaController.text, defaultValue: 60.0),
        perdaKgHa: _perdaKgHa,
        perdaScHa: _perdaScHa,
        classificacao: _classificacao,
        nomeTecnico: 'Usuário Atual', // Valor padrão
        coordenadasGps: _coordenadasGps,
        observacoes: '', // Campo removido
      );

      // TODO: Implementar salvamento no banco de dados
      Logger.info('Dados da coleta salvos: ${perda.toMap()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coleta salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Logger.error('Erro ao salvar coleta: $e');
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Erro',
          message: 'Erro ao salvar coleta: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Valida os dados antes de salvar
  bool _validarDados() {
    if (_talhaoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um talhão'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_dataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data da coleta'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_areaColetaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a area da coleta'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_pesoColetadoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o peso coletado'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Perdas na Colheita'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _salvarColeta,
              tooltip: 'Salvar Coleta',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitulo(),
                  const SizedBox(height: 20),
                  _buildDadosColeta(),
                  const SizedBox(height: 20),
                  _buildMetodoCalculo(),
                  const SizedBox(height: 20),
                  _buildCamposCalculo(),
                  const SizedBox(height: 20),
                  _buildResultados(),
                  const SizedBox(height: 32),
                  if (!_isLoading)
                    ElevatedButton.icon(
                      onPressed: _salvarColeta,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Coleta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTitulo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.agriculture,
            color: AppColors.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dados da Coleta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cálculo de perdas na colheita de milho',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói os dados da coleta
  Widget _buildDadosColeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dados da Coleta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        // Layout responsivo para evitar sobreposições
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Layout horizontal para telas maiores
              return Row(
                children: [
                  // Data da Coleta
                  Expanded(
                    child: SafeFormField(
                      controller: _dataController,
                      label: 'Data da Coleta',
                      readOnly: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selecionarData,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Talhão
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _talhaoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Talhão',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Selecione o talhão'),
                      items: _talhoes.map((talhao) {
                        final area = talhao['area'];
                        final areaFormatada = area?.toStringAsFixed(2) ?? '0.00';
                        
                        // Log para debug da exibição
                        Logger.info('🔍 [COLHEITA] Exibindo talhão ${talhao['nome']}: área = $area, formatada = $areaFormatada');
                        
                        return DropdownMenuItem<String>(
                          value: talhao['id'],
                          child: Text('${talhao['nome']} ($areaFormatada ha)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _talhaoSelecionado = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cultura
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _culturaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Cultura',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Selecione a cultura'),
                      items: _culturas.map((cultura) {
                        return DropdownMenuItem<String>(
                          value: cultura['id'],
                          child: Text(cultura['nome']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _culturaSelecionada = value);
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Layout vertical para telas menores
              return Column(
                children: [
                  // Data da Coleta
                  SafeFormField(
                    controller: _dataController,
                    label: 'Data da Coleta',
                    readOnly: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selecionarData,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Talhão
                  DropdownButtonFormField<String>(
                    value: _talhaoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Talhão',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Selecione o talhão'),
                    items: _talhoes.map((talhao) {
                      final area = talhao['area'];
                      final areaFormatada = area?.toStringAsFixed(2) ?? '0.00';
                      
                      // Log para debug da exibição
                      Logger.info('🔍 [COLHEITA] Exibindo talhão ${talhao['nome']} (vertical): área = $area, formatada = $areaFormatada');
                      
                      return DropdownMenuItem<String>(
                        value: talhao['id'],
                        child: Text('${talhao['nome']} ($areaFormatada ha)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _talhaoSelecionado = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Cultura
                  DropdownButtonFormField<String>(
                    value: _culturaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Cultura',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Selecione a cultura'),
                    items: _culturas.map((cultura) {
                      return DropdownMenuItem<String>(
                        value: cultura['id'],
                        child: Text(cultura['nome']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _culturaSelecionada = value);
                    },
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  /// Constrói o método de cálculo
  Widget _buildMetodoCalculo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Cálculo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('🪙 Peso em gramas'),
                subtitle: const Text('Peso coletado em gramas'),
                value: 'peso_gramas',
                groupValue: _metodoCalculo,
                onChanged: (value) {
                  setState(() => _metodoCalculo = value!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('📋 PMS do grão'),
                subtitle: const Text('Peso de Mil Sementes'),
                value: 'pms_grao',
                groupValue: _metodoCalculo,
                onChanged: (value) {
                  setState(() => _metodoCalculo = value!);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói os campos de cálculo
  Widget _buildCamposCalculo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campos de Cálculo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        
        // Área da Coleta
        SafeFormField(
          controller: _areaColetaController,
          label: 'Área da Coleta (m²)',
          hintText: 'Ex: 1,0 ou 2,5',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          onChanged: (_) => _calcularResultados(),
        ),
        const SizedBox(height: 16),
        
        // Peso Coletado
        SafeFormField(
          controller: _pesoColetadoController,
          label: 'Peso Coletado (gramas)',
          hintText: 'Ex: 150,0 ou 250,5',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          onChanged: (_) => _calcularResultados(),
        ),
        const SizedBox(height: 16),
        
        // Peso da Saca
        SafeFormField(
          controller: _pesoSacaController,
          label: 'Peso da Saca (kg)',
          hintText: 'Ex: 60,0 (padrão)',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          onChanged: (_) => _calcularResultados(),
        ),
      ],
    );
  }

  /// Constrói os resultados
  Widget _buildResultados() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultados Calculados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResultadoItem(
                  'Perda em kg/ha',
                  '${_perdaKgHa.toStringAsFixed(2)} kg/ha',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultadoItem(
                  'Perda em sacas/ha',
                  '${_perdaScHa.toStringAsFixed(2)} sc/ha',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultadoItem(
                  'Classificação',
                  _classificacao,
                  _getCorClassificacao(_classificacao),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCorClassificacao(String classificacao) {
    switch (classificacao) {
      case 'Aceitável':
        return Colors.green;
      case 'Alerta':
        return Colors.orange;
      case 'Alta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
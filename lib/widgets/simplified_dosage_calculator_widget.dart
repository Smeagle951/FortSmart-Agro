import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget calculadora simplificada de doses para sementes
/// Foca na lógica de Bags + Sacas + Peso + Área conforme proposta do usuário
class SimplifiedDosageCalculatorWidget extends StatefulWidget {
  final Function(double totalSeeds, double pms, double seedsPerHectare)? onCalculationChanged;

  const SimplifiedDosageCalculatorWidget({
    Key? key,
    this.onCalculationChanged,
  }) : super(key: key);

  @override
  State<SimplifiedDosageCalculatorWidget> createState() => _SimplifiedDosageCalculatorWidgetState();
}

class _SimplifiedDosageCalculatorWidgetState extends State<SimplifiedDosageCalculatorWidget> {
  // Controllers para campos principais
  final _nomeDoseController = TextEditingController();
  final _culturaController = TextEditingController();
  final _quantidadeBagsController = TextEditingController();
  final _pesoBagController = TextEditingController();
  final _sementesSacaController = TextEditingController();
  final _sacasBagController = TextEditingController();
  final _purezaController = TextEditingController();
  final _germinacaoController = TextEditingController();
  final _areaController = TextEditingController();

  // Valores calculados
  double _totalBags = 0.0;
  double _pesoTotal = 0.0;
  double _totalSacas = 0.0;
  double _totalSementes = 0.0;
  double _pmsCalculado = 0.0;
  double _sementesViaveis = 0.0;
  double _sementesViaveisPorHectare = 0.0;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _initializeDefaultValues();
  }

  @override
  void dispose() {
    _nomeDoseController.dispose();
    _culturaController.dispose();
    _quantidadeBagsController.dispose();
    _pesoBagController.dispose();
    _sementesSacaController.dispose();
    _sacasBagController.dispose();
    _purezaController.dispose();
    _germinacaoController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  /// Configura listeners dos controladores
  void _setupControllers() {
    _quantidadeBagsController.addListener(_calculateAll);
    _pesoBagController.addListener(_calculateAll);
    _sementesSacaController.addListener(_calculateAll);
    _sacasBagController.addListener(_calculateAll);
    _purezaController.addListener(_calculateAll);
    _germinacaoController.addListener(_calculateAll);
    _areaController.addListener(_calculateAll);
  }

  /// Inicializa valores padrão
  void _initializeDefaultValues() {
    // Campos ficam vazios para o usuário inserir seus próprios dados
  }

  /// Calcula todos os valores automaticamente
  void _calculateAll() {
    try {
      final quantidadeBags = double.tryParse(_quantidadeBagsController.text.replaceAll(',', '.')) ?? 0.0;
      final pesoBag = double.tryParse(_pesoBagController.text.replaceAll(',', '.')) ?? 0.0;
      final sementesSaca = double.tryParse(_sementesSacaController.text.replaceAll(',', '.')) ?? 0.0;
      final sacasBag = double.tryParse(_sacasBagController.text.replaceAll(',', '.')) ?? 0.0;
      final pureza = double.tryParse(_purezaController.text.replaceAll(',', '.')) ?? 0.0;
      final germinacao = double.tryParse(_germinacaoController.text.replaceAll(',', '.')) ?? 0.0;
      final area = double.tryParse(_areaController.text.replaceAll(',', '.')) ?? 0.0;

      // Cálculos básicos
      _totalBags = quantidadeBags;
      _pesoTotal = quantidadeBags * pesoBag;
      _totalSacas = quantidadeBags * sacasBag;
      _totalSementes = _totalSacas * sementesSaca;

      // Cálculo do PMS (Peso de Mil Sementes)
      if (_totalSementes > 0 && _pesoTotal > 0) {
        final pesoTotalGramas = _pesoTotal * 1000; // Converter kg para g
        _pmsCalculado = (pesoTotalGramas / _totalSementes) * 1000;
      } else {
        _pmsCalculado = 0.0;
      }

      // Cálculo de sementes viáveis (corrigidas por pureza e germinação)
      if (pureza > 0 && germinacao > 0) {
        _sementesViaveis = _totalSementes * (pureza / 100) * (germinacao / 100);
      } else {
        _sementesViaveis = _totalSementes;
      }

      // Cálculo de sementes viáveis por hectare
      if (area > 0) {
        _sementesViaveisPorHectare = _sementesViaveis / area;
      } else {
        _sementesViaveisPorHectare = 0.0;
      }

      // Notificar callback
      widget.onCalculationChanged?.call(
        _totalSementes,
        _pmsCalculado,
        _sementesViaveisPorHectare,
      );

      // Atualizar UI
      setState(() {});
    } catch (e) {
      print('Erro no cálculo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            _buildHeader(),
            const SizedBox(height: 16),
            
            // Seção Informações Básicas
            _buildBasicInformation(),
            const SizedBox(height: 16),
            
            // Seção Parâmetros de Sementes
            _buildSeedParameters(),
            const SizedBox(height: 16),
            
            // Resumo dos Cálculos
            _buildCalculationSummary(),
          ],
        ),
      ),
    );
  }

  /// Constrói cabeçalho
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.grain,
            color: Colors.blue[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nova Dose de Sementes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                'Cálculo simplificado por Bags e Sacas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói seção de informações básicas
  Widget _buildBasicInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Básicas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // Nome da Dose
            TextFormField(
              controller: _nomeDoseController,
              decoration: InputDecoration(
                labelText: 'Nome da Dose',
                hintText: 'Ex: Dose Soja 2024',
                prefixIcon: Icon(Icons.science, color: Colors.blue[700]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Cultura
            TextFormField(
              controller: _culturaController,
              decoration: InputDecoration(
                labelText: 'Cultura',
                hintText: 'Ex: Soja, Milho, Algodão',
                prefixIcon: Icon(Icons.eco, color: Colors.green[700]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Área (ha)
            TextFormField(
              controller: _areaController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Área (hectares)',
                hintText: 'Ex: 1',
                suffixText: 'ha',
                prefixIcon: Icon(Icons.crop_landscape, color: Colors.orange[700]),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seção de parâmetros de sementes
  Widget _buildSeedParameters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.purple[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Parâmetros de Sementes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure os parâmetros baseados nos dados do bag de sementes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Quantidade de Bags
            TextFormField(
              controller: _quantidadeBagsController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Quantidade de Bags',
                hintText: 'Ex: 2',
                prefixIcon: Icon(Icons.inventory_2, color: Colors.blue[700]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Peso por Bag (kg)
            TextFormField(
              controller: _pesoBagController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Peso por Bag (kg)',
                hintText: 'Ex: 871,43',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.scale, color: Colors.orange[700]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Sementes por Saca
            TextFormField(
              controller: _sementesSacaController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Sementes por Saca',
                hintText: 'Ex: 140.000',
                prefixIcon: Icon(Icons.grain, color: Colors.green[700]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Sacas por Bag
            TextFormField(
              controller: _sacasBagController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Sacas por Bag',
                hintText: 'Ex: 40',
                prefixIcon: Icon(Icons.grid_view, color: Colors.purple[700]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Pureza (%)
            TextFormField(
              controller: _purezaController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Pureza (%)',
                hintText: 'Ex: 98',
                suffixText: '%',
                prefixIcon: Icon(Icons.filter_alt, color: Colors.cyan[700]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Germinação (%)
            TextFormField(
              controller: _germinacaoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Germinação (%)',
                hintText: 'Ex: 85',
                suffixText: '%',
                prefixIcon: Icon(Icons.eco, color: Colors.lightGreen[700]),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói resumo dos cálculos
  Widget _buildCalculationSummary() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumo dos Cálculos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total de Bags
            _buildSummaryRow(
              'Total de Bags:',
              '${_formatarNumero(_totalBags)} bags',
              Icons.inventory_2,
            ),
            const SizedBox(height: 8),
            
            // Peso total
            _buildSummaryRow(
              'Peso total:',
              '${_formatarNumero(_pesoTotal)} kg',
              Icons.scale,
            ),
            const SizedBox(height: 8),
            
            // Total de sacas
            _buildSummaryRow(
              'Total de sacas:',
              '${_formatarNumero(_totalSacas)} sacas',
              Icons.grid_view,
            ),
            const SizedBox(height: 8),
            
            // Total de sementes brutas
            _buildSummaryRow(
              'Total de sementes brutas:',
              '${_formatarNumero(_totalSementes)} sementes',
              Icons.grain,
            ),
            const SizedBox(height: 8),
            
            // PMS calculado
            _buildSummaryRow(
              'PMS calculado:',
              '${_formatarNumero(_pmsCalculado)} g/1000 sementes',
              Icons.analytics,
            ),
            const SizedBox(height: 8),
            
            // Total de sementes viáveis
            _buildSummaryRow(
              'Total de sementes viáveis:',
              '${_formatarNumero(_sementesViaveis)} sementes',
              Icons.verified,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            
            // Sementes viáveis por hectare
            _buildSummaryRow(
              'Sementes viáveis por hectare:',
              '${_formatarNumero(_sementesViaveisPorHectare)} sementes/ha',
              Icons.crop_landscape,
              color: Colors.orange,
            ),
            
            if (_totalBags > 0 && _pesoTotal > 0 && _totalSementes > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cálculos realizados com sucesso!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói linha do resumo
  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.blue[700], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.blue[700],
          ),
        ),
      ],
    );
  }

  /// Formata número usando padrão brasileiro
  String _formatarNumero(double valor) {
    if (valor == 0) return '0';
    
    if (valor >= 1000000) {
      return '${(valor / 1000000).toStringAsFixed(1)}M';
    } else if (valor >= 1000) {
      return '${(valor / 1000).toStringAsFixed(1)}K';
    } else if (valor == valor.toInt().toDouble()) {
      return valor.toInt().toString();
    } else {
      return valor.toStringAsFixed(2).replaceAll('.', ',');
    }
  }
}

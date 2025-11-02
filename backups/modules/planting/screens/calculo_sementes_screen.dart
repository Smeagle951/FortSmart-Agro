import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculoSementesScreen extends StatefulWidget {
  const CalculoSementesScreen({Key? key}) : super(key: key);

  @override
  State<CalculoSementesScreen> createState() => _CalculoSementesScreenState();
}

class _CalculoSementesScreenState extends State<CalculoSementesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para os campos de entrada
  final TextEditingController _populacaoController = TextEditingController();
  final TextEditingController _espacamentoController = TextEditingController();
  final TextEditingController _sementesPorMetroController = TextEditingController();
  final TextEditingController _germinacaoController = TextEditingController();
  final TextEditingController _pesoMilSementesController = TextEditingController();
  
  // Resultados do cálculo
  double _sementesPorMetro = 0.0;
  double _sementesPorHectare = 0.0;
  double _quilosPorHectare = 0.0;
  
  bool _calculoRealizado = false;

  @override
  void dispose() {
    _populacaoController.dispose();
    _espacamentoController.dispose();
    _sementesPorMetroController.dispose();
    _germinacaoController.dispose();
    _pesoMilSementesController.dispose();
    super.dispose();
  }

  // Método para calcular os resultados
  void _calcular() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final populacao = double.tryParse(_populacaoController.text) ?? 0.0;
    final espacamento = double.tryParse(_espacamentoController.text) ?? 0.0;
    final sementesPorMetro = double.tryParse(_sementesPorMetroController.text) ?? 0.0;
    final germinacao = double.tryParse(_germinacaoController.text) ?? 0.0;
    final pesoMilSementes = double.tryParse(_pesoMilSementesController.text) ?? 0.0;

    // Validações adicionais
    if (populacao <= 0 || espacamento <= 0 || sementesPorMetro <= 0 || 
        germinacao <= 0 || pesoMilSementes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os valores devem ser maiores que zero'),
          backgroundColor: Color(0xFF228B22),
        ),
      );
      return;
    }

    // Cálculos
    final plantasPorMetro = 100 / espacamento;
    final sementesPorMetroCalculado = populacao / (10000 / espacamento);
    final fatorGerminacao = 100 / germinacao;
    final sementesPorMetroAjustado = sementesPorMetroCalculado * fatorGerminacao;
    
    final sementesPorHectare = sementesPorMetroAjustado * (10000 / espacamento);
    final quilosPorHectare = (sementesPorHectare * pesoMilSementes / 1000) / 1000;

    setState(() {
      _sementesPorMetro = sementesPorMetroAjustado;
      _sementesPorHectare = sementesPorHectare;
      _quilosPorHectare = quilosPorHectare;
      _calculoRealizado = true;
    });
  }

  // Widget para campos de entrada numéricos
  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    bool allowDecimal = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        inputFormatters: [
          allowDecimal 
              ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
              : FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
          suffixText: suffix,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Campo obrigatório';
          }
          final number = double.tryParse(value);
          if (number == null) {
            return 'Valor inválido';
          }
          if (number <= 0) {
            return 'Valor deve ser maior que zero';
          }
          return null;
        },
      ),
    );
  }

  // Widget para exibir os resultados
  Widget _buildResultCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultados:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const Divider(),
            _buildResultRow(
              'Sementes por metro linear:',
              _sementesPorMetro.toStringAsFixed(1),
            ),
            _buildResultRow(
              'Sementes por hectare:',
              _sementesPorHectare.toStringAsFixed(0),
            ),
            _buildResultRow(
              'Quilos por hectare:',
              '${_quilosPorHectare.toStringAsFixed(1)} kg/ha',
            ),
          ],
        ),
      ),
    );
  }

  // Widget para exibir uma linha de resultado
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Sementes'),
        backgroundColor: const Color(0xFF228B22),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campos de entrada
              _buildNumericField(
                controller: _populacaoController,
                label: 'População desejada*',
                hint: 'Ex: 60000',
                icon: Icons.grass,
                suffix: 'plantas/ha',
              ),
              _buildNumericField(
                controller: _espacamentoController,
                label: 'Espaçamento entre linhas*',
                hint: 'Ex: 50',
                icon: Icons.space_bar,
                suffix: 'cm',
              ),
              _buildNumericField(
                controller: _sementesPorMetroController,
                label: 'Número de sementes por metro linear*',
                hint: 'Ex: 3',
                icon: Icons.grain,
              ),
              _buildNumericField(
                controller: _germinacaoController,
                label: 'Percentual de Germinação*',
                hint: 'Ex: 95',
                icon: Icons.eco,
                suffix: '%',
              ),
              _buildNumericField(
                controller: _pesoMilSementesController,
                label: 'Peso de mil sementes*',
                hint: 'Ex: 320',
                icon: Icons.scale,
                suffix: 'g',
              ),
              
              // Botão de calcular
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _calcular,
                  icon: const Icon(Icons.calculate),
                  label: const Text('CALCULAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF228B22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Resultados (exibidos apenas quando o cálculo for realizado)
              if (_calculoRealizado) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }
}

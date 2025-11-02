import 'package:flutter/material.dart';

class LossCalculationScreen extends StatefulWidget {
  @override
  _LossCalculationScreenState createState() => _LossCalculationScreenState();
}

class _LossCalculationScreenState extends State<LossCalculationScreen> {
  // Controladores para inputs
  final _grainsPerM2Ctrl = TextEditingController();
  final _pmsCtrl = TextEditingController();
  final _collectedWeightCtrl = TextEditingController();
  
  // Opções de cálculo
  String _calculationMethod = 'pms'; // Valor inicial: usar PMS
  
  // Tamanho da moldura
  double _frameSize = 1.0; // 1m² (1x1m) por padrão
  String _selectedFrameSize = '1x1';
  
  // Resultado
  double _lossResult = 0.0;
  String _resultText = '';
  
  void _calculateLoss() {
    setState(() {
      if (_calculationMethod == 'pms') {
        // Método usando PMS
        final grainsPerM2 = double.tryParse(_grainsPerM2Ctrl.text.replaceAll(',', '.')) ?? 0.0;
        final pms = double.tryParse(_pmsCtrl.text.replaceAll(',', '.')) ?? 0.0;
        
        if (grainsPerM2 > 0 && pms > 0) {
          _lossResult = (grainsPerM2 * pms) / 1000;
          _resultText = 'Perda calculada: ${_lossResult.toStringAsFixed(2)} kg/ha';
        } else {
          _resultText = 'Preencha todos os campos corretamente.';
        }
      } else {
        // Método usando peso coletado
        final collectedWeight = double.tryParse(_collectedWeightCtrl.text.replaceAll(',', '.')) ?? 0.0;
        
        if (collectedWeight > 0) {
          _lossResult = (collectedWeight / _frameSize) / 1000 * 10000; // Convertendo para kg/ha
          _resultText = 'Perda calculada: ${_lossResult.toStringAsFixed(2)} kg/ha';
        } else {
          _resultText = 'Preencha todos os campos corretamente.';
        }
      }
    });
  }
  
  void _updateFrameSize(String value) {
    setState(() {
      _selectedFrameSize = value;
      switch (value) {
        case '1x1':
          _frameSize = 1.0; // 1m²
          break;
        case '0.5x0.5':
          _frameSize = 0.25; // 0.25m²
          break;
        case '0.5x1':
          _frameSize = 0.5; // 0.5m²
          break;
        case '0.25x0.25':
          _frameSize = 0.0625; // 0.0625m²
          break;
        default:
          _frameSize = 1.0; // Padrão
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cálculo de Perda na Colheita')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tamanho da moldura:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedFrameSize,
              items: [
                DropdownMenuItem(value: '1x1', child: Text('1 x 1 m (1 m²)')),
                DropdownMenuItem(value: '0.5x0.5', child: Text('0,5 x 0,5 m (0,25 m²)')),
                DropdownMenuItem(value: '0.5x1', child: Text('0,5 x 1 m (0,5 m²)')),
                DropdownMenuItem(value: '0.25x0.25', child: Text('0,25 x 0,25 m (0,0625 m²)')),
              ],
              onChanged: (value) => _updateFrameSize(value!),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _grainsPerM2Ctrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Grãos por m²'),
            ),
            SizedBox(height: 16),
            Text('Método de cálculo:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio(
                  value: 'pms',
                  groupValue: _calculationMethod,
                  onChanged: (value) {
                    setState(() {
                      _calculationMethod = value.toString();
                    });
                  },
                ),
                Text('Usar Peso de Mil Grãos (PMS)'),
              ],
            ),
            Row(
              children: [
                Radio(
                  value: 'collected',
                  groupValue: _calculationMethod,
                  onChanged: (value) {
                    setState(() {
                      _calculationMethod = value.toString();
                    });
                  },
                ),
                Text('Usar peso dos grãos coletados'),
              ],
            ),
            SizedBox(height: 16),
            // Mostrar campo de acordo com a seleção
            if (_calculationMethod == 'pms')
              TextField(
                controller: _pmsCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Peso de mil grãos (g)'),
              )
            else
              TextField(
                controller: _collectedWeightCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Peso dos grãos coletados (g)'),
              ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _calculateLoss,
                child: Text('CALCULAR PERDA'),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                _resultText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Fórmulas utilizadas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Com PMS: Perda (kg/ha) = (Grãos/m² × PMS) / 1000',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            Text(
              'Com peso coletado: Perda (kg/ha) = (Peso coletado (g) / Área da amostra (m²)) / 1000 × 10000',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

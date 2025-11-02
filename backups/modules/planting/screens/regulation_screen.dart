import 'package:flutter/material.dart';
import '../utils/planting_calculations.dart';
import '../models/regulation_model.dart';
import '../services/regulation_service.dart';

class RegulationScreen extends StatefulWidget {
  @override
  _RegulationScreenState createState() => _RegulationScreenState();
}

class _RegulationScreenState extends State<RegulationScreen> {
  final _numRowsCtrl = TextEditingController();
  final _wheelCircCtrl = TextEditingController();
  final _testDistCtrl = TextEditingController(text: '50');
  final _rowSpacingCtrl = TextEditingController();
  final _drivingGearCtrl = TextEditingController();
  final _drivenGearCtrl = TextEditingController();
  final _targetValueCtrl = TextEditingController();
  final _targetType = ValueNotifier<String>('kg/ha');
  final _operatorCtrl = TextEditingController();
  final _machineCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<TextEditingController> _weightsCtrls = List.generate(6, (_) => TextEditingController());
  bool _salvando = false;
  String resultado = '';
  List<RegulationModel> _historico = [];
  final RegulationService _service = RegulationService();

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final hist = await _service.getHistory();
    setState(() {
      _historico = hist;
    });
  }

  Future<void> calcularESalvar() async {
    setState(() { _salvando = true; });
    final numRows = int.tryParse(_numRowsCtrl.text) ?? 0;
    final wheelCirc = double.tryParse(_wheelCircCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final testDist = double.tryParse(_testDistCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final rowSpacing = double.tryParse(_rowSpacingCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final drivingGear = int.tryParse(_drivingGearCtrl.text) ?? 0;
    final drivenGear = int.tryParse(_drivenGearCtrl.text) ?? 0;
    final targetValue = double.tryParse(_targetValueCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final weights = _weightsCtrls.map((c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0).where((v) => v > 0).toList();
    final operatorName = _operatorCtrl.text;
    final machine = _machineCtrl.text;
    final notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text;

    final g50m = PlantingCalculations.calcG50m(weights, numRows);
    final avgWeight = weights.isNotEmpty ? weights.reduce((a, b) => a + b) / weights.length : 0.0;
    final kgHa = PlantingCalculations.calcKgHa(avgWeight, rowSpacing);
    final gearRatio = PlantingCalculations.calcGearRatio(drivingGear, drivenGear);
    final metaG50m = PlantingCalculations.calcTargetG50m(targetValue, rowSpacing);

    if (numRows > 0 && wheelCirc > 0 && testDist > 0 && rowSpacing > 0 && drivingGear > 0 && drivenGear > 0 && weights.isNotEmpty && operatorName.isNotEmpty && machine.isNotEmpty) {
      final model = RegulationModel(
        dateTime: DateTime.now(),
        numRows: numRows,
        wheelCircumference: wheelCirc,
        testDistance: testDist,
        weightsPerRow: weights,
        drivingGear: drivingGear,
        drivenGear: drivenGear,
        rowSpacing: rowSpacing,
        targetType: _targetType.value,
        targetValue: targetValue,
        resultKgHa: kgHa,
        resultG50m: g50m,
        operatorName: operatorName,
        machine: machine,
        notes: notes,
        photos: null,
      );
      await _service.saveRegulation(model);
      setState(() {
        resultado = 'Kg/ha: ${kgHa.toStringAsFixed(2)} | g/50m: ${g50m.toStringAsFixed(2)} | Razão: ${gearRatio.toStringAsFixed(2)} | Meta g/50m: ${metaG50m.toStringAsFixed(2)}\n(Salvo com sucesso!)';
      });
      await _carregarHistorico();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registro salvo com sucesso!')));
    } else {
      setState(() {
        resultado = 'Preencha todos os campos obrigatórios corretamente.';
      });
    }
    setState(() { _salvando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Regulagem de Plantadeira')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _numRowsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Nº de linhas da plantadeira')),
            TextField(controller: _wheelCircCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Circunferência da roda motriz (m)')),
            TextField(controller: _testDistCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Percurso para teste (m)')),
            ...List.generate(_weightsCtrls.length, (i) => TextField(controller: _weightsCtrls[i], keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Peso linha ${i+1} (g)'))),
            TextField(controller: _drivingGearCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Engrenagem Motora (dentes)')),
            TextField(controller: _drivenGearCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Engrenagem Movida (dentes)')),
            TextField(controller: _rowSpacingCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Espaçamento entre linhas (m)')),
            Row(
              children: [
                Text('Objetivo:'),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _targetType.value,
                    onChanged: (v) => _targetType.value = v ?? 'kg/ha',
                    items: [DropdownMenuItem(value: 'kg/ha', child: Text('Kg/ha')), DropdownMenuItem(value: 'g/50m', child: Text('g/50m'))],
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(controller: _targetValueCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Meta')),
                ),
              ],
            ),
            TextField(controller: _operatorCtrl, decoration: InputDecoration(labelText: 'Operador')),
            TextField(controller: _machineCtrl, decoration: InputDecoration(labelText: 'Máquina utilizada')),
            TextField(controller: _notesCtrl, decoration: InputDecoration(labelText: 'Observações')),            
            SizedBox(height: 16),
            ElevatedButton(onPressed: _salvando ? null : calcularESalvar, child: Text(_salvando ? 'Salvando...' : 'CALCULAR E SALVAR')),
            SizedBox(height: 16),
            Text(resultado, style: TextStyle(fontWeight: FontWeight.bold)),
            Divider(),
            Text('Últimos registros:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _historico.length,
                itemBuilder: (context, idx) {
                  final item = _historico[idx];
                  return ListTile(
                    title: Text('Kg/ha: ${item.resultKgHa.toStringAsFixed(2)} | g/50m: ${item.resultG50m.toStringAsFixed(2)}'),
                    subtitle: Text('Linhas: ${item.numRows}, Espaçamento: ${item.rowSpacing}m, Motora: ${item.drivingGear}, Movida: ${item.drivenGear}'),
                    trailing: Text('${item.dateTime.day}/${item.dateTime.month} ${item.dateTime.hour}:${item.dateTime.minute.toString().padLeft(2, '0')}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

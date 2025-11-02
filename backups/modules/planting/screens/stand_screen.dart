import 'package:flutter/material.dart';
import '../utils/planting_calculations.dart';
import '../models/stand_model.dart';
import '../services/stand_service.dart';

class StandScreen extends StatefulWidget {
  @override
  _StandScreenState createState() => _StandScreenState();
}

class _StandScreenState extends State<StandScreen> {
  final _numPlantsCtrl = TextEditingController();
  final _rowSpacingCtrl = TextEditingController();
  final _evalLengthCtrl = TextEditingController();
  String resultado = '';
  bool _salvando = false;
  List<StandModel> _historico = [];
  final StandService _standService = StandService();

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final hist = await _standService.getHistory();
    setState(() {
      _historico = hist;
    });
  }

  Future<void> calcularESalvar() async {
    setState(() { _salvando = true; });
    final numPlants = int.tryParse(_numPlantsCtrl.text) ?? 0;
    final rowSpacing = double.tryParse(_rowSpacingCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final evalLength = double.tryParse(_evalLengthCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final stand = PlantingCalculations.calcStand(numPlants, rowSpacing, evalLength);
    if (stand > 0) {
      final model = StandModel(
        dateTime: DateTime.now(),
        numPlants: numPlants,
        evaluatedLength: evalLength,
        rowSpacing: rowSpacing,
        resultPlantsHa: stand,
      );
      await _standService.saveStand(model);
      setState(() {
        resultado = 'Estande salvo: ${stand.toStringAsFixed(0)} plantas/ha';
      });
      await _carregarHistorico();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registro salvo com sucesso!')));
    } else {
      setState(() {
        resultado = 'Preencha todos os campos corretamente.';
      });
    }
    setState(() { _salvando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cálculo de Estande')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _numPlantsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Nº de plantas contadas')),
            TextField(controller: _rowSpacingCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Espaçamento entre linhas (m)')),
            TextField(controller: _evalLengthCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Comprimento avaliado (m)')),
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
                    title: Text('${item.resultPlantsHa.toStringAsFixed(0)} plantas/ha'),
                    subtitle: Text('Plantas: ${item.numPlants}, Espaçamento: ${item.rowSpacing}m, Comprimento: ${item.evaluatedLength}m'),
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

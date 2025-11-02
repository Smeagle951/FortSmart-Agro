import 'package:flutter/material.dart';
import '../utils/planting_calculations.dart';
import '../models/seeds_per_hectare_model.dart';
import '../services/seeds_per_hectare_service.dart';

class SeedsPerHectareScreen extends StatefulWidget {
  @override
  _SeedsPerHectareScreenState createState() => _SeedsPerHectareScreenState();
}

class _SeedsPerHectareScreenState extends State<SeedsPerHectareScreen> {
  final _rowSpacingCtrl = TextEditingController();
  final _seedSpacingCtrl = TextEditingController();
  final _thousandSeedWeightCtrl = TextEditingController();
  final _germinationCtrl = TextEditingController();
  final _purityCtrl = TextEditingController();
  String resultado = '';
  bool _salvando = false;
  List<SeedsPerHectareModel> _historico = [];
  final SeedsPerHectareService _service = SeedsPerHectareService();

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
    final rowSpacing = double.tryParse(_rowSpacingCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final seedSpacing = double.tryParse(_seedSpacingCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final thousandSeedWeight = double.tryParse(_thousandSeedWeightCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final germination = double.tryParse(_germinationCtrl.text.replaceAll(',', '.'));
    final purity = double.tryParse(_purityCtrl.text.replaceAll(',', '.'));

    final seedsHa = PlantingCalculations.calcSeedsHa(rowSpacing, seedSpacing);
    final kgHa = PlantingCalculations.calcKgHaSeeds(seedsHa, thousandSeedWeight);
    final kgHaAjustado = PlantingCalculations.calcKgHaAdjusted(kgHa, germination, purity);

    if (rowSpacing > 0 && seedSpacing > 0 && thousandSeedWeight > 0) {
      final model = SeedsPerHectareModel(
        dateTime: DateTime.now(),
        rowSpacing: rowSpacing,
        seedSpacing: seedSpacing,
        thousandSeedWeight: thousandSeedWeight,
        germination: germination,
        purity: purity,
        resultSeedsHa: seedsHa,
        resultKgHa: kgHa,
        resultKgHaAdjusted: kgHaAjustado,
      );
      await _service.saveSeeds(model);
      setState(() {
        resultado = 'Sementes/ha: ${seedsHa.toStringAsFixed(0)}\nKg/ha: ${kgHa.toStringAsFixed(2)}\nKg/ha ajustado: ${kgHaAjustado.toStringAsFixed(2)}\n(Salvo com sucesso!)';
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
      appBar: AppBar(title: Text('Sementes por Hectare')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _rowSpacingCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Espaçamento entre linhas (m)')),
            TextField(controller: _seedSpacingCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Espaçamento entre sementes (m)')),
            TextField(controller: _thousandSeedWeightCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Peso de 1000 sementes (g)')),
            TextField(controller: _germinationCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Germinação (%) (opcional)')),
            TextField(controller: _purityCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Pureza (%) (opcional)')),
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
                    title: Text('Sementes/ha: ${item.resultSeedsHa.toStringAsFixed(0)}'),
                    subtitle: Text('Kg/ha: ${item.resultKgHa.toStringAsFixed(2)} | Kg/ha ajustado: ${item.resultKgHaAdjusted?.toStringAsFixed(2) ?? "-"}'),
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

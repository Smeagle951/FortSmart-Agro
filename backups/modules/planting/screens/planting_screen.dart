import 'package:flutter/material.dart';
import '../models/planting_record_model.dart';
import '../services/planting_record_service.dart';

class PlantingScreen extends StatefulWidget {
  @override
  _PlantingScreenState createState() => _PlantingScreenState();
}

class _PlantingScreenState extends State<PlantingScreen> {
  final _farmCtrl = TextEditingController();
  final _plotCtrl = TextEditingController();
  final _cropCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  DateTime? _plantingDate;
  final _numRowsCtrl = TextEditingController();
  final _rowSpacingCtrl = TextEditingController();
  final _sowingDensityCtrl = TextEditingController();
  final _regulationNotesCtrl = TextEditingController();
  final _operatorCtrl = TextEditingController();
  final _machineCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _gpsCtrl = TextEditingController();
  // Fotos não implementadas neste fluxo (pode ser adicionado depois)
  bool _salvando = false;
  String resultado = '';
  List<PlantingRecordModel> _historico = [];
  final PlantingRecordService _service = PlantingRecordService();

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

  Future<void> salvar() async {
    setState(() { _salvando = true; });
    final farm = _farmCtrl.text;
    final plot = _plotCtrl.text;
    final crop = _cropCtrl.text;
    final variety = _varietyCtrl.text;
    final plantingDate = _plantingDate;
    final numRows = int.tryParse(_numRowsCtrl.text) ?? 0;
    final rowSpacing = double.tryParse(_rowSpacingCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final sowingDensity = double.tryParse(_sowingDensityCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final regulationNotes = _regulationNotesCtrl.text.isEmpty ? null : _regulationNotesCtrl.text;
    final operatorName = _operatorCtrl.text;
    final machine = _machineCtrl.text;
    final notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text;
    final gps = _gpsCtrl.text.isEmpty ? null : _gpsCtrl.text;
    // Fotos não implementadas neste fluxo

    if (farm.isNotEmpty && plot.isNotEmpty && crop.isNotEmpty && variety.isNotEmpty && plantingDate != null && numRows > 0 && rowSpacing > 0 && sowingDensity > 0 && operatorName.isNotEmpty && machine.isNotEmpty) {
      final model = PlantingRecordModel(
        dateTime: DateTime.now(),
        farm: farm,
        plot: plot,
        crop: crop,
        variety: variety,
        plantingDate: plantingDate,
        numRows: numRows,
        rowSpacing: rowSpacing,
        sowingDensity: sowingDensity,
        regulationNotes: regulationNotes,
        operatorName: operatorName,
        machine: machine,
        notes: notes,
        gpsCoordinates: gps,
        photos: null,
      );
      await _service.saveRecord(model);
      setState(() {
        resultado = 'Registro salvo com sucesso!';
      });
      await _carregarHistorico();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registro de plantio salvo com sucesso!')));
    } else {
      setState(() {
        resultado = 'Preencha todos os campos obrigatórios corretamente.';
      });
    }
    setState(() { _salvando = false; });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _plantingDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Plantio')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _farmCtrl, decoration: InputDecoration(labelText: 'Fazenda')),
            TextField(controller: _plotCtrl, decoration: InputDecoration(labelText: 'Talhão')),
            TextField(controller: _cropCtrl, decoration: InputDecoration(labelText: 'Cultura')),
            TextField(controller: _varietyCtrl, decoration: InputDecoration(labelText: 'Variedade')),
            Row(
              children: [
                Text('Data do Plantio: '),
                Text(_plantingDate == null ? 'Selecione' : '${_plantingDate!.day}/${_plantingDate!.month}/${_plantingDate!.year}'),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            TextField(controller: _numRowsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Nº de linhas')),
            TextField(controller: _rowSpacingCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Espaçamento entre linhas (m)')),
            TextField(controller: _sowingDensityCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Densidade de semeadura (mil sementes/ha)')),
            TextField(controller: _regulationNotesCtrl, decoration: InputDecoration(labelText: 'Observações de regulagem')),
            TextField(controller: _operatorCtrl, decoration: InputDecoration(labelText: 'Operador')),
            TextField(controller: _machineCtrl, decoration: InputDecoration(labelText: 'Máquina utilizada')),
            TextField(controller: _notesCtrl, decoration: InputDecoration(labelText: 'Observações')),
            TextField(controller: _gpsCtrl, decoration: InputDecoration(labelText: 'Coordenadas GPS (opcional)')),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _salvando ? null : salvar, child: Text(_salvando ? 'Salvando...' : 'SALVAR')),
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
                    title: Text('${item.farm} - ${item.plot} - ${item.crop}'),
                    subtitle: Text('Variedade: ${item.variety} | Data: ${item.plantingDate.day}/${item.plantingDate.month}/${item.plantingDate.year} | Linhas: ${item.numRows}'),
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

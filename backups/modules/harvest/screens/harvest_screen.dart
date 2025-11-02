import 'package:flutter/material.dart';
import '../models/harvest_model.dart';
import '../services/harvest_service.dart';

class HarvestScreen extends StatefulWidget {
  @override
  _HarvestScreenState createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  final _farmCtrl = TextEditingController();
  final _plotCtrl = TextEditingController();
  final _cropCtrl = TextEditingController();
  final _productivityCtrl = TextEditingController();
  final _lossesCtrl = TextEditingController();
  final _operatorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  List<String> _photos = [];
  bool _salvando = false;
  String resultado = '';
  List<HarvestModel> _historico = [];
  final HarvestService _service = HarvestService();

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
    final productivity = double.tryParse(_productivityCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final losses = double.tryParse(_lossesCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final operatorName = _operatorCtrl.text;
    final notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text;
    final photos = _photos;

    if (farm.isNotEmpty && plot.isNotEmpty && crop.isNotEmpty && productivity > 0 && operatorName.isNotEmpty) {
      final model = HarvestModel(
        dateTime: DateTime.now(),
        farm: farm,
        plot: plot,
        crop: crop,
        productivity: productivity,
        losses: losses,
        operatorName: operatorName,
        notes: notes,
        photos: photos,
      );
      await _service.saveHarvest(model);
      setState(() {
        resultado = 'Registro de colheita salvo com sucesso!';
      });
      await _carregarHistorico();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registro de colheita salvo com sucesso!')));
    } else {
      setState(() {
        resultado = 'Preencha todos os campos obrigatórios corretamente.';
      });
    }
    setState(() { _salvando = false; });
  }

  Future<void> _pickImage() async {
    // Aqui você pode integrar com um picker de imagem (ex: image_picker)
    // Para exemplo, apenas simula anexar um caminho
    if (_photos.length < 2) {
      setState(() {
        _photos.add('imagem_${_photos.length + 1}.jpg');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro de Colheita')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _farmCtrl, decoration: InputDecoration(labelText: 'Fazenda')),
            TextField(controller: _plotCtrl, decoration: InputDecoration(labelText: 'Talhão')),
            TextField(controller: _cropCtrl, decoration: InputDecoration(labelText: 'Cultura')),
            TextField(controller: _productivityCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Produtividade (sacas/ha)')),
            TextField(controller: _lossesCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Perdas (sacas/ha)')),
            TextField(controller: _operatorCtrl, decoration: InputDecoration(labelText: 'Operador')),
            TextField(controller: _notesCtrl, decoration: InputDecoration(labelText: 'Observações')),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _photos.length < 2 ? _pickImage : null,
                  child: Text('Anexar imagem (${_photos.length}/2)'),
                ),
                SizedBox(width: 8),
                ..._photos.map((p) => Icon(Icons.image, color: Colors.green)).toList(),
              ],
            ),
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
                    subtitle: Text('Produtividade: ${item.productivity.toStringAsFixed(2)} sacas/ha | Perdas: ${item.losses.toStringAsFixed(2)} sacas/ha'),
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

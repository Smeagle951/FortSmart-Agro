import 'package:flutter/material.dart';
import '../models/experiment_model.dart';
import '../services/experiment_service.dart';

class ExperimentScreen extends StatefulWidget {
  @override
  _ExperimentScreenState createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> {
  final _experimentNameCtrl = TextEditingController();
  final _varietiesCtrl = TextEditingController();
  final _plotDelimitationCtrl = TextEditingController();
  DateTime? _plantingDate;
  final _conditionsCtrl = TextEditingController();
  final _treatmentsCtrl = TextEditingController();
  final _emergenceCtrl = TextEditingController();
  final _growthCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  final _finalProductivityCtrl = TextEditingController();
  final _harvestedKgCtrl = TextEditingController();
  final _harvestedBagsCtrl = TextEditingController();
  final _productivityAnalysisCtrl = TextEditingController();
  List<String> _photos = [];
  bool _salvando = false;
  String resultado = '';
  List<ExperimentModel> _historico = [];
  final ExperimentService _service = ExperimentService();

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
    final experimentName = _experimentNameCtrl.text;
    final varieties = _varietiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final plotDelimitation = _plotDelimitationCtrl.text;
    final plantingDate = _plantingDate;
    final conditions = _conditionsCtrl.text;
    final treatments = _treatmentsCtrl.text;
    final emergence = _emergenceCtrl.text;
    final growth = _growthCtrl.text;
    final health = _healthCtrl.text;
    final finalProductivity = _finalProductivityCtrl.text;
    final harvestedKg = double.tryParse(_harvestedKgCtrl.text.replaceAll(',', '.'));
    final harvestedBags = double.tryParse(_harvestedBagsCtrl.text.replaceAll(',', '.'));
    final productivityAnalysis = _productivityAnalysisCtrl.text;
    final photos = _photos;

    final evaluations = [
      ExperimentEvaluation(
        dateTime: DateTime.now(),
        type: 'Emergência',
        description: emergence.isNotEmpty ? emergence : 'Não avaliado',
      ),
      ExperimentEvaluation(
        dateTime: DateTime.now(),
        type: 'Crescimento',
        description: growth.isNotEmpty ? growth : 'Não avaliado',
      ),
      ExperimentEvaluation(
        dateTime: DateTime.now(),
        type: 'Sanidade',
        description: health.isNotEmpty ? health : 'Não avaliado',
      ),
      ExperimentEvaluation(
        dateTime: DateTime.now(),
        type: 'Produtividade Final',
        description: finalProductivity.isNotEmpty ? finalProductivity : 'Não avaliado',
      ),
    ];

    if (experimentName.isNotEmpty && varieties.isNotEmpty && plotDelimitation.isNotEmpty && plantingDate != null && conditions.isNotEmpty && treatments.isNotEmpty) {
      final model = ExperimentModel(
        dateTime: DateTime.now(),
        experimentName: experimentName,
        varieties: varieties,
        plotDelimitation: plotDelimitation,
        plantingDate: plantingDate,
        conditions: conditions,
        treatments: treatments,
        photos: photos,
        evaluations: evaluations,
        harvestedProductionKg: harvestedKg,
        harvestedProductionBags: harvestedBags,
        productivityAnalysis: productivityAnalysis,
      );
      await _service.saveExperiment(model);
      setState(() {
        resultado = 'Registro de experimento salvo com sucesso!';
      });
      await _carregarHistorico();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registro de experimento salvo com sucesso!')));
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
      appBar: AppBar(title: Text('Registro de Experimentos')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _experimentNameCtrl, decoration: InputDecoration(labelText: 'Nome do experimento')),
            TextField(controller: _varietiesCtrl, decoration: InputDecoration(labelText: 'Variedades utilizadas (separar por vírgula)')),
            TextField(controller: _plotDelimitationCtrl, decoration: InputDecoration(labelText: 'Delimitação do talhão/área (mapa ou coordenadas)')),
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
            TextField(controller: _conditionsCtrl, decoration: InputDecoration(labelText: 'Condições de plantio (espaçamento, densidade)')),
            TextField(controller: _treatmentsCtrl, decoration: InputDecoration(labelText: 'Descrição do tratamento')),
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
            Text('Avaliações', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _emergenceCtrl, decoration: InputDecoration(labelText: 'Emergência')),
            TextField(controller: _growthCtrl, decoration: InputDecoration(labelText: 'Crescimento')),
            TextField(controller: _healthCtrl, decoration: InputDecoration(labelText: 'Sanidade')),
            TextField(controller: _finalProductivityCtrl, decoration: InputDecoration(labelText: 'Produtividade final')),
            TextField(controller: _harvestedKgCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Produção colhida (Kg)')),
            TextField(controller: _harvestedBagsCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Produção colhida (sacas)')),
            TextField(controller: _productivityAnalysisCtrl, decoration: InputDecoration(labelText: 'Análise de produtividade (gráfico/relatório)')),
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
                    title: Text(item.experimentName),
                    subtitle: Text('Variedades: ${item.varieties.join(", ")} | Data: ${item.plantingDate.day}/${item.plantingDate.month}/${item.plantingDate.year}'),
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

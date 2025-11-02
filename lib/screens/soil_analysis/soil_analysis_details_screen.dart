import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/soil_analysis_repository.dart';
import '../../repositories/prescription_repository.dart';
import '../../database/models/soil_analysis.dart';
import '../../services/agricultural_calculator.dart';
import '../prescription/add_prescription_screen.dart';
import '../soil_analysis/add_soil_analysis_screen.dart';

class SoilAnalysisDetailsScreen extends StatefulWidget {
  final int analysisId;

  const SoilAnalysisDetailsScreen({
    Key? key,
    required this.analysisId,
  }) : super(key: key);

  @override
  _SoilAnalysisDetailsScreenState createState() =>
      _SoilAnalysisDetailsScreenState();
}

class _SoilAnalysisDetailsScreenState extends State<SoilAnalysisDetailsScreen> {
  final SoilAnalysisRepository _repository = SoilAnalysisRepository();
  final PrescriptionRepository _prescriptionRepository = PrescriptionRepository();
  final AgriculturalCalculator _calculator = AgriculturalCalculator();

  SoilAnalysis? _analysis;
  bool _isLoading = true;
  bool _hasPrescription = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _analysis = await _repository.getSoilAnalysisById(widget.analysisId);
      
      if (_analysis != null) {
        // Verificar se já existe uma prescrição para esta análise
        final prescriptions = await _prescriptionRepository
            .getPrescriptionsBySoilAnalysisId(_analysis!.id!);
        _hasPrescription = prescriptions.isNotEmpty;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar análise: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Análise #${widget.analysisId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditAnalysis,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null
              ? _buildAnalysisNotFound()
              : _buildAnalysisDetails(),
      floatingActionButton: _analysis != null && !_hasPrescription
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreatePrescription,
              icon: const Icon(Icons.add_chart),
              label: const Text('Gerar Prescrição'),
            )
          : null,
    );
  }

  Widget _buildAnalysisNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Análise não encontrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildParametersCard(),
          const SizedBox(height: 16),
          _buildInterpretationCard(),
          const SizedBox(height: 16),
          if (_hasPrescription) _buildPrescriptionCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Gerais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            _buildInfoRow('ID', '${_analysis!.id}'),
            _buildInfoRow('Data de Criação', _formatDate(_analysis!.createdAt)),
            _buildInfoRow('ID do Monitoramento', '${_analysis!.monitoringId}'),
            _buildInfoRow('Sincronizado', _analysis!.synced ? 'Sim' : 'Não'),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parâmetros da Análise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            _buildParameterRow(
              'pH',
              _analysis!.ph?.toStringAsFixed(2) ?? 'N/A',
              _getPhColor(_analysis!.ph),
            ),
            _buildParameterRow(
              'Matéria Orgânica',
              _analysis!.organicMatter != null
                  ? '${_analysis!.organicMatter!.toStringAsFixed(2)}%'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'Fósforo',
              _analysis!.phosphorus != null
                  ? '${_analysis!.phosphorus!.toStringAsFixed(2)} mg/dm³'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'Potássio',
              _analysis!.potassium != null
                  ? '${_analysis!.potassium!.toStringAsFixed(2)} mmolc/dm³'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'Cálcio',
              _analysis!.calcium != null
                  ? '${_analysis!.calcium!.toStringAsFixed(2)} mmolc/dm³'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'Magnésio',
              _analysis!.magnesium != null
                  ? '${_analysis!.magnesium!.toStringAsFixed(2)} mmolc/dm³'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'Enxofre',
              _analysis!.sulfur != null
                  ? '${_analysis!.sulfur!.toStringAsFixed(2)} mg/dm³'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'Alumínio',
              _analysis!.aluminum != null
                  ? '${_analysis!.aluminum!.toStringAsFixed(2)} mmolc/dm³'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'CTC',
              _analysis!.cationExchangeCapacity != null
                  ? '${_analysis!.cationExchangeCapacity!.toStringAsFixed(2)} mmolc/dm³'
                  : 'N/A',
              null,
            ),
            _buildParameterRow(
              'Saturação por Bases',
              _analysis!.baseSaturation != null
                  ? '${_analysis!.baseSaturation!.toStringAsFixed(2)}%'
                  : 'N/A',
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpretationCard() {
    if (_analysis!.ph == null &&
        _analysis!.organicMatter == null &&
        _analysis!.phosphorus == null &&
        _analysis!.potassium == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interpretação da Análise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            if (_analysis!.ph != null)
              _buildInterpretationRow(
                'pH',
                _calculator.interpretSoilPh(_analysis!.ph!),
              ),
            if (_analysis!.organicMatter != null)
              _buildInterpretationRow(
                'Matéria Orgânica',
                _calculator.interpretOrganicMatter(_analysis!.organicMatter!),
              ),
            if (_analysis!.phosphorus != null)
              _buildInterpretationRow(
                'Fósforo',
                _calculator.interpretPhosphorus(_analysis!.phosphorus!, 'médio'),
              ),
            if (_analysis!.potassium != null)
              _buildInterpretationRow(
                'Potássio',
                _calculator.interpretPotassium(_analysis!.potassium!),
              ),
            if (_analysis!.baseSaturation != null)
              _buildInterpretationRow(
                'Saturação por Bases',
                _calculator.interpretBaseSaturation(_analysis!.baseSaturation!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Card(
      elevation: 3,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prescrição Existente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: _navigateToViewPrescription,
                  child: const Text('Ver Prescrição'),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Uma prescrição já foi gerada com base nesta análise de solo. Clique no botão acima para visualizá-la.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationRow(String parameter, String interpretation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parameter,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            interpretation,
            style: const TextStyle(fontSize: 15),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Color _getPhColor(double? ph) {
    if (ph == null) return Colors.grey;
    
    if (ph < 5.0) return Colors.red;
    if (ph < 5.5) return Colors.orange;
    if (ph < 6.5) return Colors.green;
    if (ph < 7.5) return Colors.blue;
    return Colors.purple;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data desconhecida';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'Data inválida';
    }
  }

  void _navigateToEditAnalysis() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSoilAnalysisScreen(
          monitoringId: _analysis!.monitoringId,
          analysisId: _analysis!.id,
        ),
      ),
    );

    if (result == true) {
      _loadAnalysis();
    }
  }

  void _navigateToCreatePrescription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPrescriptionScreen(
          soilAnalysisId: _analysis!.id!,
        ),
      ),
    );

    if (result == true) {
      _loadAnalysis();
    }
  }

  void _navigateToViewPrescription() async {
    try {
      final prescriptions = await _prescriptionRepository
          .getPrescriptionsBySoilAnalysisId(_analysis!.id!);
      
      if (prescriptions.isNotEmpty) {
        // Navegar para a tela de detalhes da prescrição
        Navigator.pushNamed(
          context,
          '/prescription_details',
          arguments: {'prescriptionId': prescriptions.first.id},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma prescrição encontrada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar prescrição: $e')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir esta análise de solo? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnalysis();
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnalysis() async {
    if (_analysis == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _repository.deleteSoilAnalysis(_analysis!.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Análise excluída com sucesso')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir análise: $e')),
      );
    }
  }
}

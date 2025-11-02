import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pesticide_application.dart';
import '../../services/pesticide_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/safe_text.dart';

class PesticideApplicationListScreen extends StatefulWidget {
  const PesticideApplicationListScreen({Key? key}) : super(key: key);

  @override
  _PesticideApplicationListScreenState createState() => _PesticideApplicationListScreenState();
}

class _PesticideApplicationListScreenState extends State<PesticideApplicationListScreen> {
  final PesticideService _pesticideService = PesticideService();
  
  List<PesticideApplication> _applications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }
  
  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      final applications = await _pesticideService.getAllApplications();
      
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      SnackbarHelper.showError(context, 'Erro ao carregar aplicações: $e');
    }
  }
  
  void _navigateToAddApplication() {
    // Implementar navegação para tela de adicionar aplicação
    SnackbarHelper.showInfo(context, 'Funcionalidade em desenvolvimento');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SafeText('Aplicações de Defensivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _applications.isEmpty
                  ? _buildEmptyState()
                  : _buildApplicationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddApplication,
        child: const Icon(Icons.add),
        tooltip: 'Nova Aplicação',
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          SafeText(
            'Ocorreu um erro ao carregar os dados',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SafeText(
            _errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadApplications,
            child: const SafeText('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            color: Colors.grey[400],
            size: 80,
          ),
          const SizedBox(height: 16),
          const SafeText(
            'Nenhuma aplicação registrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const SafeText(
            'Registre suas aplicações de defensivos para\nmonitorar o uso de produtos em suas lavouras.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddApplication,
            icon: const Icon(Icons.add),
            label: const SafeText('Registrar Aplicação'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildApplicationsList() {
    return ListView.builder(
      itemCount: _applications.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final application = _applications[index];
        return _buildApplicationItem(application);
      },
    );
  }
  
  Widget _buildApplicationItem(PesticideApplication application) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final applicationDate = dateFormat.format(application.applicationDate);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                SafeText(
                  'Data: $applicationDate',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.science, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: SafeText(
                    'Produto: ${application.productName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.straighten, size: 16),
                const SizedBox(width: 8),
                SafeText(
                  'Dose: ${application.dose} ${application.doseUnit}',
                ),
              ],
            ),
            if (application.pestName != null && application.pestName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.pest_control, size: 16),
                    const SizedBox(width: 8),
                    SafeText(
                      'Alvo: ${application.pestName}',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Botões removidos para produção
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

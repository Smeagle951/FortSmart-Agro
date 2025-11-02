import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pesticide_application.dart';
import '../../repositories/pesticide_application_repository.dart';
import '../../widgets/loading_indicator.dart';

class PesticideApplicationDetailsScreen extends StatefulWidget {
  final String applicationId;

  const PesticideApplicationDetailsScreen({Key? key, required this.applicationId}) : super(key: key);

  @override
  _PesticideApplicationDetailsScreenState createState() => _PesticideApplicationDetailsScreenState();
}

class _PesticideApplicationDetailsScreenState extends State<PesticideApplicationDetailsScreen> {
  final PesticideApplicationRepository _repository = PesticideApplicationRepository();
  PesticideApplication? _application;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final application = await _repository.getPesticideApplicationById(widget.applicationId);
      setState(() {
        _application = application;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Aplicação'),
        // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/application/form',
                arguments: {'applicationId': widget.applicationId},
              ).then((_) => _loadApplication());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _application == null
              ? const Center(
                  child: Text('Registro não encontrado'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho com título e produto
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF90CAF9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_drink_outlined,
                                  color: Color(0xFF0D47A1),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _application!.productName ?? 'Produto não especificado',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.grass,
                                  color: Color(0xFF0D47A1),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cultura: ${_application!.cropName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF0D47A1),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Data: ${DateFormat('dd/MM/yyyy').format(_application!.date)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Dados da aplicação
                      _buildSectionCard(
                        'Dados da Aplicação',
                        [
                          _buildDetailRow('Dose por hectare', '${_application!.dosePerHa} ${_application!.doseUnit}/ha'),
                          _buildDetailRow('Volume de calda', '${_application!.caldaVolumePerHa} L/ha'),
                          _buildDetailRow('Área total', '${_application!.totalArea} ha'),
                          _buildDetailRow('Tipo de aplicação', _application!.applicationType == ApplicationType.ground ? 'Terrestre' : 'Aérea'),
                          _buildDetailRow('Responsável', _application!.responsible),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Totais calculados
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Totais Calculados',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Volume total de calda:',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${_application!.totalCaldaVolume.toStringAsFixed(2)} L',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quantidade total de produto:',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${_application!.totalProductAmount.toStringAsFixed(2)} ${_application!.doseUnit}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Condições climáticas
                      if (_application!.temperature != null || _application!.humidity != null)
                        _buildSectionCard(
                          'Condições Climáticas',
                          [
                            if (_application!.temperature != null)
                              _buildDetailRow('Temperatura', '${_application!.temperature}°C'),
                            if (_application!.humidity != null)
                              _buildDetailRow('Umidade relativa', '${_application!.humidity}%'),
                          ],
                        ),
                      
                      if (_application!.temperature != null || _application!.humidity != null)
                        const SizedBox(height: 24),
                      
                      // Observações
                      if (_application!.observations != null && _application!.observations!.isNotEmpty)
                        _buildSectionCard(
                          'Observações',
                          [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(_application!.observations!),
                            ),
                          ],
                        ),
                      
                      if (_application!.observations != null && _application!.observations!.isNotEmpty)
                        const SizedBox(height: 24),
                      
                      // Imagens
                      if (_application!.imageUrls != null && _application!.imageUrls!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Imagens',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _application!.imageUrls!.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        // Exibir imagem em tela cheia
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Scaffold(
                                              appBar: AppBar(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                              ),
                                              body: Center(
                                                child: Image.asset(
                                                  _application!.imageUrls![index],
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              backgroundColor: Colors.black,
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          _application!.imageUrls![index],
                                          height: 200,
                                          width: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      
                      if (_application!.imageUrls != null && _application!.imageUrls!.isNotEmpty)
                        const SizedBox(height: 24),
                      
                      // Informações de segurança
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '⚠️ Informações de Segurança',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Lembre-se de utilizar os Equipamentos de Proteção Individual (EPIs) adequados durante a aplicação de defensivos agrícolas. Siga sempre as recomendações do fabricante e a legislação vigente.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF795548),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Informações do registro
                      Text(
                        'Registro criado em: ${_application!.createdAt != null ? DateFormat('dd/MM/yyyy').format(_application!.createdAt!) : "N/A"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (_application!.updatedAt != null)
                        Text(
                          'Última atualização: ${DateFormat('dd/MM/yyyy').format(_application!.updatedAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Botão para gerar relatório PDF
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Implementar geração de PDF
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gerando relatório PDF...')),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text(
                            'GERAR RELATÓRIO PDF',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

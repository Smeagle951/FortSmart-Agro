import 'package:flutter/material.dart';
import 'soil_compaction_form_screen.dart';
import 'soil_compaction_history_screen.dart';
import 'soil_compaction_repository.dart';

class SoilCompactionMainScreen extends StatefulWidget {
  const SoilCompactionMainScreen({Key? key}) : super(key: key);

  @override
  _SoilCompactionMainScreenState createState() => _SoilCompactionMainScreenState();
}

class _SoilCompactionMainScreenState extends State<SoilCompactionMainScreen> {
  final _repository = SoilCompactionRepository();
  bool _isLoading = false;
  int _totalRegistros = 0;

  @override
  void initState() {
    super.initState();
    _carregarTotalRegistros();
  }

  Future<void> _carregarTotalRegistros() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final registros = await _repository.listarCompactacoes();
      setState(() {
        _totalRegistros = registros.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar registros: $e'),
          backgroundColor: Colors.red,
        ),
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
        title: const Text('Compactação de Solo'),
        backgroundColor: const Color(0xFF8B4513), // Cor marrom para representar solo
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resistência à Penetração do Solo (RP)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Calcule a resistência à penetração do solo e obtenha interpretação automática dos resultados.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildOptionCard(
                    title: 'Novo Cálculo',
                    description: 'Realize um novo cálculo de compactação do solo.',
                    icon: Icons.add_circle,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoilCompactionFormScreen(),
                      ),
                    ).then((_) => _carregarTotalRegistros()),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    title: 'Histórico',
                    description: 'Visualize o histórico de cálculos realizados.',
                    icon: Icons.history,
                    color: Colors.blue,
                    count: _totalRegistros,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoilCompactionHistoryScreen(),
                      ),
                    ).then((_) => _carregarTotalRegistros()),
                  ),
                  const SizedBox(height: 24),
                  const ExpansionTile(
                    title: Text('Sobre a Compactação de Solo'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'O que é Resistência à Penetração (RP)?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'A resistência à penetração é uma medida da compactação do solo, '
                              'expressa em MPa (Megapascal). Valores elevados indicam maior '
                              'dificuldade para o desenvolvimento das raízes das plantas.',
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Interpretação dos Resultados:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text('• Baixa: < 1,0 MPa - Sem restrição ao crescimento radicular'),
                            Text('• Média: 1,0 a 2,0 MPa - Pouca restrição ao crescimento radicular'),
                            Text('• Alta: 2,0 a 3,0 MPa - Restrição moderada ao crescimento radicular'),
                            Text('• Muito Alta: > 3,0 MPa - Alta restrição ao crescimento radicular'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? count,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (count != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/calda/product.dart';
import '../../models/calda/calda_config.dart';
import '../../services/calda/calda_service.dart';
import '../../services/calda/calda_calculation_service.dart';
import 'pre_calda_screen.dart';
import 'jar_test_screen.dart';

class CaldaCalculationScreen extends StatefulWidget {
  final List<Product> products;
  final CaldaConfig config;

  const CaldaCalculationScreen({
    Key? key,
    required this.products,
    required this.config,
  }) : super(key: key);

  @override
  State<CaldaCalculationScreen> createState() => _CaldaCalculationScreenState();
}

class _CaldaCalculationScreenState extends State<CaldaCalculationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final CaldaService _caldaService = CaldaService.instance;
  RecipeCalculationResult? _calculationResult;
  List<String> _compatibilityWarnings = [];
  List<Product> _mixingOrder = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateRecipe();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateRecipe() {
    setState(() {
      _calculationResult = _caldaService.calculateRecipe(widget.products, widget.config);
      _compatibilityWarnings = _caldaService.checkCompatibility(widget.products);
      _mixingOrder = _caldaService.getMixingOrder(widget.products);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_calculationResult == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado do Cálculo'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Produtos e Doses', icon: Icon(Icons.inventory)),
            Tab(text: 'Pré-Calda', icon: Icon(Icons.local_drink)),
            Tab(text: 'Teste de Calda', icon: Icon(Icons.science)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildPreCaldaTab(),
          _buildJarTestTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo da configuração
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuração da Calda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Volume da Calda', '${_calculationResult!.totalVolume.toStringAsFixed(0)} L'),
                  _buildInfoRow('Vazão', '${widget.config.flowRate.toStringAsFixed(0)} ${widget.config.isFlowPerHectare ? 'L/ha' : 'L/alqueire'}'),
                  _buildInfoRow('Área Coberta', '${_calculationResult!.hectaresCovered.toStringAsFixed(2)} ha'),
                  _buildInfoRow('Volume por Hectare', '${_calculationResult!.volumePerHectare.toStringAsFixed(0)} L/ha'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Lista de produtos e doses
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produtos e Doses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ..._calculationResult!.products.asMap().entries.map((entry) {
                    int index = entry.key;
                    ProductCalculationResult result = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2E7D32),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          result.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${result.product.manufacturer} • ${result.product.formulation.code}'),
                            const SizedBox(height: 4),
                            Text(
                              'Dose: ${result.product.dose} ${result.product.doseUnit.symbol}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${result.displayValue} ${result.displayUnit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            Text(
                              'Total no tanque',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Ordem de mistura
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sort, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text(
                        'Ordem de Mistura Sugerida',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ..._mixingOrder.asMap().entries.map((entry) {
                    int index = entry.key;
                    Product product = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF2E7D32),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${product.formulation.code} - ${product.manufacturer}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          // Avisos de compatibilidade
          if (_compatibilityWarnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Avisos de Compatibilidade',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ..._compatibilityWarnings.map((warning) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Text(
                        warning,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreCaldaTab() {
    return PreCaldaScreen(
      products: widget.products,
      config: widget.config,
    );
  }

  Widget _buildJarTestTab() {
    return JarTestScreen(
      products: widget.products,
      config: widget.config,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

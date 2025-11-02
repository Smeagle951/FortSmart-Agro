import 'package:flutter/material.dart';
import '../../models/calda/product.dart';
import '../../models/calda/calda_config.dart';
import 'tabs/product_dose_tab.dart';
import 'tabs/precalda_tab.dart';
import 'tabs/jar_test_tab.dart';

class CaldaAdvancedMainScreen extends StatefulWidget {
  const CaldaAdvancedMainScreen({Key? key}) : super(key: key);

  @override
  State<CaldaAdvancedMainScreen> createState() => _CaldaAdvancedMainScreenState();
}

class _CaldaAdvancedMainScreenState extends State<CaldaAdvancedMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Dados compartilhados entre as abas
  CaldaConfig? _caldaConfig;
  List<Product> _products = [];
  List<String> _mixingOrder = [];
  List<String> _compatibilityWarnings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaldaFlex Avançado'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: const Color(0xFF2E7D32),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.inventory, size: 20),
                  text: 'Produto & Dose',
                ),
                Tab(
                  icon: Icon(Icons.local_drink, size: 20),
                  text: 'Pré-Calda',
                ),
                Tab(
                  icon: Icon(Icons.science, size: 20),
                  text: 'Teste de Calda',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProductDoseTab(
            onDataChanged: _onProductDoseDataChanged,
            caldaConfig: _caldaConfig,
            products: _products,
            mixingOrder: _mixingOrder,
            compatibilityWarnings: _compatibilityWarnings,
          ),
          PreCaldaTab(
            caldaConfig: _caldaConfig,
            products: _products,
          ),
          JarTestTab(
            products: _products,
            caldaConfig: _caldaConfig,
          ),
        ],
      ),
    );
  }

  void _onProductDoseDataChanged({
    CaldaConfig? config,
    List<Product>? products,
    List<String>? mixingOrder,
    List<String>? warnings,
  }) {
    setState(() {
      _caldaConfig = config;
      _products = products ?? [];
      _mixingOrder = mixingOrder ?? [];
      _compatibilityWarnings = warnings ?? [];
    });
  }
}

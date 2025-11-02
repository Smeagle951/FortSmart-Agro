import 'package:flutter/material.dart';
import '../../models/calda/calda_recipe.dart';
import '../../services/calda/calda_service.dart';
import 'calda_config_screen.dart';
import 'calda_recipes_screen.dart';

class CaldaMainScreen extends StatefulWidget {
  const CaldaMainScreen({Key? key}) : super(key: key);

  @override
  State<CaldaMainScreen> createState() => _CaldaMainScreenState();
}

class _CaldaMainScreenState extends State<CaldaMainScreen> {
  final CaldaService _caldaService = CaldaService.instance;
  List<CaldaRecipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await _caldaService.getRecipes();
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erro ao carregar receitas: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo Calda'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header com informações
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.science_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cálculo de Calda Agrícola',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Configure volume, vazão e produtos para sua aplicação',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Botões de ação
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Botão Nova Receita
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToNewRecipe(),
                          icon: const Icon(Icons.add_circle_outline, size: 24),
                          label: const Text(
                            'Nova Receita',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Botão Ver Receitas
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToRecipes(),
                          icon: const Icon(Icons.list_alt, size: 20),
                          label: const Text(
                            'Ver Receitas Salvas',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Estatísticas rápidas
                if (_recipes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Receitas', _recipes.length.toString(), Icons.science),
                        _buildStatCard('Produtos', _getTotalProducts().toString(), Icons.inventory),
                        _buildStatCard('Última', _getLastRecipeDate(), Icons.schedule),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // Informações adicionais
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2E7D32),
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Configure volume da calda, vazão por hectare ou alqueire, e adicione produtos com suas respectivas dosagens.',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  int _getTotalProducts() {
    return _recipes.fold(0, (sum, recipe) => sum + recipe.products.length);
  }

  String _getLastRecipeDate() {
    if (_recipes.isEmpty) return '-';
    final lastRecipe = _recipes.reduce((a, b) => 
        a.createdAt.isAfter(b.createdAt) ? a : b);
    return '${lastRecipe.createdAt.day}/${lastRecipe.createdAt.month}';
  }

  void _navigateToNewRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CaldaConfigScreen(),
      ),
    ).then((_) => _loadRecipes());
  }

  void _navigateToRecipes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CaldaRecipesScreen(),
      ),
    ).then((_) => _loadRecipes());
  }
}

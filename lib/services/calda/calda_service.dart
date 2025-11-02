import '../../models/calda/product.dart';
import '../../models/calda/calda_recipe.dart';
import '../../models/calda/calda_config.dart';
import '../../database/calda/daos/product_dao.dart';
import '../../database/calda/daos/recipe_dao.dart';
import 'calda_calculation_service.dart';

/// Serviço principal do módulo Calda
class CaldaService {
  static CaldaService? _instance;
  
  CaldaService._();
  
  static CaldaService get instance {
    _instance ??= CaldaService._();
    return _instance!;
  }

  // === PRODUTOS ===
  
  /// Adiciona um novo produto
  Future<int> addProduct(Product product) async {
    return await ProductDao.insert(product);
  }

  /// Busca todos os produtos
  Future<List<Product>> getProducts() async {
    return await ProductDao.findAll();
  }

  /// Busca produto por ID
  Future<Product?> getProduct(int id) async {
    return await ProductDao.findById(id);
  }

  /// Atualiza um produto
  Future<int> updateProduct(Product product) async {
    return await ProductDao.update(product);
  }

  /// Remove um produto
  Future<int> deleteProduct(int id) async {
    return await ProductDao.delete(id);
  }

  /// Busca produtos por fabricante
  Future<List<Product>> getProductsByManufacturer(String manufacturer) async {
    return await ProductDao.findByManufacturer(manufacturer);
  }

  /// Busca produtos por formulação
  Future<List<Product>> getProductsByFormulation(String formulation) async {
    return await ProductDao.findByFormulation(formulation);
  }

  // === RECEITAS ===
  
  /// Adiciona uma nova receita
  Future<int> addRecipe(CaldaRecipe recipe) async {
    return await RecipeDao.insert(recipe);
  }

  /// Busca todas as receitas
  Future<List<CaldaRecipe>> getRecipes() async {
    return await RecipeDao.findAll();
  }

  /// Busca receita por ID
  Future<CaldaRecipe?> getRecipe(int id) async {
    return await RecipeDao.findById(id);
  }

  /// Atualiza uma receita
  Future<int> updateRecipe(CaldaRecipe recipe) async {
    return await RecipeDao.update(recipe);
  }

  /// Remove uma receita
  Future<int> deleteRecipe(int id) async {
    return await RecipeDao.delete(id);
  }

  // === CÁLCULOS ===
  
  /// Calcula receita completa
  RecipeCalculationResult calculateRecipe(
    List<Product> products,
    CaldaConfig config,
  ) {
    return CaldaCalculationService.calculateRecipe(products, config);
  }

  /// Calcula pré-calda
  RecipeCalculationResult calculatePreCalda(
    List<Product> products,
    CaldaConfig originalConfig,
    double preCaldaVolume,
  ) {
    return CaldaCalculationService.calculatePreCalda(
      products,
      originalConfig,
      preCaldaVolume,
    );
  }

  /// Sugere ordem de mistura
  List<Product> getMixingOrder(List<Product> products) {
    return CaldaCalculationService.getMixingOrder(products);
  }

  // === VALIDAÇÕES ===
  
  /// Valida se a receita está correta
  List<String> validateRecipe(List<Product> products, CaldaConfig config) {
    List<String> errors = [];
    
    if (products.isEmpty) {
      errors.add('Adicione pelo menos um produto à receita');
    }
    
    if (config.volumeLiters <= 0) {
      errors.add('Volume da calda deve ser maior que zero');
    }
    
    if (config.flowRate <= 0) {
      errors.add('Vazão deve ser maior que zero');
    }
    
    if (config.area <= 0) {
      errors.add('Área deve ser maior que zero');
    }
    
    // Verifica se há produtos duplicados
    Set<String> productNames = {};
    for (Product product in products) {
      if (productNames.contains(product.name)) {
        errors.add('Produto "${product.name}" está duplicado');
      }
      productNames.add(product.name);
    }
    
    return errors;
  }

  /// Verifica compatibilidade entre produtos
  List<String> checkCompatibility(List<Product> products) {
    List<String> warnings = [];
    
    // Regras básicas de compatibilidade
    for (int i = 0; i < products.length; i++) {
      for (int j = i + 1; j < products.length; j++) {
        Product product1 = products[i];
        Product product2 = products[j];
        
        // Verifica incompatibilidades conhecidas
        if (_areIncompatible(product1, product2)) {
          warnings.add(
            '⚠️ ${product1.name} (${product1.formulation.code}) pode ser '
            'incompatível com ${product2.name} (${product2.formulation.code})'
          );
        }
      }
    }
    
    return warnings;
  }

  /// Verifica se dois produtos são incompatíveis
  bool _areIncompatible(Product product1, Product product2) {
    // Regras básicas de incompatibilidade
    List<String> incompatiblePairs = [
      'EC+WP', 'WP+EC', // Emulsão com pó molhável
      'SC+WP', 'WP+SC', // Suspensão com pó molhável
    ];
    
    String pair1 = '${product1.formulation.code}+${product2.formulation.code}';
    String pair2 = '${product2.formulation.code}+${product1.formulation.code}';
    
    return incompatiblePairs.contains(pair1) || incompatiblePairs.contains(pair2);
  }
}

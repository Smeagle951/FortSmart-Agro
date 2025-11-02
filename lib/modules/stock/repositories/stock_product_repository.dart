import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_product_model.dart';

class StockProductRepository {
  static const String _storageKey = 'stock_products';
  
  // Cache em memória para performance
  List<StockProduct> _products = [];
  bool _isInitialized = false;

  /// Inicializa o repositório carregando dados do storage
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 Inicializando StockProductRepository...');
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey(_storageKey)) {
        print('📝 Chave $_storageKey não encontrada, criando lista vazia');
        _products = [];
        _isInitialized = true;
        return;
      }
      
      final productsJson = prefs.getStringList(_storageKey) ?? [];
      print('📊 Produtos encontrados no storage: ${productsJson.length}');
      
      _products = [];
      for (int i = 0; i < productsJson.length; i++) {
        try {
          final json = productsJson[i];
          final map = jsonDecode(json) as Map<String, dynamic>;
          final product = StockProduct.fromJson(map);
          _products.add(product);
        } catch (e) {
          print('⚠️ Erro ao carregar produto $i: $e');
          // Continuar carregando outros produtos
        }
      }
      
      // Limpar produtos de exemplo automaticamente
      await _limparProdutosExemploAutomaticamente();
      
      _isInitialized = true;
      print('✅ StockProductRepository inicializado com ${_products.length} produtos válidos');
    } catch (e) {
      print('❌ Erro ao inicializar StockProductRepository: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _products = [];
      _isInitialized = true;
    }
  }

  /// Salva produtos no storage
  Future<void> _saveToStorage() async {
    try {
      print('🔄 Salvando ${_products.length} produtos no storage...');
      final prefs = await SharedPreferences.getInstance();
      
      final productsJson = <String>[];
      for (int i = 0; i < _products.length; i++) {
        try {
          final product = _products[i];
          final json = jsonEncode(product.toJson());
          productsJson.add(json);
        } catch (e) {
          print('⚠️ Erro ao serializar produto $i: $e');
          // Continuar com outros produtos
        }
      }
      
      await prefs.setStringList(_storageKey, productsJson);
      print('✅ Produtos salvos no storage: ${productsJson.length} produtos');
    } catch (e) {
      print('❌ Erro ao salvar produtos no storage: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Serviço de armazenamento não disponível: $e');
    }
  }

  Future<List<StockProduct>> getAll() async {
    try {
      await _initialize();
      
      // Filtrar produtos de exemplo para garantir que apenas produtos reais sejam retornados
      final produtosReais = _products.where((produto) {
        final nomeProduto = produto.name.toLowerCase();
        final produtosExemplo = [
          'ticlopir',
          'fusão',
          'acetameprid',
          'roundup original',
          'fertilizante npk 20-20-20',
          'inseticida decis',
          'glifosato 480',
          'npk 20-20-20',
          'semente de soja rr',
        ];
        
        return !produtosExemplo.any((exemplo) => nomeProduto.contains(exemplo));
      }).toList();
      
      print('📦 Retornando ${produtosReais.length} produtos reais (${_products.length - produtosReais.length} produtos de exemplo filtrados)');
      return List.unmodifiable(produtosReais);
    } catch (e) {
      print('❌ Erro ao obter produtos: $e');
      throw Exception('Serviço de armazenamento não disponível: $e');
    }
  }

  Future<StockProduct?> getById(String id) async {
    await _initialize();
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> insert(StockProduct product) async {
    try {
      await _initialize();
      
      // Verificar se já existe um produto com o mesmo nome
      final existingIndex = _products.indexWhere((p) => p.name.toLowerCase() == product.name.toLowerCase());
      if (existingIndex != -1) {
        throw Exception('Já existe um produto com o nome "${product.name}"');
      }
      
      _products.add(product);
      await _saveToStorage();
      print('✅ Produto adicionado: ${product.name}');
    } catch (e) {
      print('❌ Erro ao inserir produto: $e');
      if (e.toString().contains('Serviço de armazenamento')) {
        rethrow;
      }
      throw Exception('Erro ao inserir produto: $e');
    }
  }

  Future<void> update(StockProduct product) async {
    await _initialize();
    
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      throw Exception('Produto não encontrado: ${product.id}');
    }
    
    // Verificar se o novo nome não conflita com outro produto
    final nameConflictIndex = _products.indexWhere((p) => 
      p.id != product.id && p.name.toLowerCase() == product.name.toLowerCase()
    );
    if (nameConflictIndex != -1) {
      throw Exception('Já existe outro produto com o nome "${product.name}"');
    }
    
    _products[index] = product;
    await _saveToStorage();
    print('✅ Produto atualizado: ${product.name}');
  }

  Future<void> delete(String id) async {
    await _initialize();
    
    final initialLength = _products.length;
    _products.removeWhere((product) => product.id == id);
    
    if (_products.length == initialLength) {
      throw Exception('Produto não encontrado para exclusão: $id');
    }
    
    await _saveToStorage();
    print('✅ Produto excluído: $id');
  }

  /// Busca produtos por categoria
  Future<List<StockProduct>> getByCategory(String category) async {
    await _initialize();
    return _products.where((product) => product.category == category).toList();
  }

  /// Busca produtos por nome (busca parcial)
  Future<List<StockProduct>> searchByName(String query) async {
    await _initialize();
    final lowerQuery = query.toLowerCase();
    return _products.where((product) => 
      product.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Obtém produtos com estoque baixo
  Future<List<StockProduct>> getLowStockProducts() async {
    await _initialize();
    return _products.where((product) => product.isLowStock).toList();
  }

  /// Obtém produtos próximos do vencimento
  Future<List<StockProduct>> getExpiringProducts() async {
    await _initialize();
    return _products.where((product) => product.isNearExpiration).toList();
  }

  /// Obtém produtos vencidos
  Future<List<StockProduct>> getExpiredProducts() async {
    await _initialize();
    return _products.where((product) => product.isExpired).toList();
  }

  /// Limpa todos os dados (para testes)
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _products.clear();
      _isInitialized = false;
      print('✅ Todos os produtos foram removidos');
    } catch (e) {
      print('❌ Erro ao limpar produtos: $e');
    }
  }

  /// Testa se o SharedPreferences está funcionando
  Future<bool> testarStorage() async {
    try {
      print('🧪 TESTE: Verificando SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      
      // Teste de escrita
      const testKey = 'test_storage_key';
      const testValue = 'test_value';
      await prefs.setString(testKey, testValue);
      
      // Teste de leitura
      final readValue = prefs.getString(testKey);
      if (readValue != testValue) {
        throw Exception('Valor lido não corresponde ao valor escrito');
      }
      
      // Limpar teste
      await prefs.remove(testKey);
      
      print('✅ TESTE: SharedPreferences funcionando corretamente');
      return true;
    } catch (e) {
      print('❌ TESTE: Erro no SharedPreferences: $e');
      return false;
    }
  }

  /// Limpa produtos de exemplo automaticamente durante a inicialização
  Future<void> _limparProdutosExemploAutomaticamente() async {
    try {
      if (_products.isEmpty) return;
      
      final produtosExemplo = [
        'Ticlopir',
        'Fusão',
        'Acetameprid',
        'Roundup Original',
        'Fertilizante NPK 20-20-20',
        'Inseticida Decis',
        'Glifosato 480',
        'NPK 20-20-20',
        'Semente de Soja RR',
      ];
      
      final produtosAntes = _products.length;
      
      // Filtrar produtos que não são de exemplo
      _products.removeWhere((produto) {
        return produtosExemplo.any((exemplo) => 
          produto.name.toLowerCase().contains(exemplo.toLowerCase())
        );
      });
      
      final produtosRemovidos = produtosAntes - _products.length;
      
      if (produtosRemovidos > 0) {
        print('🧹 Removidos automaticamente $produtosRemovidos produtos de exemplo');
        // Salvar a lista limpa
        await _saveToStorage();
      }
    } catch (e) {
      print('⚠️ Erro ao limpar produtos de exemplo automaticamente: $e');
      // Não falhar a inicialização por causa disso
    }
  }

  /// Limpa dados de exemplo do estoque
  Future<void> limparDadosExemplo() async {
    try {
      print('🧹 Limpando dados de exemplo do estoque...');
      
      // Lista de produtos de exemplo que devem ser removidos
      final produtosExemplo = [
        'Ticlopir',
        'Fusão',
        'Acetameprid',
        'Roundup Original',
        'Fertilizante NPK 20-20-20',
        'Inseticida Decis',
        'Glifosato 480',
        'NPK 20-20-20',
        'Semente de Soja RR',
      ];
      
      // Carregar produtos atuais
      await _initialize();
      
      // Filtrar produtos que não são de exemplo
      final produtosValidos = _products.where((produto) {
        return !produtosExemplo.any((exemplo) => 
          produto.name.toLowerCase().contains(exemplo.toLowerCase())
        );
      }).toList();
      
      // Salvar apenas produtos válidos
      _products = produtosValidos;
      await _saveToStorage();
      
      print('✅ ${produtosExemplo.length} produtos de exemplo removidos');
      print('✅ ${produtosValidos.length} produtos válidos mantidos');
    } catch (e) {
      print('❌ Erro ao limpar dados de exemplo: $e');
    }
  }
}

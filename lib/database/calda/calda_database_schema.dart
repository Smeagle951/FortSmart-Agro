/// Schema do banco de dados para o módulo Calda
class CaldaDatabaseSchema {
  static const String productsTable = '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      manufacturer TEXT NOT NULL,
      formulation TEXT NOT NULL,
      dose REAL NOT NULL,
      dose_unit TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String recipesTable = '''
    CREATE TABLE recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      volume_liters REAL NOT NULL,
      flow_rate REAL NOT NULL,
      is_flow_per_hectare INTEGER NOT NULL,
      area REAL NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String recipeProductsTable = '''
    CREATE TABLE recipe_products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
    )
  ''';

  static const String preCaldaTable = '''
    CREATE TABLE pre_calda (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      volume_liters REAL NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
    )
  ''';

  static const String jarTestTable = '''
    CREATE TABLE jar_test (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      test_date TEXT NOT NULL,
      operator_name TEXT NOT NULL,
      temperature REAL,
      humidity REAL,
      result TEXT NOT NULL,
      observations TEXT,
      photo_paths TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
    )
  ''';

  static List<String> get allTables => [
    productsTable,
    recipesTable,
    recipeProductsTable,
    preCaldaTable,
    jarTestTable,
  ];
}



/// Modelo simples de usuário
class User {
  final String id;
  final String nome;
  final String email;

  User({
    required this.id,
    required this.nome,
    required this.email,
  });
}

/// Serviço de gerenciamento de usuários
class UserService {
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  UserService._internal();
  
  // Usuário atual simulado
  User? _currentUser;
  
  /// Retorna o usuário atual
  User? get currentUser => _currentUser;
  
  /// Inicializa o serviço com um usuário padrão
  Future<void> init() async {
    _currentUser = User(
      id: 'user_default',
      nome: 'Usuário Padrão',
      email: 'usuario@fortsmart.com',
    );
  }
  
  /// Obtém o usuário atual
  Future<User?> getCurrentUser() async {
    if (_currentUser == null) {
      await init();
    }
    return _currentUser;
  }
}

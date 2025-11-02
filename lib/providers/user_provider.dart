import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/database/models/user.dart';
import 'package:fortsmart_agro/services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  UserProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      debugPrint('Erro ao carregar usuário: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String id, String name, {String? email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = User(
        id: id,
        name: name,
        email: email,
      );

      final success = await _authService.saveUser(user);
      if (success) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao fazer login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.logout();
      if (success) {
        _currentUser = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(String name, {String? email}) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = User(
        id: _currentUser!.id,
        name: name,
        email: email,
      );

      final success = await _authService.saveUser(updatedUser);
      if (success) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


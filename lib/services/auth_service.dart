import 'package:flutter/material.dart';
import 'package:fortsmart_agro/database/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userTokenKey = 'user_token';

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final userName = prefs.getString(_userNameKey);
    final userEmail = prefs.getString(_userEmailKey);
    
    if (userId == null || userName == null) {
      return null;
    }
    
    return User(
      id: userId,
      name: userName,
      email: userEmail,
    );
  }

  Future<bool> saveUser(User user, {String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, user.id);
      await prefs.setString(_userNameKey, user.name);
      if (user.email != null) {
        await prefs.setString(_userEmailKey, user.email!);
      }
      if (token != null) {
        await prefs.setString(_userTokenKey, token);
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar usuário: $e');
      return false;
    }
  }
  
  /// Obtém o token de autenticação do usuário atual
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTokenKey);
    } catch (e) {
      debugPrint('Erro ao obter token: $e');
      return null;
    }
  }
  
  /// Método alternativo para obter o token do usuário (para compatibilidade)
  Future<String?> getUserToken() async {
    return getToken();
  }

  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userTokenKey);
      return true;
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      return false;
    }
  }
}


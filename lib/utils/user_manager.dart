import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Classe para gerenciar informações do usuário
class UserManager {
  static final UserManager _instance = UserManager._internal();
  SharedPreferences? _prefs;
  String? _userId;
  String? _userName;
  String? _userEmail;
  bool _isPremium = false;
  bool _isLoggedIn = false;

  factory UserManager() {
    return _instance;
  }

  UserManager._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadUserData();
  }

  void _loadUserData() {
    if (_prefs != null) {
      _userId = _prefs!.getString('userId');
      _userName = _prefs!.getString('userName');
      _userEmail = _prefs!.getString('userEmail');
      _isPremium = _prefs!.getBool('isPremium') ?? false;
      _isLoggedIn = _prefs!.getBool('isLoggedIn') ?? false;
    }
  }

  Future<void> setUserData({
    String? userId,
    String? userName,
    String? userEmail,
    bool? isPremium,
    bool? isLoggedIn,
  }) async {
    if (_prefs != null) {
      if (userId != null) {
        _userId = userId;
        await _prefs!.setString('userId', userId);
      }
      if (userName != null) {
        _userName = userName;
        await _prefs!.setString('userName', userName);
      }
      if (userEmail != null) {
        _userEmail = userEmail;
        await _prefs!.setString('userEmail', userEmail);
      }
      if (isPremium != null) {
        _isPremium = isPremium;
        await _prefs!.setBool('isPremium', isPremium);
      }
      if (isLoggedIn != null) {
        _isLoggedIn = isLoggedIn;
        await _prefs!.setBool('isLoggedIn', isLoggedIn);
      }
    }
  }

  Future<void> clearUserData() async {
    if (_prefs != null) {
      await _prefs!.remove('userId');
      await _prefs!.remove('userName');
      await _prefs!.remove('userEmail');
      await _prefs!.remove('isPremium');
      await _prefs!.remove('isLoggedIn');
      _userId = null;
      _userName = null;
      _userEmail = null;
      _isPremium = false;
      _isLoggedIn = false;
    }
  }

  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isPremium => _isPremium;
  bool get isLoggedIn => _isLoggedIn;
  
  /// Retorna o ID do usuário (método para compatibilidade com código existente)
  String? getUserId() => _userId;
}

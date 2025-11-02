import 'dart:io';
import 'package:flutter/material.dart';

/// Wrapper para permissões que não depende de plugins externos
class PermissionHandlerWrapper {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Obtém a chave do Navigator para ser usada no MaterialApp
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Solicita permissão de armazenamento
  static Future<bool> requestStoragePermission() async {
    // Em plataformas móveis, exibimos um diálogo explicando a necessidade da permissão
    if (Platform.isAndroid || Platform.isIOS) {
      return await _showPermissionDialog(
        title: 'Permissão de armazenamento',
        message: 'O aplicativo precisa de acesso ao armazenamento para salvar e carregar arquivos.',
      );
    }
    // Em outras plataformas, assumimos que a permissão está concedida
    return true;
  }

  /// Solicita permissão de câmera
  static Future<bool> requestCameraPermission() async {
    // Em plataformas móveis, exibimos um diálogo explicando a necessidade da permissão
    if (Platform.isAndroid || Platform.isIOS) {
      return await _showPermissionDialog(
        title: 'Permissão de câmera',
        message: 'O aplicativo precisa de acesso à câmera para tirar fotos.',
      );
    }
    // Em outras plataformas, assumimos que a permissão está concedida
    return true;
  }

  /// Solicita permissão de localização
  static Future<bool> requestLocationPermission() async {
    // Em plataformas móveis, exibimos um diálogo explicando a necessidade da permissão
    if (Platform.isAndroid || Platform.isIOS) {
      return await _showPermissionDialog(
        title: 'Permissão de localização',
        message: 'O aplicativo precisa de acesso à localização para mostrar sua posição no mapa.',
      );
    }
    // Em outras plataformas, assumimos que a permissão está concedida
    return true;
  }

  /// Verifica se a permissão de armazenamento está concedida
  static Future<bool> hasStoragePermission() async {
    // Como não podemos verificar diretamente, assumimos que a permissão está concedida
    // se o usuário já concedeu permissão anteriormente
    return true;
  }

  /// Verifica se a permissão de câmera está concedida
  static Future<bool> hasCameraPermission() async {
    // Como não podemos verificar diretamente, assumimos que a permissão está concedida
    // se o usuário já concedeu permissão anteriormente
    return true;
  }

  /// Verifica se a permissão de localização está concedida
  static Future<bool> hasLocationPermission() async {
    // Como não podemos verificar diretamente, assumimos que a permissão está concedida
    // se o usuário já concedeu permissão anteriormente
    return true;
  }

  /// Exibe um diálogo explicando a necessidade da permissão
  static Future<bool> _showPermissionDialog({
    required String title,
    required String message,
  }) async {
    if (_navigatorKey.currentContext == null) {
      // Se não temos acesso ao contexto, assumimos que a permissão está concedida
      return true;
    }

    final result = await showDialog<bool>(
      context: _navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Negar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
